import { useState, useEffect } from 'react';
import { api } from '../services/api';

export const useCustomers = () => {
  const [customers, setCustomers] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(false);

  // Fetch customers from backend
  const fetchCustomers = async (search = '') => {
    setLoading(true);
    try {
      const data = await api.get(`/customers?search=${encodeURIComponent(search)}`);
      setCustomers(data);
    } catch (err) {
      console.error('Failed to fetch customers:', err);
    } finally {
      setLoading(false);
    }
  };

  // Re-fetch when search changes
  useEffect(() => {
    if (localStorage.getItem('stitchcraft_token')) {
      fetchCustomers(searchQuery);
    }
  }, [searchQuery]);

  // Create a new customer profile
  const addCustomer = async (customer) => {
    try {
      const data = await api.post('/customers', customer);
      setCustomers((prev) => [data, ...prev]);
      return data;
    } catch (err) {
      console.error('Failed to add customer:', err);
      throw err;
    }
  };

  // Update customer sizing measurements
  const updateMeasurements = async (customerId, measurements) => {
    try {
      const data = await api.put(`/customers/${customerId}`, { measurements });
      setCustomers((prev) =>
        prev.map((c) => (c.id === customerId ? data : c))
      );
      return data;
    } catch (err) {
      console.error('Failed to update measurements:', err);
      throw err;
    }
  };

  return {
    customers,
    rawCustomers: customers,
    searchQuery,
    setSearchQuery,
    addCustomer,
    updateMeasurements,
    loading,
    refreshCustomers: () => fetchCustomers(searchQuery),
  };
};
