import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../../../services/api';
import { getSignedUrl } from '../../../services/supabase';

export const useOrderDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [maapSignedUrl, setMaapSignedUrl] = useState('');

  // Payment Modal states
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [payAmount, setPayAmount] = useState('');
  const [payType, setPayType] = useState('Cash');
  const [paymentLoading, setPaymentLoading] = useState(false);
  const [paymentError, setPaymentError] = useState('');

  // Delete Order states
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  const fetchOrderDetails = async () => {
    setLoading(true);
    try {
      const data = await api.get(`/orders/${id}`);
      setOrder(data);
    } catch (err) {
      console.error('Failed to fetch order details:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrderDetails();
  }, [id]);

  useEffect(() => {
    const fetchSignedUrl = async () => {
      if (order && order.maapImageUrl) {
        if (order.maapImageUrl.startsWith('http://') || order.maapImageUrl.startsWith('https://')) {
          setMaapSignedUrl(order.maapImageUrl);
        } else {
          const url = await getSignedUrl('maap-images', order.maapImageUrl);
          if (url) {
            setMaapSignedUrl(url);
          }
        }
      }
    };
    fetchSignedUrl();
  }, [order]);

  const handleRecordPayment = async (e) => {
    e.preventDefault();
    if (!payAmount || Number(payAmount) <= 0) {
      setPaymentError('Please enter a valid amount.');
      return;
    }
    setPaymentLoading(true);
    setPaymentError('');
    try {
      const updatedOrder = await api.post(`/orders/${id}/payments`, {
        amount: Number(payAmount),
        paymentType: payType
      });
      setOrder(updatedOrder);
      setIsPaymentModalOpen(false);
      setPayAmount('');
    } catch (err) {
      setPaymentError(err.message || 'Failed to record payment.');
    } finally {
      setPaymentLoading(false);
    }
  };

  const handleDeleteOrder = async () => {
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/orders/${id}`);
      navigate('/orders');
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete order.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleStatusChange = async (newStatus) => {
    try {
      const updatedOrder = await api.put(`/orders/${id}`, { status: newStatus });
      setOrder(updatedOrder);
    } catch (err) {
      console.error('Failed to update status:', err);
      alert('Failed to update status.');
    }
  };

  return {
    id,
    order,
    loading,
    maapSignedUrl,
    isPaymentModalOpen,
    setIsPaymentModalOpen,
    payAmount,
    setPayAmount,
    payType,
    setPayType,
    paymentLoading,
    paymentError,
    isDeleteModalOpen,
    setIsDeleteModalOpen,
    deleteLoading,
    deleteError,
    handleRecordPayment,
    handleDeleteOrder,
    handleStatusChange,
  };
};
