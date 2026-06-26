/**
 * Calculates the total order value of a list of orders
 * @param {Array} orders
 * @returns {number}
 */
export const calculateTotalValue = (orders) => {
  return orders.reduce((sum, order) => sum + (Number(order.totalAmount) || 0), 0);
};

/**
 * Calculates the total advance payments collected
 * @param {Array} orders
 * @returns {number}
 */
export const calculateTotalAdvances = (orders) => {
  return orders.reduce((sum, order) => sum + (Number(order.advancePaid) || 0), 0);
};

/**
 * Calculates total outstanding dues (totalAmount - advancePaid)
 * @param {Array} orders
 * @returns {number}
 */
export const calculateTotalDues = (orders) => {
  return orders.reduce((sum, order) => {
    const due = (Number(order.totalAmount) || 0) - (Number(order.advancePaid) || 0);
    return sum + (due > 0 ? due : 0);
  }, 0);
};

/**
 * Groups orders by their current status
 * @param {Array} orders
 * @returns {Object}
 */
export const getStatusCounts = (orders) => {
  return orders.reduce((counts, order) => {
    const status = order.status || 'Pending';
    counts[status] = (counts[status] || 0) + 1;
    return counts;
  }, {});
};
