/**
 * StitchCraft Garment Template & Versioned Measurement Schema Service
 * ---------------------------------------------------------------------------
 * Provides standard, versioned measurement schemas for traditional and modern
 * garments (Blouse, Kurti, Salwar, Shirt, Pant, Suit, Lehenga) with support for
 * shop-level customizations and validation.
 */

export const GARMENT_TEMPLATES = {
  shirt: {
    key: 'shirt',
    name: 'Men\'s Shirt',
    version: 1,
    gender: 'men',
    category: 'upper',
    fields: [
      { key: 'length', label: 'Length', required: true, min: 20, max: 45 },
      { key: 'chest', label: 'Chest', required: true, min: 28, max: 65 },
      { key: 'waist', label: 'Waist', required: false, min: 24, max: 65 },
      { key: 'shoulder', label: 'Shoulder', required: true, min: 12, max: 28 },
      { key: 'sleeve', label: 'Sleeve Length', required: true, min: 6, max: 35 },
      { key: 'neck', label: 'Neck / Collar', required: false, min: 10, max: 24 },
      { key: 'bicep', label: 'Bicep / Arm', required: false, min: 8, max: 30 },
      { key: 'cuff', label: 'Cuff Round', required: false, min: 6, max: 18 },
    ],
  },
  pant: {
    key: 'pant',
    name: 'Trousers / Pant',
    version: 1,
    gender: 'men',
    category: 'lower',
    fields: [
      { key: 'length', label: 'Length', required: true, min: 25, max: 50 },
      { key: 'waist', label: 'Waist', required: true, min: 24, max: 65 },
      { key: 'hips', label: 'Hips / Seat', required: true, min: 28, max: 70 },
      { key: 'inseam', label: 'Inseam', required: false, min: 20, max: 40 },
      { key: 'thigh', label: 'Thigh Round', required: false, min: 16, max: 40 },
      { key: 'rise', label: 'Rise', required: false, min: 8, max: 20 },
      { key: 'bottom', label: 'Bottom / Ankle Round', required: true, min: 10, max: 26 },
      { key: 'knee', label: 'Knee Round', required: false, min: 12, max: 30 },
    ],
  },
  blouse: {
    key: 'blouse',
    name: 'Women\'s Blouse (Saree)',
    version: 1,
    gender: 'women',
    category: 'upper',
    fields: [
      { key: 'length', label: 'Length', required: true, min: 10, max: 22 },
      { key: 'chest', label: 'Bust / Chest', required: true, min: 26, max: 60 },
      { key: 'waist', label: 'Under-Bust Waist', required: true, min: 22, max: 55 },
      { key: 'shoulder', label: 'Shoulder', required: true, min: 9, max: 20 },
      { key: 'sleeveLength', label: 'Sleeve Length', required: false, min: 3, max: 30 },
      { key: 'sleeveRound', label: 'Sleeve Round', required: false, min: 8, max: 26 },
      { key: 'frontNeck', label: 'Front Neck Deep', required: false, min: 4, max: 12 },
      { key: 'backNeck', label: 'Back Neck Deep', required: false, min: 4, max: 14 },
      { key: 'apex', label: 'Apex / Bust Point', required: false, min: 7, max: 16 },
      { key: 'crossBack', label: 'Cross Back', required: false, min: 10, max: 22 },
    ],
  },
  kurti: {
    key: 'kurti',
    name: 'Women\'s Kurti / Kameez',
    version: 1,
    gender: 'women',
    category: 'upper',
    fields: [
      { key: 'length', label: 'Length', required: true, min: 28, max: 58 },
      { key: 'chest', label: 'Bust / Chest', required: true, min: 26, max: 60 },
      { key: 'waist', label: 'Waist', required: true, min: 22, max: 58 },
      { key: 'hips', label: 'Hips', required: true, min: 28, max: 68 },
      { key: 'shoulder', label: 'Shoulder', required: true, min: 10, max: 22 },
      { key: 'sleeveLength', label: 'Sleeve Length', required: false, min: 4, max: 32 },
      { key: 'armhole', label: 'Armhole Round', required: false, min: 12, max: 28 },
      { key: 'frontNeck', label: 'Front Neck Deep', required: false, min: 4, max: 10 },
      { key: 'backNeck', label: 'Back Neck Deep', required: false, min: 3, max: 10 },
      { key: 'slit', label: 'Side Slit Opening', required: false, min: 12, max: 28 },
    ],
  },
  salwar: {
    key: 'salwar',
    name: 'Salwar / Chudidar / Palazzo',
    version: 1,
    gender: 'women',
    category: 'lower',
    fields: [
      { key: 'length', label: 'Length', required: true, min: 30, max: 48 },
      { key: 'waist', label: 'Waist / Belt', required: true, min: 24, max: 60 },
      { key: 'hips', label: 'Hips / Seat', required: false, min: 28, max: 70 },
      { key: 'thigh', label: 'Thigh Round', required: false, min: 18, max: 40 },
      { key: 'knee', label: 'Knee Round', required: false, min: 12, max: 28 },
      { key: 'bottom', label: 'Mori / Bottom Round', required: true, min: 9, max: 30 },
      { key: 'seat', label: 'Seat / Asan', required: false, min: 12, max: 22 },
    ],
  },
  suit: {
    key: 'suit',
    name: 'Suit / Safari / Blazer',
    version: 1,
    gender: 'men',
    category: 'upper',
    fields: [
      { key: 'length', label: 'Coat Length', required: true, min: 24, max: 42 },
      { key: 'chest', label: 'Chest', required: true, min: 30, max: 65 },
      { key: 'waist', label: 'Waist', required: true, min: 26, max: 62 },
      { key: 'shoulder', label: 'Shoulder', required: true, min: 13, max: 26 },
      { key: 'sleeve', label: 'Sleeve Length', required: true, min: 18, max: 32 },
      { key: 'collar', label: 'Collar / Neck', required: false, min: 12, max: 24 },
      { key: 'crossBack', label: 'Cross Back', required: false, min: 12, max: 24 },
    ],
  },
  lehenga: {
    key: 'lehenga',
    name: 'Lehenga / Skirt',
    version: 1,
    gender: 'women',
    category: 'lower',
    fields: [
      { key: 'length', label: 'Length', required: true, min: 34, max: 48 },
      { key: 'waist', label: 'Waist', required: true, min: 24, max: 60 },
      { key: 'hips', label: 'Hips', required: false, min: 30, max: 70 },
      { key: 'flare', label: 'Ghera / Flare', required: false, min: 60, max: 300 },
    ],
  },
};

/**
 * Returns canonical template for a garment name or key.
 */
export const resolveGarmentTemplate = (garmentName = '') => {
  const norm = garmentName.toLowerCase().replace(/[\s\-_]/g, '');
  if (norm.includes('shirt')) return GARMENT_TEMPLATES.shirt;
  if (norm.includes('pant') || norm.includes('trouser')) return GARMENT_TEMPLATES.pant;
  if (norm.includes('blouse')) return GARMENT_TEMPLATES.blouse;
  if (norm.includes('kurti') || norm.includes('kameez')) return GARMENT_TEMPLATES.kurti;
  if (norm.includes('salwar') || norm.includes('chudidar') || norm.includes('palazzo')) return GARMENT_TEMPLATES.salwar;
  if (norm.includes('suit') || norm.includes('blazer') || norm.includes('safari')) return GARMENT_TEMPLATES.suit;
  if (norm.includes('lehenga') || norm.includes('skirt')) return GARMENT_TEMPLATES.lehenga;
  return null;
};

/**
 * Validates a map of measurements against a template's schema.
 */
export const validateMeasurementsForTemplate = (templateKey, measurements = {}) => {
  const template = GARMENT_TEMPLATES[templateKey] || resolveGarmentTemplate(templateKey);
  if (!template) {
    return { valid: true, sanitized: { ...measurements } };
  }

  const sanitized = {};
  const errors = [];

  for (const field of template.fields) {
    const rawVal = measurements[field.key] ?? measurements[field.label] ?? measurements[field.key.toLowerCase()];
    if (rawVal !== undefined && rawVal !== null && rawVal !== '') {
      const numVal = Number(rawVal);
      if (isNaN(numVal) || numVal <= 0) {
        errors.push(`Measurement '${field.label}' must be a positive number.`);
      } else if (field.min && numVal < field.min) {
        errors.push(`Measurement '${field.label}' (${numVal}) is below minimum plausible limit (${field.min}").`);
      } else if (field.max && numVal > field.max) {
        errors.push(`Measurement '${field.label}' (${numVal}) exceeds maximum plausible limit (${field.max}").`);
      } else {
        sanitized[field.key] = numVal;
      }
    } else if (field.required && !measurements.isDraft) {
      // Missing required field
      errors.push(`Field '${field.label}' is required for template '${template.name}'.`);
    }
  }

  // Preserve any extra custom notes or fields
  for (const [k, v] of Object.entries(measurements)) {
    if (!sanitized[k] && v !== undefined && v !== null && v !== '') {
      sanitized[k] = v;
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    sanitized,
    templateKey: template.key,
    schemaVersion: template.version,
  };
};

/**
 * Creates an immutable, versioned snapshot of garment measurements for an order.
 */
export const createMeasurementsSnapshot = (garmentName, measurements = {}) => {
  const template = resolveGarmentTemplate(garmentName);
  const templateKey = template?.key || 'custom';
  const schemaVersion = template?.version || 1;

  return {
    templateKey,
    schemaVersion,
    garmentName: garmentName || 'Custom Garment',
    capturedAt: new Date().toISOString(),
    measurements: { ...measurements },
  };
};
