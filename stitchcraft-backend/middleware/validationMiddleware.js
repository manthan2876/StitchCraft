/**
 * Express Request Validation Middleware
 * ---------------------------------------------------------------------------
 * Validates request payload structures before entering controllers.
 * Returns HTTP 400 with detailed field-level error messages.
 */

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_REGEX = /^[0-9+]{10,15}$/;

const formatErrorResponse = (res, message, errors) => {
  return res.status(400).json({
    message,
    errors,
  });
};

/**
 * Validate customer creation and updates
 */
export const validateCustomerRequest = (req, res, next) => {
  const { name, phone, email } = req.body;
  const errors = {};

  if (!name || typeof name !== 'string' || name.trim().length < 2) {
    errors.name = 'Full name is required and must be at least 2 characters';
  }

  if (!phone) {
    errors.phone = 'Phone number is required';
  } else {
    const cleanPhone = String(phone).replace(/[\s-]/g, '');
    if (!PHONE_REGEX.test(cleanPhone)) {
      errors.phone = 'Phone number must contain between 10 and 15 digits';
    }
  }

  if (email && email.trim() && !EMAIL_REGEX.test(email.trim())) {
    errors.email = 'Invalid email address format';
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Customer validation failed', errors);
  }
  next();
};

/**
 * Validate order creation
 */
export const validateOrderCreateRequest = (req, res, next) => {
  const { customerName, apparelType, items, deliveryDate, price, advancePaid, needsAster, asterQuantity, asterSellingPrice } = req.body;
  const errors = {};

  if (!customerName || typeof customerName !== 'string' || customerName.trim().length < 2) {
    errors.customerName = 'Customer name is required';
  }

  if (!apparelType && (!Array.isArray(items) || items.length === 0)) {
    errors.apparelType = 'Please select an apparel category or add garments';
  }

  if (!deliveryDate) {
    errors.deliveryDate = 'Delivery deadline date is required';
  } else {
    const d = new Date(deliveryDate);
    if (isNaN(d.getTime())) {
      errors.deliveryDate = 'Delivery date is invalid';
    }
  }

  if (price !== undefined) {
    const numPrice = Number(price);
    if (isNaN(numPrice) || numPrice < 0) {
      errors.price = 'Order price cannot be negative';
    }
  }

  if (advancePaid !== undefined && advancePaid !== '') {
    const numAdv = Number(advancePaid);
    if (isNaN(numAdv) || numAdv < 0) {
      errors.advancePaid = 'Advance payment cannot be negative';
    }
  }

  if (needsAster) {
    if (asterQuantity !== undefined && asterQuantity !== '') {
      const q = Number(asterQuantity);
      if (isNaN(q) || q < 0) errors.asterQuantity = 'Astar quantity cannot be negative';
    }
    if (asterSellingPrice !== undefined && asterSellingPrice !== '') {
      const p = Number(asterSellingPrice);
      if (isNaN(p) || p < 0) errors.asterSellingPrice = 'Astar selling price cannot be negative';
    }
  }

  if (Array.isArray(items)) {
    items.forEach((item, idx) => {
      if (item.price !== undefined && (isNaN(Number(item.price)) || Number(item.price) < 0)) {
        errors[`items[${idx}].price`] = 'Item price cannot be negative';
      }
      if (item.quantity !== undefined && (isNaN(Number(item.quantity)) || Number(item.quantity) <= 0)) {
        errors[`items[${idx}].quantity`] = 'Item quantity must be at least 1';
      }
    });
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Order validation failed', errors);
  }
  next();
};

/**
 * Validate order update
 */
export const validateOrderUpdateRequest = (req, res, next) => {
  const { status, deliveryDate, price, items, asterQuantity, asterSellingPrice } = req.body;
  const errors = {};

  if (status) {
    const allowed = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered', 'Cancelled'];
    if (!allowed.includes(status)) {
      errors.status = `Status must be one of: ${allowed.join(', ')}`;
    }
  }

  if (deliveryDate) {
    const d = new Date(deliveryDate);
    if (isNaN(d.getTime())) {
      errors.deliveryDate = 'Delivery date is invalid';
    }
  }

  if (price !== undefined) {
    const numPrice = Number(price);
    if (isNaN(numPrice) || numPrice < 0) {
      errors.price = 'Order price cannot be negative';
    }
  }

  if (asterQuantity !== undefined && asterQuantity !== '') {
    const q = Number(asterQuantity);
    if (isNaN(q) || q < 0) errors.asterQuantity = 'Astar quantity cannot be negative';
  }

  if (asterSellingPrice !== undefined && asterSellingPrice !== '') {
    const p = Number(asterSellingPrice);
    if (isNaN(p) || p < 0) errors.asterSellingPrice = 'Astar selling price cannot be negative';
  }

  if (Array.isArray(items)) {
    items.forEach((item, idx) => {
      if (item.price !== undefined && (isNaN(Number(item.price)) || Number(item.price) < 0)) {
        errors[`items[${idx}].price`] = 'Item price cannot be negative';
      }
      if (item.quantity !== undefined && (isNaN(Number(item.quantity)) || Number(item.quantity) <= 0)) {
        errors[`items[${idx}].quantity`] = 'Item quantity must be at least 1';
      }
    });
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Order update validation failed', errors);
  }
  next();
};

/**
 * Validate payment record
 */
export const validatePaymentRequest = (req, res, next) => {
  const { amount, paymentType } = req.body;
  const errors = {};

  const numAmount = Number(amount);
  if (!amount || isNaN(numAmount) || numAmount <= 0) {
    errors.amount = 'Payment amount must be a positive number';
  }

  if (paymentType && !['Cash', 'UPI', 'Card', 'Credit', 'Bank'].includes(paymentType)) {
    errors.paymentType = 'Invalid payment mode';
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Payment validation failed', errors);
  }
  next();
};

/**
 * Validate inventory item creation/update
 */
export const validateInventoryRequest = (req, res, next) => {
  const { itemName, itemType, quantity, unit, minQuantity, costPerUnit, purchaseAmount } = req.body;
  const errors = {};

  if (!itemName || typeof itemName !== 'string' || itemName.trim().length < 2) {
    errors.itemName = 'Item name must be at least 2 characters';
  }

  if (!itemType || !['Lining', 'Fabric', 'Thread', 'Accessories', 'Other'].includes(itemType)) {
    errors.itemType = 'Valid item category/type is required';
  }

  if (quantity !== undefined && quantity !== '') {
    const q = Number(quantity);
    if (isNaN(q) || q < 0) errors.quantity = 'Stock quantity cannot be negative';
  }

  if (unit && !['meters', 'pieces', 'rolls', 'yards', 'packs'].includes(unit)) {
    errors.unit = 'Invalid unit of measurement';
  }

  if (minQuantity !== undefined && minQuantity !== '') {
    const m = Number(minQuantity);
    if (isNaN(m) || m < 0) errors.minQuantity = 'Minimum alert quantity cannot be negative';
  }

  if (costPerUnit !== undefined && costPerUnit !== '') {
    const c = Number(costPerUnit);
    if (isNaN(c) || c < 0) errors.costPerUnit = 'Cost per unit cannot be negative';
  }

  if (purchaseAmount !== undefined && purchaseAmount !== '') {
    const p = Number(purchaseAmount);
    if (isNaN(p) || p < 0) errors.purchaseAmount = 'Purchase amount cannot be negative';
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Inventory validation failed', errors);
  }
  next();
};

/**
 * Validate karigar (artisan)
 */
export const validateKarigarRequest = (req, res, next) => {
  const { name, phone, specialization, status } = req.body;
  const errors = {};

  if (!name || typeof name !== 'string' || name.trim().length < 2) {
    errors.name = 'Artisan name must be at least 2 characters';
  }

  if (!phone) {
    errors.phone = 'Artisan phone number is required';
  } else {
    const cleanPhone = String(phone).replace(/[\s-]/g, '');
    if (!PHONE_REGEX.test(cleanPhone)) {
      errors.phone = 'Phone number must contain between 10 and 15 digits';
    }
  }

  if (specialization && !['Stitching', 'Cutting', 'Embroidery', 'Measurements', 'General'].includes(specialization)) {
    errors.specialization = 'Invalid artisan specialization';
  }

  if (status && !['Active', 'Inactive'].includes(status)) {
    errors.status = 'Status must be Active or Inactive';
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Karigar validation failed', errors);
  }
  next();
};

/**
 * Validate machine record
 */
export const validateMachineRequest = (req, res, next) => {
  const { name, type, status } = req.body;
  const errors = {};

  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    errors.name = 'Machine identifier/name is required';
  }

  if (!type || typeof type !== 'string' || type.trim().length === 0) {
    errors.type = 'Machine type is required';
  }

  if (status && !['Working', 'Under Maintenance', 'Broken'].includes(status)) {
    errors.status = 'Status must be Working, Under Maintenance, or Broken';
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Machine validation failed', errors);
  }
  next();
};

/**
 * Validate expense entry
 */
export const validateExpenseRequest = (req, res, next) => {
  const { amount, category } = req.body;
  const errors = {};

  const numAmount = Number(amount);
  if (!amount || isNaN(numAmount) || numAmount <= 0) {
    errors.amount = 'Expense amount must be a positive number';
  }

  if (!category || typeof category !== 'string' || category.trim().length === 0) {
    errors.category = 'Expense category is required';
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Expense validation failed', errors);
  }
  next();
};

/**
 * Validate user registration
 */
export const validateRegisterRequest = (req, res, next) => {
  const { name, email, password, shopName, phone } = req.body;
  const errors = {};

  if (!name || typeof name !== 'string' || name.trim().length < 2) {
    errors.name = 'Full name must be at least 2 characters';
  }

  if (!email || !EMAIL_REGEX.test(email.trim())) {
    errors.email = 'Valid email address is required';
  }

  if (!password || password.length < 6) {
    errors.password = 'Password must be at least 6 characters long';
  }

  if (!shopName || typeof shopName !== 'string' || shopName.trim().length < 2) {
    errors.shopName = 'Shop name must be at least 2 characters';
  }

  if (phone) {
    const cleanPhone = String(phone).replace(/[\s-]/g, '');
    if (!PHONE_REGEX.test(cleanPhone)) {
      errors.phone = 'Phone number must contain between 10 and 15 digits';
    }
  }

  if (Object.keys(errors).length > 0) {
    return formatErrorResponse(res, 'Registration validation failed', errors);
  }
  next();
};

export default {
  validateCustomerRequest,
  validateOrderCreateRequest,
  validateOrderUpdateRequest,
  validatePaymentRequest,
  validateInventoryRequest,
  validateKarigarRequest,
  validateMachineRequest,
  validateExpenseRequest,
  validateRegisterRequest,
};

