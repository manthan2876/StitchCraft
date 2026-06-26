/* src/pages/OrderDetails.jsx */
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import {
  MdArrowBack, MdPhone, MdEdit, MdDelete, MdClose,
  MdPayments, MdLocalShipping, MdOutlineInventory,
  MdAssignmentInd, MdBookmarkBorder, MdCameraAlt
} from 'react-icons/md';
import { FaWhatsapp } from 'react-icons/fa';
import { GiSewingMachine } from 'react-icons/gi';
import { useLanguage } from '../context/LanguageContext';
import { getSignedUrl } from '../services/supabase';
import { formatCurrency, formatDate } from '../utils/formatters';

export const OrderDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [maapSignedUrl, setMaapSignedUrl] = useState('');

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

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

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

  if (loading) {
    return <div className="w-full py-12 text-center text-sm text-text-muted">{tf('syncing', 'Syncing...')}</div>;
  }

  if (!order) {
    return (
      <Card className="flex flex-col items-center justify-center py-12 text-center gap-4">
        <h4 className="text-sm font-bold text-text-main">{tf('recordNotFound', 'Record Not Found')}</h4>
        <p className="text-xs text-text-muted font-semibold">{tf('orderNotFoundDesc', 'Order details could not be found.')}</p>
        <button onClick={() => navigate('/orders')} className="btn-tactile cursor-pointer">
          <span className="text-white-forced">{tf('backToRegistry', 'Back to Registry')}</span>
        </button>
      </Card>
    );
  }

  const asterPrice = order.needsAster ? ((order.asterSellingPrice || 0) * (order.asterQuantity || 0)) : 0;
  const totalValue = order.price + asterPrice;
  const balanceAmount = order.payment
    ? Math.max(0, order.payment.totalAmount - order.payment.paidAmount)
    : totalValue;

  const isFullyPaid = balanceAmount === 0;

  const statusList = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered', 'Cancelled'];

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'Incoming': return 'bg-blue-500/10 text-blue-500 border border-blue-500/20';
      case 'Measuring': return 'bg-amber-500/10 text-amber-500 border border-amber-500/20';
      case 'Cutting': return 'bg-cyan-500/10 text-cyan-500 border border-cyan-500/20';
      case 'Stitching': return 'bg-purple-500/10 text-purple-500 border border-purple-500/20';
      case 'Checking': return 'bg-pink-500/10 text-pink-500 border border-pink-500/20';
      case 'Ready': return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
      case 'Delivered': return 'bg-gray-500/10 text-gray-500 border border-gray-500/20';
      case 'Cancelled': return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default: return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  return (
    <div className="flex flex-col gap-6 select-none max-w-5xl mx-auto text-left">
      {/* Header Actions */}
      <div className="flex items-center justify-between">
        <Link to="/orders" className="flex items-center gap-1.5 text-xs text-text-muted hover:text-text-main font-bold transition-colors">
          <MdArrowBack className="w-4 h-4" />
          <span>{tf('backToOrders', 'Back to Orders')}</span>
        </Link>
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate(`/orders/${order._id}/edit`)}
            className="px-3.5 py-1.5 bg-bg-secondary hover:bg-bg-card-hover text-text-main border border-border-medium hover:border-color-accent-purple/50 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1 transition-all"
          >
            <MdEdit className="w-3.5 h-3.5 text-color-accent-purple" />
            <span>{tf('editOrder', 'Edit Order')}</span>
          </button>
          <button
            onClick={() => setIsDeleteModalOpen(true)}
            className="px-3.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 border border-rose-500/20 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1 transition-all"
          >
            <MdDelete className="w-3.5 h-3.5 text-color-accent-pink" />
            <span>{tf('deleteOrder', 'Delete Order')}</span>
          </button>
        </div>
      </div>

      {/* Main Order Overview Card */}
      <Card className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-color-accent-purple/20 text-color-accent-purple flex items-center justify-center font-black text-2xl shadow-inner shrink-0">
            {order.apparelType ? order.apparelType[0].toUpperCase() : 'O'}
          </div>
          <div>
            <div className="flex items-center gap-2.5 flex-wrap">
              <h3 className="text-xl font-bold text-text-main tracking-wide">
                {tf('apparel' + order.apparelType, order.apparelType)}
              </h3>
              <span className="px-2.5 py-0.5 text-[10px] font-black bg-bg-secondary text-text-main rounded-md border border-border-subtle uppercase tracking-wider">
                {order.orderId}
              </span>
            </div>
            <p className="text-xs text-text-muted mt-1.5 font-semibold">
              {tf('customer', 'Customer')}: <Link to={`/customers/${order.customer?._id || order.customer}`} className="text-color-accent-purple hover:underline font-extrabold">{order.customerName}</Link>
            </p>
          </div>
        </div>

        {/* Status Dropdown */}
        <div className="flex flex-col gap-1 w-full md:w-auto">
          <label className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('productionStatus', 'Production Status')}</label>
          <select
            value={order.status}
            onChange={(e) => handleStatusChange(e.target.value)}
            className={`px-4 py-2 border rounded-xl text-xs font-black outline-none bg-bg-secondary cursor-pointer transition-all ${getStatusBadgeClass(order.status)}`}
          >
            {statusList.map(s => (
              <option key={s} value={s} className="bg-bg-card text-text-main font-bold">{tf('status' + s, s)}</option>
            ))}
          </select>
        </div>
      </Card>

      {/* Three Column Info Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left Column: Order details & fabrication */}
        <div className="lg:col-span-2 flex flex-col gap-6">

          {/* Order Specifications Card */}
          <Card className="flex flex-col gap-5">
            <h3 className="text-sm font-black text-text-main uppercase tracking-wider border-b border-border-subtle pb-3">
              📐 {tf('orderSpecifications', 'Order Specifications')}
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <div className="flex flex-col gap-1">
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('fabricType', 'Fabric Description')}</span>
                <span className="text-sm font-semibold text-text-main">{order.fabric || tf('notSpecified', 'Not specified')}</span>
              </div>
              <div className="flex flex-col gap-1">
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('orderDate', 'Order Placement')}</span>
                <span className="text-sm font-semibold text-text-main">{formatDate(order.date)}</span>
              </div>
            </div>

            {/* Lining / Astar Details */}
            <div className="flex flex-col gap-3 p-4 bg-bg-secondary border border-border-subtle rounded-2xl">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-color-accent-pink/10 flex items-center justify-center text-color-accent-pink">
                    <MdOutlineInventory className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-text-main">{tf('astarLining', 'Lining / Astar Material')}</h4>
                    <p className="text-[10px] text-text-muted font-medium mt-0.5">
                      {order.needsAster
                        ? `${tf('required', 'Required')}: ${order.asterQuantity} ${order.asterInventoryItem?.unit || 'meters'}`
                        : tf('notRequired', 'No lining needed')}
                    </p>
                  </div>
                </div>
                <div className="self-start sm:self-auto">
                  {order.needsAster ? (
                    order.asterDeducted ? (
                      <span style={{ whiteSpace: 'nowrap' }} className="px-2.5 py-1 text-[9px] font-black uppercase tracking-wider bg-emerald-500/10 text-emerald-500 border border-emerald-500/20 rounded-md">
                        ✓ {tf('deducted', 'Stock Deducted')}
                      </span>
                    ) : (
                      <span style={{ whiteSpace: 'nowrap' }} className="px-2.5 py-1 text-[9px] font-black uppercase tracking-wider bg-amber-500/10 text-amber-500 border border-amber-500/20 rounded-md">
                        ⚠ {tf('pendingDeduction', 'Pending Stitching')}
                      </span>
                    )
                  ) : (
                    <span style={{ whiteSpace: 'nowrap' }} className="px-2.5 py-1 text-[9px] font-black uppercase tracking-wider bg-bg-hover text-text-muted border border-border-subtle rounded-md">
                      {tf('noVal', 'None')}
                    </span>
                  )}
                </div>
              </div>

              {order.needsAster && (
                <div className="mt-2 pt-3 border-t border-border-subtle/50 grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                  <div className="flex flex-col">
                    <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('liningMaterial', 'Material')}</span>
                    <span className="text-xs font-semibold text-text-main mt-0.5 truncate">{order.asterInventoryItem?.itemName || tf('unknown', 'Unknown')}</span>
                  </div>
                  <div className="flex flex-col">
                    <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('liningCostPrice', 'Cost/Unit')}</span>
                    <span className="text-xs font-semibold text-text-main mt-0.5">₹{(order.asterCostPrice || 0).toFixed(2)}</span>
                  </div>
                  <div className="flex flex-col">
                    <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('liningSellingPrice', 'Selling/Unit')}</span>
                    <span className="text-xs font-semibold text-text-main mt-0.5">₹{(order.asterSellingPrice || 0).toFixed(2)}</span>
                  </div>
                  <div className="flex flex-col">
                    <span className="text-[9px] font-bold text-color-accent-emerald uppercase tracking-wider">{tf('liningProfit', 'Total Profit')}</span>
                    <span className="text-xs font-bold text-color-accent-emerald mt-0.5">₹{(order.asterProfit || 0).toFixed(2)}</span>
                  </div>
                </div>
              )}
            </div>

            {/* Assigned Karigar */}
            <div className="p-4 bg-bg-secondary border border-border-subtle rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-color-accent-purple/10 flex items-center justify-center text-color-accent-purple">
                  <MdAssignmentInd className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-text-main">{tf('assignedKarigar', 'Assigned Karigar')}</h4>
                  <p className="text-[10px] text-text-muted font-medium mt-0.5">
                    {order.assignedKarigar ? order.assignedKarigar.specialization : tf('productionStaff', 'Tailoring Artisan')}
                  </p>
                </div>
              </div>
              <div className="self-start sm:self-auto">
                {order.assignedKarigar ? (
                  <Link
                    to={`/karigars/${order.assignedKarigar._id || order.assignedKarigar}`}
                    style={{ whiteSpace: 'nowrap' }}
                    className="px-3 py-1 bg-color-accent-purple/10 text-color-accent-purple border border-color-accent-purple/20 text-xs font-bold rounded-xl hover:bg-color-accent-purple/20 transition-all"
                  >
                    {order.assignedKarigar.name || order.assignedKarigar} →
                  </Link>
                ) : (
                  <span style={{ whiteSpace: 'nowrap' }} className="px-2.5 py-1 text-[9px] font-black uppercase tracking-wider bg-rose-500/10 text-rose-500 border border-rose-500/20 rounded-md">
                    {tf('unassigned', 'Unassigned')}
                  </span>
                )}
              </div>
            </div>

            {/* Assigned Machine */}
            <div className="p-4 bg-bg-secondary border border-border-subtle rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-color-accent-purple/10 flex items-center justify-center text-color-accent-purple">
                  <GiSewingMachine className="w-5.5 h-5.5 text-color-accent-purple" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-text-main">{tf('assignedMachine', 'Assigned Machine')}</h4>
                  <p className="text-[10px] text-text-muted font-medium mt-0.5">
                    {order.assignedMachine ? order.assignedMachine.type : tf('sewingMachinery', 'Sewing Machinery')}
                  </p>
                </div>
              </div>
              <div className="self-start sm:self-auto">
                {order.assignedMachine ? (
                  <span style={{ whiteSpace: 'nowrap' }} className="px-3 py-1 bg-color-accent-purple/15 text-color-accent-purple border border-color-accent-purple/25 text-xs font-black rounded-xl">
                    {order.assignedMachine.name || order.assignedMachine}
                  </span>
                ) : (
                  <span style={{ whiteSpace: 'nowrap' }} className="px-2.5 py-1 text-[9px] font-black uppercase tracking-wider bg-rose-500/10 text-rose-500 border border-rose-500/20 rounded-md">
                    {tf('unassigned', 'Unassigned')}
                  </span>
                )}
              </div>
            </div>
          </Card>

          {/* Customer Sizing / Maap Details */}
          <Card className="flex flex-col gap-5">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center justify-between border-b border-border-subtle pb-3">
              <h3 className="text-sm font-black text-text-main uppercase tracking-wider">
                📏 {tf('measurementsOrMaap', 'Measurements / Sizing')}
              </h3>
              <span className="self-start sm:self-auto text-[10px] font-black uppercase tracking-widest px-2.5 py-0.5 rounded bg-bg-secondary border border-border-subtle text-text-muted whitespace-nowrap">
                {order.measurementType === 'Maap' ? '🧵 Custom Maap' : '📐 Dimensions'}
              </span>
            </div>

            {order.measurementType === 'Maap' ? (
              <div className="flex flex-col items-center justify-center py-6 border-2 border-dashed border-border-subtle rounded-2xl gap-3 text-center">
                {maapSignedUrl ? (
                  <div className="relative group max-w-sm rounded-xl overflow-hidden shadow-md">
                    <img src={maapSignedUrl} alt="Maap Pattern" className="max-h-80 object-contain mx-auto" />
                    <a
                      href={maapSignedUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white-forced font-bold text-xs transition-opacity cursor-pointer"
                    >
                      Open Full Size ↗
                    </a>
                  </div>
                ) : (
                  <>
                    <MdCameraAlt className="w-10 h-10 text-text-muted" />
                    <div>
                      <h4 className="text-xs font-bold text-text-main">{tf('noMaapImage', 'No reference Maap image uploaded.')}</h4>
                      <p className="text-[10px] text-text-muted mt-0.5">{tf('noMaapImageDesc', 'Edit order to upload a picture of the customer\'s sample garment.')}</p>
                    </div>
                  </>
                )}
              </div>
            ) : (
              <div className="flex flex-col gap-6">
                {/* Display customer measurements */}
                {(order.measurementsSnapshot || order.measurements) ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* Shirt */}
                    {(order.measurementsSnapshot?.shirt || order.measurements?.shirt) && Object.values(order.measurementsSnapshot?.shirt || order.measurements?.shirt).some(v => v > 0) && (
                      <div className="flex flex-col gap-3">
                        <h4 className="text-xs font-bold text-text-main uppercase tracking-wider border-b border-border-subtle pb-1.5">{tf('shirtParameters', 'Shirt Parameters')}</h4>
                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                          {Object.entries(order.measurementsSnapshot?.shirt || order.measurements?.shirt).map(([field, val]) => val > 0 && (
                            <div key={`s-${field}`} className="bg-bg-secondary px-2.5 py-2 border border-border-subtle rounded-xl flex flex-col items-center">
                              <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf(field, field)}</span>
                              <span className="text-sm font-black text-text-main mt-0.5">{val}"</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Pant */}
                    {(order.measurementsSnapshot?.pant || order.measurements?.pant) && Object.values(order.measurementsSnapshot?.pant || order.measurements?.pant).some(v => v > 0) && (
                      <div className="flex flex-col gap-3">
                        <h4 className="text-xs font-bold text-text-main uppercase tracking-wider border-b border-border-subtle pb-1.5">{tf('pantParameters', 'Pant Parameters')}</h4>
                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                          {Object.entries(order.measurementsSnapshot?.pant || order.measurements?.pant).map(([field, val]) => val > 0 && (
                            <div key={`p-${field}`} className="bg-bg-secondary px-2.5 py-2 border border-border-subtle rounded-xl flex flex-col items-center">
                              <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf(field, field)}</span>
                              <span className="text-sm font-black text-text-main mt-0.5">{val}"</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="text-center py-6 text-xs text-text-muted font-bold">
                    {tf('noMeasurementsRecorded', 'No specific measurements recorded on this customer record yet.')}
                  </div>
                )}

                {(order.measurementsSnapshot?.others || order.measurements?.others) && (
                  <div className="bg-bg-secondary border border-border-subtle rounded-xl p-4 text-xs">
                    <span className="font-bold text-color-accent-purple flex items-center gap-1 uppercase tracking-wider mb-2">
                      <MdBookmarkBorder /> {tf('specialSewingNotes', 'Special Sewing Notes')}
                    </span>
                    <p className="text-text-main opacity-80 italic">"{order.measurementsSnapshot?.others || order.measurements?.others}"</p>
                  </div>
                )}
              </div>
            )}
          </Card>
        </div>

        {/* Right Column: Payments & Deliveries */}
        <div className="flex flex-col gap-6">

          {/* Payment Card */}
          <Card className="flex flex-col gap-5 border-l-4 border-l-emerald-500">
            <div className="flex items-center justify-between border-b border-border-subtle pb-3">
              <h3 className="text-sm font-black text-text-main uppercase tracking-wider">
                💰 {tf('billingOverview', 'Billing Overview')}
              </h3>
              <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${isFullyPaid
                  ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
                  : 'bg-amber-500/10 text-amber-500 border border-amber-500/20'
                }`}>
                {isFullyPaid ? tf('fullyPaid', 'Fully Paid') : tf('pendingBalance', 'Pending Balance')}
              </span>
            </div>

            <div className="flex flex-col gap-3.5">
              <div className="flex items-center justify-between text-xs">
                <span className="text-text-muted font-bold">{tf('totalPrice', 'Total Price')}</span>
                <span className="font-black text-text-main text-sm">{formatCurrency(order.payment?.totalAmount || order.price)}</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-text-muted font-bold">{tf('advancePaid', 'Paid So Far')}</span>
                <span className="font-black text-emerald-500 text-sm">{formatCurrency(order.payment?.paidAmount || 0)}</span>
              </div>
              <div className="flex items-center justify-between border-t border-border-subtle pt-3 text-xs">
                <span className="text-text-muted font-extrabold">{tf('balanceDue', 'Balance Due')}</span>
                <span className="font-black text-rose-500 text-base">{formatCurrency(balanceAmount)}</span>
              </div>
            </div>

            {order.payment?.paymentType && (
              <div className="text-[10px] text-text-muted font-bold flex items-center gap-1 uppercase tracking-wider bg-bg-secondary p-2 rounded border border-border-subtle">
                <MdPayments className="text-color-accent-purple" /> {tf('latestPaymentMode', 'Payment Mode')}: {order.payment.paymentType}
              </div>
            )}

            {!isFullyPaid && (
              <button
                onClick={() => setIsPaymentModalOpen(true)}
                className="w-full mt-2 py-2.5 bg-emerald-500 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-emerald-950/20 hover:bg-emerald-600 transition-all flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <MdPayments className="w-4 h-4 text-white-forced" />
                <span>{tf('recordPayment', 'Record Payment')}</span>
              </button>
            )}

            {order.transactions && order.transactions.length > 0 && (
              <div className="mt-4 pt-4 border-t border-border-subtle flex flex-col gap-2">
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('paymentHistory', 'Payment History')}</span>
                <div className="flex flex-col gap-2 max-h-48 overflow-y-auto pr-1">
                  {order.transactions.map((tx) => (
                    <div key={tx._id} className="flex justify-between items-center bg-bg-secondary/60 border border-border-subtle/40 rounded-xl p-2.5 text-[11px] font-semibold text-text-main">
                      <div className="flex flex-col gap-0.5">
                        <span className="font-bold">{tx.paymentType || 'Cash'}</span>
                        <span className="text-[9px] text-text-muted">{new Date(tx.date).toLocaleDateString()}</span>
                      </div>
                      <span className={tx.type === 'Refund' ? 'text-rose-500 font-extrabold' : 'text-emerald-500 font-extrabold'}>
                        {tx.type === 'Refund' ? '-' : '+'}{formatCurrency(tx.amount)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </Card>

          {/* Delivery Card */}
          <Card className="flex flex-col gap-5 border-l-4 border-l-blue-500">
            <div className="flex items-center justify-between border-b border-border-subtle pb-3">
              <h3 className="text-sm font-black text-text-main uppercase tracking-wider">
                📦 {tf('deliveryStatus', 'Delivery Tracking')}
              </h3>
              <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${order.delivery?.status === 'Delivered'
                  ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
                  : 'bg-blue-500/10 text-blue-500 border border-blue-500/20'
                }`}>
                {order.delivery?.status === 'Delivered' ? tf('delivered', 'Delivered') : tf('statusPending', 'Pending')}
              </span>
            </div>

            <div className="flex flex-col gap-3.5 text-xs font-semibold text-text-muted">
              <div className="flex items-center justify-between">
                <span>{tf('deliveryDeadline', 'Delivery Deadline')}</span>
                <span className="text-text-main font-bold">{formatDate(order.deliveryDate)}</span>
              </div>

              {order.delivery?.deliveredBy && (
                <div className="flex items-center justify-between border-t border-border-subtle pt-3">
                  <span>{tf('deliveredBy', 'Handled By')}</span>
                  <span className="text-text-main font-bold">{order.delivery.deliveredBy}</span>
                </div>
              )}

              {order.delivery?.status !== 'Delivered' && (
                <div className="p-3.5 bg-bg-secondary border border-border-subtle rounded-xl flex items-center gap-3 mt-1">
                  <MdLocalShipping className="text-color-accent-blue w-5 h-5 shrink-0" />
                  <p className="text-[10px] leading-relaxed">
                    {tf('deliveryDisclaimer', 'Maintain stitching flow coordinates to deliver items on time.')}
                  </p>
                </div>
              )}
            </div>
          </Card>

          {/* Customer CRM Card */}
          <Card className="flex flex-col gap-4">
            <h3 className="text-xs font-black text-text-main uppercase tracking-wider border-b border-border-subtle pb-3">
              👤 {tf('customerContacts', 'Customer Profile')}
            </h3>

            <div className="flex flex-col gap-3">
              <h4 className="text-sm font-bold text-text-main leading-snug">{order.customerName}</h4>

              <div className="flex flex-col gap-2.5 text-xs text-text-muted font-semibold">
                <span className="flex items-center gap-2">
                  <MdPhone className="w-4 h-4 text-color-accent-purple" /> {order.customer?.phone || 'No phone recorded'}
                  <button
                    onClick={() => {
                      const cleanPhone = (order.customer?.phone || '0000000000').replace(/\D/g, '');
                      const formattedPhone = cleanPhone.length === 10 ? '91' + cleanPhone : cleanPhone;
                      const message = `Hello ${order.customerName}, payment or details updates regarding your garment ${order.orderId} are available.`;
                      window.open(`https://wa.me/${formattedPhone}?text=${encodeURIComponent(message)}`, '_blank');
                    }}
                    className="ml-1.5 p-1 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-500 rounded-lg transition-all cursor-pointer flex items-center justify-center"
                    title="WhatsApp"
                  >
                    <FaWhatsapp className="w-3.5 h-3.5" />
                  </button>
                </span>

                {order.customer?.address && (
                  <div className="border-t border-border-subtle pt-2.5 mt-0.5">
                    <span className="text-[10px] uppercase font-bold tracking-wider block mb-1 text-text-muted/65">{t('address')}</span>
                    <span className="text-text-main text-xs">{order.customer.address}</span>
                  </div>
                )}
              </div>
            </div>
          </Card>

        </div>
      </div>

      {/* Record Payment Dialog Modal */}
      {isPaymentModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsPaymentModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
              <MdPayments className="text-emerald-500 w-5 h-5" />
              {tf('recordPayment', 'Record Payment')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {tf('recordPaymentDesc', 'Enter partial or full amount received from the customer for this order.')}
            </p>

            <form onSubmit={handleRecordPayment} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('amountReceived', 'Amount (₹)')}</label>
                <input
                  type="number"
                  required
                  min="1"
                  max={balanceAmount}
                  value={payAmount}
                  onChange={e => { setPayAmount(e.target.value); setPaymentError(''); }}
                  placeholder={`Max ₹${balanceAmount}`}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-black placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('paymentMode', 'Payment Mode')}</label>
                <select
                  value={payType}
                  onChange={e => setPayType(e.target.value)}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                >
                  <option value="Cash" className="bg-bg-card">💵 Cash</option>
                  <option value="UPI" className="bg-bg-card">📱 UPI / Online</option>
                  <option value="Card" className="bg-bg-card">💳 Card</option>
                </select>
              </div>

              {paymentError && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
                  {paymentError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsPaymentModalOpen(false)}
                  className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer"
                >
                  {tf('cancel', 'Cancel')}
                </button>
                <button
                  type="submit"
                  disabled={paymentLoading}
                  className="flex-1 py-2.5 bg-emerald-500 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-emerald-500/20 hover:bg-emerald-600 transition-all cursor-pointer disabled:opacity-50"
                >
                  {paymentLoading ? tf('saving', 'Saving...') : tf('confirmPayment', 'Confirm')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Order Dialog Modal */}
      {isDeleteModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsDeleteModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdDelete className="text-color-accent-pink w-5 h-5" />
              {tf('deleteOrder', 'Delete Order')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {tf('deleteOrderConfirm', 'Are you sure you want to permanently delete the tailoring order record')} <span className="text-text-main font-bold">{order.orderId}</span>?
            </p>

            {deleteError && (
              <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">
                {deleteError}
              </span>
            )}

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setIsDeleteModalOpen(false)}
                className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer"
              >
                {tf('cancel', 'Cancel')}
              </button>
              <button
                onClick={handleDeleteOrder}
                disabled={deleteLoading}
                className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg transition-all cursor-pointer disabled:opacity-50"
              >
                {deleteLoading ? tf('saving', 'Saving...') : tf('deleteOrder', 'Delete Order')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default OrderDetails;
