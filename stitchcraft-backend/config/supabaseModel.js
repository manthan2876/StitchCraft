import crypto from 'node:crypto';
import { supabase } from './supabase.js';

const clone = (value, seen = new WeakSet()) => {
  if (value === null || typeof value !== 'object') return value;
  if (seen.has(value)) return null;
  seen.add(value);

  if (Array.isArray(value)) {
    return value.map((item) => clone(item, seen));
  }

  return Object.fromEntries(
    Object.entries(value)
      .filter(([, item]) => typeof item !== 'function')
      .map(([key, item]) => [key, clone(item, seen)]),
  );
};

const getValue = (document, path) => path.split('.').reduce(
  (value, key) => value?.[key],
  document,
);

const matches = (document, query = {}) => Object.entries(query).every(([key, expected]) => {
  if (key === '$or') return expected.some((condition) => matches(document, condition));
  const actual = key === '_id' ? (document._id ?? document.id) : getValue(document, key);

  if (expected instanceof RegExp) return expected.test(String(actual ?? ''));
  if (expected && typeof expected === 'object' && !Array.isArray(expected)) {
    return Object.entries(expected).every(([operator, value]) => {
      if (operator === '$in') return value.map(String).includes(String(actual));
      if (operator === '$ne') return String(actual) !== String(value);
      if (operator === '$gte') return actual >= value;
      if (operator === '$lte') return actual <= value;
      if (operator === '$gt') return actual > value;
      if (operator === '$lt') return actual < value;
      if (operator === '$regex') return new RegExp(value).test(String(actual ?? ''));
      if (operator === '$options') return true;
      return false;
    });
  }
  return String(actual) === String(expected);
});

const applyUpdate = (document, update) => {
  const result = { ...document };
  if (update.$set) Object.assign(result, update.$set);
  if (update.$inc) {
    for (const [key, value] of Object.entries(update.$inc)) {
      result[key] = (Number(result[key]) || 0) + value;
    }
  }
  for (const [key, value] of Object.entries(update)) {
    if (!key.startsWith('$')) result[key] = value;
  }
  return result;
};

const referenceCollections = {
  shopId: 'shops',
  customer: 'customers',
  customerId: 'customers',
  assignedKarigar: 'karigars',
  assignedMachine: 'machines',
  asterInventoryItem: 'inventory',
  orderId: 'orders',
};

const populateReference = async (document, path) => {
  const collection = referenceCollections[path];
  const reference = document?.[path];
  if (!collection || !reference || typeof reference === 'object') return;

  const { data, error } = await supabase
    .from('app_records')
    .select('source_id,document,created_at,updated_at')
    .eq('collection', collection)
    .eq('source_id', String(reference))
    .maybeSingle();
  if (error) throw new Error(`Supabase ${collection} relation read failed: ${error.message}`);
  if (data) {
    document[path] = {
      ...data.document,
      _id: data.source_id,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
    };
  }
};

class SupabaseQuery {
  constructor(executor, single = false) {
    this.executor = executor;
    this.single = single;
    this.projection = null;
    this.sortFields = null;
    this.limitCount = null;
    this.populateFields = [];
  }

  select(fields) {
    this.projection = fields;
    return this;
  }

  populate() {
    this.populateFields.push(...arguments);
    return this;
  }

  sort(fields) {
    this.sortFields = fields;
    return this;
  }

  limit(count) {
    this.limitCount = Math.max(0, Number(count) || 0);
    return this;
  }

  lean() {
    return this;
  }

  async then(resolve, reject) {
    try {
      let value = await this.executor();
      const values = Array.isArray(value) ? value : [value];
      if (this.sortFields && Array.isArray(value)) {
        const entries = Object.entries(this.sortFields);
        value.sort((left, right) => {
          for (const [field, direction] of entries) {
            const comparison = String(left?.[field] ?? '').localeCompare(
              String(right?.[field] ?? ''),
              undefined,
              { numeric: true },
            );
            if (comparison !== 0) return comparison * Number(direction);
          }
          return 0;
        });
      }
      if (this.limitCount !== null && Array.isArray(value)) {
        value = value.slice(0, this.limitCount);
      }
      if (this.populateFields.length) {
        for (const field of this.populateFields) {
          const path = typeof field === 'string' ? field : field.path;
          for (const item of values) {
            if (item) await populateReference(item, path);
          }
        }
      }
      if (this.projection && value) {
        const omit = this.projection.startsWith('-')
          ? this.projection.slice(1).split(' ')
          : [];
        if (this.single) {
          value = { ...value };
          omit.forEach((field) => delete value[field]);
        }
      }
      resolve(value);
    } catch (error) {
      reject(error);
    }
  }
}

export const createDocumentModel = (collection) => {
  const load = async () => {
    const { data, error } = await supabase
      .from('app_records')
      .select('source_id,document,created_at,updated_at')
      .eq('collection', collection);
    if (error) throw new Error(`Supabase ${collection} read failed: ${error.message}`);
    return (data ?? []).map(hydrate);
  };

  const persist = async (document) => {
    const value = clone(document);
    const sourceId = String(value._id ?? crypto.randomUUID());
    if (collection === 'customers' && !value.customerId) {
      value.customerId = `CUST-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
    }
    if (collection === 'orders' && !value.orderId) {
      value.orderId = `ORD-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
    }
    delete value._id;
    delete value.createdAt;
    delete value.updatedAt;
    const { data, error } = await supabase
      .from('app_records')
      .upsert({
        collection,
        source_id: sourceId,
        document: { ...value, _id: sourceId },
      }, { onConflict: 'collection,source_id' })
      .select('source_id,document,created_at,updated_at')
      .single();
    if (error) throw new Error(`Supabase ${collection} write failed: ${error.message}`);
    return hydrate(data);
  };

  const hydrate = (row) => ({
    ...row.document,
    _id: row.source_id,
    ...(row.document.customerId ? { id: row.document.customerId } : {}),
    ...(row.document.orderId ? { id: row.document.orderId } : {}),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    toJSON() {
      return clone(this);
    },
    toObject() {
      return clone(this);
    },
    async populate(...fields) {
      for (const field of fields) {
        const path = typeof field === 'string' ? field : field.path;
        await populateReference(this, path);
      }
      return this;
    },
    save: async function save() { return persist(this); },
  });

  class Document {
    constructor(value = {}) {
      Object.assign(this, value);
      this._id ??= crypto.randomUUID();
    }

    async save() {
      return persist(this);
    }

    toJSON() {
      return clone(this);
    }

    toObject() {
      return clone(this);
    }

    async populate(...fields) {
      for (const field of fields) {
        const path = typeof field === 'string' ? field : field.path;
        await populateReference(this, path);
      }
      return this;
    }
  }

  Document.find = (query = {}) => new SupabaseQuery(async () => (
    (await load()).filter((document) => matches(document, query))
  ));
  Document.findOne = (query = {}) => new SupabaseQuery(async () => (
    (await load()).find((document) => matches(document, query)) ?? null
  ), true);
  Document.countDocuments = async (query = {}) => (
    (await load()).filter((document) => matches(document, query)).length
  );
  Document.findById = (id) => Document.findOne({ _id: id });
  Document.create = async (value) => persist(new Document(value));
  Document.findOneAndUpdate = (query, update, options = {}) => new SupabaseQuery(async () => {
    const existing = (await load()).find((document) => matches(document, query));
    if (!existing && !options.upsert) return null;
    return persist(new Document(applyUpdate(existing ?? {}, update)));
  }, true);
  Document.updateOne = async (query, update, options = {}) => {
    const existing = (await load()).find((document) => matches(document, query));
    if (!existing) {
      if (!options.upsert) return { matchedCount: 0, modifiedCount: 0, upsertedCount: 0 };
      const created = await persist(new Document(applyUpdate({}, update)));
      return { matchedCount: 0, modifiedCount: created ? 1 : 0, upsertedCount: created ? 1 : 0 };
    }
    const updated = await persist(new Document(applyUpdate(existing, update)));
    return { matchedCount: 1, modifiedCount: updated ? 1 : 0, upsertedCount: 0 };
  };
  Document.updateMany = async (query = {}, update = {}) => {
    const documents = (await load()).filter((document) => matches(document, query));
    let modifiedCount = 0;
    for (const document of documents) {
      if (await persist(new Document(applyUpdate(document, update)))) {
        modifiedCount++;
      }
    }
    return {
      matchedCount: documents.length,
      modifiedCount,
      upsertedCount: 0,
    };
  };
  Document.findByIdAndUpdate = (id, update, options) => (
    Document.findOneAndUpdate({ _id: id }, update, options)
  );
  Document.replaceOne = (query, replacement) => new SupabaseQuery(async () => {
    const existing = (await load()).find((document) => matches(document, query));
    if (!existing) return { matchedCount: 0, modifiedCount: 0 };
    const saved = await persist(new Document({ ...replacement, _id: existing._id }));
    return { matchedCount: 1, modifiedCount: saved ? 1 : 0 };
  }, true);
  Document.findByIdAndDelete = (id) => new SupabaseQuery(async () => {
    const existing = (await load()).find((document) => String(document._id) === String(id));
    if (!existing) return null;
    const { error } = await supabase.from('app_records')
      .delete().eq('collection', collection).eq('source_id', String(id));
    if (error) throw error;
    return existing;
  }, true);
  Document.deleteOne = async (query = {}) => {
    const existing = (await load()).find((document) => matches(document, query));
    if (!existing) return { deletedCount: 0 };
    const { error } = await supabase.from('app_records')
      .delete().eq('collection', collection).eq('source_id', String(existing._id));
    if (error) throw new Error(`Supabase ${collection} delete failed: ${error.message}`);
    return { deletedCount: 1 };
  };
  Document.deleteMany = async (query = {}) => {
    const documents = (await load()).filter((document) => matches(document, query));
    for (const document of documents) await Document.findByIdAndDelete(document._id);
    return { deletedCount: documents.length };
  };

  return Document;
};
