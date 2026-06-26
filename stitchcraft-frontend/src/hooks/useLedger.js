/* src/hooks/useLedger.js */
import { useState, useEffect } from 'react';
import { api } from '../services/api';

export const useLedger = () => {
  const [transactions, setTransactions] = useState([]);
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);

  // Fetch orders from backend
  const fetchOrders = async () => {
    try {
      const data = await api.get('/orders');
      setOrders(data);
    } catch (err) {
      console.error('Failed to fetch orders:', err);
    }
  };

  // Fetch transactions from backend
  const fetchTransactions = async () => {
    try {
      const data = await api.get('/ledger/transactions');
      setTransactions(data);
    } catch (err) {
      console.error('Failed to fetch transactions:', err);
    }
  };

  // Initial load
  const loadData = async () => {
    setLoading(true);
    await Promise.all([fetchOrders(), fetchTransactions()]);
    setLoading(false);
  };

  useEffect(() => {
    if (localStorage.getItem('stitchcraft_token')) {
      loadData();
    }
  }, []);

  // Log a new custom tailoring order
  const addOrder = async (order) => {
    try {
      const newOrder = await api.post('/orders', order);
      setOrders((prev) => [newOrder, ...prev]);
      
      // Since order creation might trigger an automatic advance deposit transaction,
      // let's re-fetch transactions to sync the ledger log.
      if (Number(order.advancePaid) > 0) {
        fetchTransactions();
      }
      return newOrder;
    } catch (err) {
      console.error('Failed to add order:', err);
      throw err;
    }
  };

  // Update order stage / status
  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      const updatedOrder = await api.put(`/orders/${orderId}`, { status: newStatus });
      setOrders((prev) =>
        prev.map((o) => (o.id === orderId ? updatedOrder : o))
      );
      return updatedOrder;
    } catch (err) {
      console.error('Failed to update order status:', err);
      throw err;
    }
  };

  // Add transaction (for settlements/payments)
  const addTransaction = async (tx) => {
    try {
      if (tx.orderId) {
        // Record payment against the order
        const data = await api.post(`/orders/${tx.orderId}/payments`, {
          amount: tx.amount,
          description: tx.description,
          type: tx.type || 'Credit'
        });
        
        // Refresh transactions and sync updated order advancePaid
        fetchTransactions();
        setOrders((prev) =>
          prev.map((o) => (o.id === tx.orderId ? data.order : o))
        );
      }
    } catch (err) {
      console.error('Failed to add transaction:', err);
      throw err;
    }
  };

  return {
    transactions,
    orders,
    addOrder,
    updateOrderStatus,
    addTransaction,
    loading,
    refreshLedger: loadData
  };
};
