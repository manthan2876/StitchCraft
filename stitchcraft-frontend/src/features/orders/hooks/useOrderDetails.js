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

  // Notes states
  const [noteText, setNoteText] = useState('');
  const [noteLoading, setNoteLoading] = useState(false);
  const [noteError, setNoteError] = useState('');

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
    const parsedAmount = Number(payAmount);
    if (!payAmount || isNaN(parsedAmount) || parsedAmount <= 0) {
      setPaymentError('Please enter a valid positive payment amount.');
      return;
    }
    const asterPrice = order?.needsAster ? ((order.asterSellingPrice || 0) * (order.asterQuantity || 0)) : 0;
    const totalValue = (order?.price || 0) + asterPrice;
    const balanceAmount = order?.payment
      ? Math.max(0, order.payment.totalAmount - order.payment.paidAmount)
      : totalValue;

    if (parsedAmount > balanceAmount) {
      setPaymentError(`Payment amount (₹${parsedAmount}) cannot exceed the remaining balance (₹${balanceAmount}).`);
      return;
    }
    setPaymentLoading(true);
    setPaymentError('');
    try {
      const updatedOrder = await api.post(`/orders/${id}/payments`, {
        amount: parsedAmount,
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

  const handleStatusChange = async (newStatus, allowCredit = false, creditReason = '') => {
    try {
      const payload = { status: newStatus };
      if (allowCredit) {
        payload.allowCredit = true;
        payload.creditReason = creditReason;
      }
      const updatedOrder = await api.put(`/orders/${id}`, payload);
      setOrder(updatedOrder);
    } catch (err) {
      if (newStatus === 'Delivered' && (err.requiresCreditApproval || err.message?.includes('outstanding balance'))) {
        const confirmCredit = window.confirm(
          `${err.message}\n\nDo you want to confirm delivery on credit (Udhar)?`
        );
        if (confirmCredit) {
          const reason = window.prompt(
            'Enter reason for credit delivery (required for Udhar audit):',
            'Customer promised to settle by next visit'
          );
          if (reason && reason.trim()) {
            handleStatusChange(newStatus, true, reason.trim());
            return;
          } else {
            alert('A reason is required to approve delivery on credit.');
            return;
          }
        }
      }
      console.error('Failed to update status:', err);
      alert(err.message || 'Failed to update status.');
    }
  };

  const handleAddNote = async (e) => {
    e.preventDefault();
    if (!noteText.trim()) return;
    setNoteLoading(true);
    setNoteError('');
    try {
      const result = await api.post(`/orders/${id}/notes`, { text: noteText.trim() });
      setOrder(prev => ({ ...prev, notes: result.notes }));
      setNoteText('');
    } catch (err) {
      setNoteError(err.message || 'Failed to add note.');
    } finally {
      setNoteLoading(false);
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
    setPaymentError,
    isDeleteModalOpen,
    setIsDeleteModalOpen,
    deleteLoading,
    deleteError,
    handleRecordPayment,
    handleDeleteOrder,
    handleStatusChange,
    noteText,
    setNoteText,
    noteLoading,
    noteError,
    handleAddNote,
  };
};

