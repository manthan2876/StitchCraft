/**
 * Table & Document Validation Rules for StitchCraft
 * ---------------------------------------------------------------------------
 * Validates entity records before writing to database (app_records or domain tables).
 */

const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$/;
const PHONE_REGEX = /^[0-9+]{10,15}$/;

export class ValidationError extends Error {
  constructor(message, fieldErrors = {}) {
    super(message);
    this.name = 'ValidationError';
    this.statusCode = 400;
    this.fieldErrors = fieldErrors;
  }
}

/**
 * Validates document based on collection type
 * @param {string} collection - collection name
 * @param {Object} doc - document object
 * @throws {ValidationError} if validation fails
 */
export const validateDocument = (collection, doc) => {
  if (!doc || typeof doc !== 'object') {
    throw new ValidationError(`Invalid document payload for table '${collection}'`);
  }

  const errors = {};

  switch (collection) {
    case 'users': {
      if (!doc.name || typeof doc.name !== 'string' || doc.name.trim().length < 2) {
        errors.name = 'User name must be at least 2 characters';
      }
      if (doc.email) {
        const clean = doc.email.trim();
        if (clean.length > 254 || !EMAIL_REGEX.test(clean)) {
          errors.email = 'Valid email address is required';
        }
      }
      if (doc.role && !['owner', 'manager', 'karigar', 'staff'].includes(doc.role)) {
        errors.role = 'Role must be owner, manager, karigar, or staff';
      }
      break;
    }

    case 'shops': {
      if (!doc.shopName || typeof doc.shopName !== 'string' || doc.shopName.trim().length < 2) {
        errors.shopName = 'Shop name must be at least 2 characters';
      }
      if (doc.phone) {
        const cleanPhone = String(doc.phone).replace(/[\s-]/g, '');
        if (!PHONE_REGEX.test(cleanPhone)) {
          errors.phone = 'Shop contact phone must contain 10-15 digits';
        }
      }
      break;
    }

    case 'customers': {
      if (!doc.shopId) {
        errors.shopId = 'Customer record must be linked to a shop';
      }
      if (!doc.name || typeof doc.name !== 'string' || doc.name.trim().length < 2) {
        errors.name = 'Customer name must be at least 2 characters';
      }
      if (doc.phone) {
        const cleanPhone = String(doc.phone).replace(/[\s-]/g, '');
        if (!PHONE_REGEX.test(cleanPhone)) {
          errors.phone = 'Customer phone must contain 10-15 digits';
        }
      } else {
        errors.phone = 'Customer phone number is required';
      }
      if (doc.email && doc.email.trim()) {
        const clean = doc.email.trim();
        if (clean.length > 254 || !EMAIL_REGEX.test(clean)) {
          errors.email = 'Invalid customer email address';
        }
      }
      break;
    }

    case 'orders': {
      if (!doc.shopId) {
        errors.shopId = 'Order record must be linked to a shop';
      }
      if (!doc.customerName || typeof doc.customerName !== 'string' || doc.customerName.trim().length < 2) {
        errors.customerName = 'Customer name is required';
      }
      if (doc.price !== undefined && (typeof doc.price !== 'number' || doc.price < 0)) {
        errors.price = 'Order price cannot be negative';
      }
      if (doc.status) {
        const allowedStatuses = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered', 'Cancelled'];
        if (!allowedStatuses.includes(doc.status)) {
          errors.status = `Status must be one of: ${allowedStatuses.join(', ')}`;
        }
      }
      if (doc.deliveryDate) {
        const d = new Date(doc.deliveryDate);
        if (isNaN(d.getTime())) {
          errors.deliveryDate = 'Invalid delivery date';
        }
      }
      if (doc.needsAster) {
        if (doc.asterQuantity !== undefined && (typeof doc.asterQuantity !== 'number' || doc.asterQuantity < 0)) {
          errors.asterQuantity = 'Astar quantity cannot be negative';
        }
        if (doc.asterSellingPrice !== undefined && (typeof doc.asterSellingPrice !== 'number' || doc.asterSellingPrice < 0)) {
          errors.asterSellingPrice = 'Astar selling price cannot be negative';
        }
      }
      if (Array.isArray(doc.items)) {
        doc.items.forEach((item, idx) => {
          if (item.price !== undefined && (typeof item.price !== 'number' || item.price < 0)) {
            errors[`items[${idx}].price`] = 'Item price cannot be negative';
          }
          if (item.quantity !== undefined && (typeof item.quantity !== 'number' || item.quantity <= 0)) {
            errors[`items[${idx}].quantity`] = 'Item quantity must be greater than zero';
          }
        });
      }
      break;
    }

    case 'payments': {
      if (!doc.shopId) errors.shopId = 'Payment must be linked to a shop';
      if (!doc.orderId) errors.orderId = 'Payment must be linked to an order';
      if (doc.totalAmount !== undefined && (typeof doc.totalAmount !== 'number' || doc.totalAmount < 0)) {
        errors.totalAmount = 'Total payment amount cannot be negative';
      }
      if (doc.paidAmount !== undefined && (typeof doc.paidAmount !== 'number' || doc.paidAmount < 0)) {
        errors.paidAmount = 'Paid amount cannot be negative';
      }
      if (doc.balanceAmount !== undefined && (typeof doc.balanceAmount !== 'number' || doc.balanceAmount < 0)) {
        errors.balanceAmount = 'Balance amount cannot be negative';
      }
      if (doc.status && !['Pending', 'Partial', 'Paid'].includes(doc.status)) {
        errors.status = 'Payment status must be Pending, Partial, or Paid';
      }
      break;
    }

    case 'transactions': {
      if (!doc.shopId) errors.shopId = 'Transaction must be linked to a shop';
      if (!doc.orderId) errors.orderId = 'Transaction must be linked to an order';
      if (doc.amount === undefined || typeof doc.amount !== 'number' || doc.amount <= 0) {
        errors.amount = 'Transaction amount must be a positive number';
      }
      if (doc.type && !['Payment', 'Refund'].includes(doc.type)) {
        errors.type = 'Transaction type must be Payment or Refund';
      }
      if (doc.paymentType && !['Cash', 'UPI', 'Card', 'Credit', 'Bank'].includes(doc.paymentType)) {
        errors.paymentType = 'Invalid payment mode';
      }
      break;
    }

    case 'ledger_entries': {
      if (!doc.shopId) errors.shopId = 'Ledger entry must be linked to a shop';
      if (doc.amount === undefined || typeof doc.amount !== 'number' || doc.amount <= 0) {
        errors.amount = 'Ledger amount must be a positive number';
      }
      if (!doc.category || typeof doc.category !== 'string' || doc.category.trim().length === 0) {
        errors.category = 'Ledger category is required';
      }
      break;
    }

    case 'inventory': {
      if (!doc.shopId) errors.shopId = 'Inventory item must be linked to a shop';
      if (!doc.itemName || typeof doc.itemName !== 'string' || doc.itemName.trim().length < 2) {
        errors.itemName = 'Inventory item name must be at least 2 characters';
      }
      if (doc.quantity !== undefined && (typeof doc.quantity !== 'number' || doc.quantity < 0)) {
        errors.quantity = 'Inventory quantity cannot be negative';
      }
      if (doc.minQuantity !== undefined && (typeof doc.minQuantity !== 'number' || doc.minQuantity < 0)) {
        errors.minQuantity = 'Minimum stock alert quantity cannot be negative';
      }
      if (doc.costPerUnit !== undefined && (typeof doc.costPerUnit !== 'number' || doc.costPerUnit < 0)) {
        errors.costPerUnit = 'Cost price per unit cannot be negative';
      }
      if (doc.unit && !['meters', 'pieces', 'rolls', 'yards', 'packs'].includes(doc.unit)) {
        errors.unit = 'Invalid inventory measurement unit';
      }
      if (doc.itemType && !['Lining', 'Fabric', 'Thread', 'Accessories', 'Other'].includes(doc.itemType)) {
        errors.itemType = 'Invalid inventory category/type';
      }
      break;
    }

    case 'karigars': {
      if (!doc.shopId) errors.shopId = 'Karigar must be linked to a shop';
      if (!doc.name || typeof doc.name !== 'string' || doc.name.trim().length < 2) {
        errors.name = 'Karigar name must be at least 2 characters';
      }
      if (doc.phone) {
        const cleanPhone = String(doc.phone).replace(/[\s-]/g, '');
        if (!PHONE_REGEX.test(cleanPhone)) {
          errors.phone = 'Karigar phone must contain 10-15 digits';
        }
      } else {
        errors.phone = 'Karigar phone number is required';
      }
      if (doc.specialization && !['Stitching', 'Cutting', 'Embroidery', 'Measurements', 'General'].includes(doc.specialization)) {
        errors.specialization = 'Invalid artisan specialization';
      }
      if (doc.status && !['Active', 'Inactive'].includes(doc.status)) {
        errors.status = 'Status must be Active or Inactive';
      }
      break;
    }

    case 'machines': {
      if (!doc.shopId) errors.shopId = 'Machine must be linked to a shop';
      if (!doc.name || typeof doc.name !== 'string' || doc.name.trim().length === 0) {
        errors.name = 'Machine identifier/name is required';
      }
      if (!doc.type || typeof doc.type !== 'string' || doc.type.trim().length === 0) {
        errors.type = 'Machine type is required';
      }
      if (doc.status && !['Working', 'Under Maintenance', 'Broken'].includes(doc.status)) {
        errors.status = 'Status must be Working, Under Maintenance, or Broken';
      }
      break;
    }

    case 'deliveries': {
      if (!doc.shopId) errors.shopId = 'Delivery must be linked to a shop';
      if (!doc.orderId) errors.orderId = 'Delivery must be linked to an order';
      if (doc.status && !['Pending', 'Delivered', 'Cancelled'].includes(doc.status)) {
        errors.status = 'Status must be Pending, Delivered, or Cancelled';
      }
      break;
    }

    case 'measurements': {
      if (!doc.shopId) errors.shopId = 'Measurement must be linked to a shop';
      if (!doc.customerId) errors.customerId = 'Measurement must be linked to a customer';
      // Validate anatomical values if present (must be numbers between 0 and 150)
      const validateDims = (group, groupName) => {
        if (group && typeof group === 'object') {
          for (const [k, v] of Object.entries(group)) {
            if (v !== undefined && v !== null && v !== '') {
              const num = Number(v);
              if (isNaN(num) || num < 0 || num > 150) {
                errors[`${groupName}.${k}`] = `Dimension for ${k} must be between 0 and 150 inches`;
              }
            }
          }
        }
      };
      validateDims(doc.shirt, 'shirt');
      validateDims(doc.pant, 'pant');
      break;
    }

    case 'notifications': {
      if (!doc.shopId) errors.shopId = 'Notification must be linked to a shop';
      if (!doc.message || typeof doc.message !== 'string' || doc.message.trim().length === 0) {
        errors.message = 'Notification message cannot be empty';
      }
      break;
    }

    default:
      break;
  }

  if (Object.keys(errors).length > 0) {
    const errorMsg = `Validation failed for table '${collection}': ` +
      Object.entries(errors).map(([f, m]) => `${f} (${m})`).join(', ');
    throw new ValidationError(errorMsg, errors);
  }

  return true;
};

export default {
  validateDocument,
  ValidationError,
};

