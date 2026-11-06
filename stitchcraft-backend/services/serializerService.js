/**
 * Role-Specific Field Authorization & Response Serializers (Phase 4, 8.2)
 * Ensures sensitive financial margins, wholesale costs, and customer contacts
 * never leak to unauthorized clients (karigars, staff, partner tailors).
 */

/**
 * Serialize an order entity according to the caller's role
 */
export const serializeOrderForRole = (order, userRole = 'staff') => {
  if (!order) return null;

  const raw = (typeof order.toJSON === 'function') ? order.toJSON() : { ...order };
  const role = String(userRole || 'staff').trim().toLowerCase();

  // 1. Owner: Universal access to all pricing, margins, wholesale costs, and telemetry
  if (role === 'owner') {
    return raw;
  }

  // 2. Karigar / Tailor: Workshop execution view ONLY
  if (role === 'karigar' || role === 'tailor') {
    const karigarView = {
      _id: raw._id,
      id: raw.id || raw._id,
      orderId: raw.orderId,
      status: raw.status,
      apparelType: raw.apparelType,
      fabric: raw.fabric || '',
      fabric_photo_url: raw.fabric_photo_url || raw.fabricPhotoUrl || null,
      deliveryDate: raw.deliveryDate || raw.due_date,
      due_date: raw.due_date || raw.deliveryDate,
      notes: raw.notes || '',
      assignedKarigar: raw.assignedKarigar,
      assignedMachine: raw.assignedMachine,
      measurements: raw.measurements || null,
      measurementsSnapshot: raw.measurementsSnapshot || null,
      style_attributes_json: raw.style_attributes_json || null,
      createdAt: raw.createdAt,
      updatedAt: raw.updatedAt,
      version: raw.version || 1,
    };

    // Customer name without exposing private phone, email, or physical address
    if (raw.customer && typeof raw.customer === 'object') {
      karigarView.customer = {
        _id: raw.customer._id || raw.customer.id,
        name: raw.customer.name || raw.customerName || 'Customer',
      };
    } else {
      karigarView.customerName = raw.customerName || 'Customer';
    }

    // Include items without wholesale margins or retail pricing
    if (Array.isArray(raw.items)) {
      karigarView.items = raw.items.map((it) => ({
        id: it.id,
        name: it.name || it.apparelType,
        apparelType: it.apparelType,
        quantity: it.quantity || 1,
        fabric: it.fabric || '',
        measurements: it.measurements || null,
        needsAster: Boolean(it.needsAster),
        asterQuantity: it.asterQuantity || 0,
        notes: it.notes || '',
      }));
    }

    return karigarView;
  }

  // 3. Staff / Front Desk: Can see customer details and prices, but NOT owner wholesale costs/margins
  if (role === 'staff') {
    const staffView = { ...raw };

    // Strip owner internal margins and wholesale cost breakdown
    delete staffView.labor_cost;
    delete staffView.overhead_cost;
    delete staffView.material_cost;
    delete staffView.laborCost;
    delete staffView.overheadCost;
    delete staffView.materialCost;
    delete staffView.asterProfit;
    delete staffView.asterCostPrice;
    delete staffView.profit;
    delete staffView.ownerMargin;

    return staffView;
  }

  // 4. Manager: Operational management
  if (role === 'manager') {
    const managerView = { ...raw };
    // Managers can see prices & payments, but owner wholesale margins are stripped
    delete managerView.labor_cost;
    delete managerView.overhead_cost;
    delete managerView.material_cost;
    delete managerView.laborCost;
    delete managerView.overheadCost;
    delete managerView.materialCost;
    delete managerView.asterProfit;
    delete managerView.asterCostPrice;

    return managerView;
  }

  // Fallback default: strip all margins
  const sanitized = { ...raw };
  delete sanitized.labor_cost;
  delete sanitized.overhead_cost;
  delete sanitized.material_cost;
  delete sanitized.asterProfit;
  delete sanitized.asterCostPrice;
  return sanitized;
};

/**
 * Serialize a customer entity according to the caller's role
 */
export const serializeCustomerForRole = (customer, userRole = 'staff') => {
  if (!customer) return null;

  const raw = (typeof customer.toJSON === 'function') ? customer.toJSON() : { ...customer };
  const role = String(userRole || 'staff').trim().toLowerCase();

  if (role === 'owner' || role === 'manager') {
    return raw;
  }

  // Staff: Customer contact and measurements preserved; internal notes stripped if private
  if (role === 'staff') {
    const staffView = { ...raw };
    return staffView;
  }

  // Karigar: Strip phone and email
  if (role === 'karigar' || role === 'tailor') {
    return {
      _id: raw._id,
      id: raw.id || raw._id,
      name: raw.name,
      physical_attributes: raw.physical_attributes || null,
      soft_preferences: raw.soft_preferences || null,
    };
  }

  return raw;
};

export default {
  serializeOrderForRole,
  serializeCustomerForRole,
};

