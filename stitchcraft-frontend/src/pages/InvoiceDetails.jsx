/* src/pages/InvoiceDetails.jsx */
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { useLanguage } from '../context/LanguageContext';
import { formatCurrency, formatDate } from '../utils/formatters';
import {
  MdArrowBack as BackIcon,
  MdPrint as PrintIcon,
  MdShare as ShareIcon,
  MdAlarm as AlarmIcon,
  MdCheckCircle as CheckIcon,
  MdReceipt as InvoiceIcon,
} from 'react-icons/md';
import { FaWhatsapp } from 'react-icons/fa';

export const InvoiceDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [shop, setShop] = useState(null);

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  useEffect(() => {
    const fetchAllData = async () => {
      try {
        const data = await api.get(`/orders/${id}`);
        setOrder(data);

        if (data && data.shopId) {
          const shopData = await api.get(`/shops/${data.shopId}`);
          setShop(shopData);
        }
      } catch (err) {
        console.error('Failed to load invoice details:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchAllData();
  }, [id]);

  if (loading) {
    return <div className="w-full py-12 text-center text-sm text-text-muted">{t('syncing')}</div>;
  }

  if (!order) {
    return (
      <Card className="flex flex-col items-center justify-center py-12 text-center gap-4">
        <h4 className="text-sm font-bold text-text-main">{t('invoiceNotFound')}</h4>
        <button onClick={() => navigate('/orders')} className="btn-tactile cursor-pointer">
          <span className="text-white-forced">{t('backToInvoices')}</span>
        </button>
      </Card>
    );
  }

  // Calculations
  const liningTotal = order.needsAster ? (order.asterQuantity * order.asterSellingPrice) : 0;
  const subtotal = order.price;
  const billTotal = order.price + liningTotal;
  const paidAmount = order.payment?.paidAmount || 0;
  const balanceDue = Math.max(0, billTotal - paidAmount);

  let billingStatus = 'Unpaid';
  if (paidAmount > 0) {
    billingStatus = balanceDue === 0 ? 'Paid' : 'Partial';
  }

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'Paid':
        return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
      case 'Partial':
        return 'bg-amber-500/10 text-amber-500 border border-amber-500/20';
      case 'Unpaid':
        return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default:
        return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  // WhatsApp Messaging URLs
  const getWhatsAppNumber = () => {
    const cleanPhone = (order.customer?.phone || '').replace(/\D/g, '');
    return cleanPhone.length === 10 ? '91' + cleanPhone : cleanPhone;
  };

  const getGuestInvoiceUrl = () => {
    return `${window.location.origin}/invoice/share/${order._id}`;
  };

  // Add this helper function inside the InvoiceDetails component
  const formatMessage = (template, data) => {
    let msg = template;
    Object.keys(data).forEach(key => {
      // Replaces {key} with the corresponding value from data object
      msg = msg.replace(new RegExp(`{${key}}`, 'g'), data[key]);
    });
    return msg;
  };

  const handleShareInvoice = () => {
    const phone = getWhatsAppNumber();
    const guestUrl = getGuestInvoiceUrl();
    const invoiceId = `INV-${order.orderId}`;

    // 1. Get the raw template string from your translations
    const template = t('whatsappInvoiceMsg');

    // 2. Format the template with the data object
    const message = formatMessage(template, {
      name: order.customerName,
      id: invoiceId,
      shopName: shop?.shopName || 'StitchCraft',
      total: billTotal.toFixed(2),
      paid: paidAmount.toFixed(2),
      balance: balanceDue.toFixed(2),
      url: guestUrl
    });

    window.open(`https://wa.me/${phone}?text=${encodeURIComponent(message)}`, '_blank');
  };

  const handleSendReminder = () => {
    const phone = getWhatsAppNumber();
    const guestUrl = getGuestInvoiceUrl();
    const invoiceId = `INV-${order.orderId}`;

    // 1. Get the raw template string
    const template = t('whatsappReminderMsg');

    // 2. Format the template
    const message = formatMessage(template, {
      name: order.customerName,
      balance: balanceDue.toFixed(2),
      id: invoiceId,
      shopName: shop?.shopName || 'StitchCraft',
      url: guestUrl
    });

    window.open(`https://wa.me/91${phone}?text=${encodeURIComponent(message)}`, '_blank');
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="flex flex-col gap-6 select-none max-w-4xl mx-auto text-left pb-24">
      <style dangerouslySetInnerHTML={{
        __html: `
        @media print {
          /* Hide sidebar, topbar, buttons, back links, and other non-print elements */
          .print-hidden-element, button, a {
            display: none !important;
          }
          
          /* Reset root layout structural limits to let content flow naturally on paper */
          html, body, #root, #root > div, main {
            height: auto !important;
            min-height: 0 !important;
            overflow: visible !important;
            position: static !important;
            background: white !important;
            color: black !important;
            width: 100% !important;
            margin: 0 !important;
            padding: 0 !important;
          }
          
          /* Style the printable invoice card container specifically for paper output */
          #printable-invoice {
            visibility: visible !important;
            display: flex !important;
            flex-direction: column !important;
            background: white !important;
            color: black !important;
            border: none !important;
            box-shadow: none !important;
            margin: 0 !important;
            padding: 2cm !important;
            width: 100% !important;
            max-width: 100% !important;
            position: static !important;
          }
          
          /* Ensure all text inside invoice displays properly */
          #printable-invoice * {
            visibility: visible !important;
            color: black !important;
          }
        }
      `}} />

      {/* Header controls (hidden on print) */}
      <div className="flex items-center justify-between print-hidden-element">
        <Link to="/invoices" className="flex items-center gap-1.5 text-xs text-text-muted hover:text-text-main font-bold transition-colors">
          <BackIcon className="w-4 h-4" />
          <span>{tf('backToInvoices', 'Back to Invoices')}</span>
        </Link>
        <div className="flex items-center gap-2">
          <button
            onClick={handlePrint}
            className="px-3.5 py-1.5 bg-bg-secondary hover:bg-bg-card-hover text-text-main border border-border-medium hover:border-color-accent-purple/50 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1.5 transition-all"
          >
            <PrintIcon className="w-4 h-4 text-color-accent-purple" />
            <span>{tf('printInvoice', 'Print Invoice')}</span>
          </button>
          <button
            onClick={handleShareInvoice}
            className="px-3.5 py-1.5 bg-emerald-500 hover:bg-emerald-600 text-white-forced font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1.5 transition-all"
          >
            <FaWhatsapp className="w-4 h-4 text-white-forced" />
            <span>{tf('shareInvoice', 'Share Invoice')}</span>
          </button>
          {balanceDue > 0 && (
            <button
              onClick={handleSendReminder}
              className="px-3.5 py-1.5 bg-amber-500 hover:bg-amber-600 text-white-forced font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1.5 transition-all"
            >
              <AlarmIcon className="w-4 h-4 text-white-forced" />
              <span>{tf('sendReminder', 'Send Reminder')}</span>
            </button>
          )}
        </div>
      </div>

      {/* Printable Invoice Container */}
      <Card id="printable-invoice" className="flex flex-col gap-8 p-8 sm:p-12 bg-bg-secondary border border-border-subtle shadow-card rounded-[24px]">
        {/* Invoice Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 border-b border-border-subtle pb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-color-accent-purple flex items-center justify-center text-white-forced shadow-sm">
              <InvoiceIcon className="w-7 h-7 text-white-forced" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-text-main tracking-wider">{t('title')}</h1>
              <p className="text-[10px] font-bold text-text-muted uppercase tracking-widest mt-0.5">{t('erpdescription')}</p>
            </div>
          </div>

          <div className="text-left sm:text-right">
            <h2 className="text-lg font-black text-color-accent-purple tracking-wide">{t('invoiceTitle')}</h2>
            <div className="flex flex-col gap-0.5 mt-1.5 text-xs text-text-muted font-bold">
              <span>{t('invoiceid')}: <strong className="text-text-main font-black">{`INV-${order.orderId}`}</strong></span>
              <span>{t('orderRef')}: <strong className="text-text-main">{order.orderId}</strong></span>
              <span>{t('billingDate')}: <strong>{formatDate(order.date)}</strong></span>
              <span>{t('dueDate')}: <strong>{formatDate(order.deliveryDate)}</strong></span>
            </div>
          </div>
        </div>

        {/* Customer & Merchant Profiles */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 border-b border-border-subtle pb-6 text-xs text-text-muted">
          <div className="flex flex-col gap-2">
            <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">{t('billedTo')}</span>
            <div className="flex flex-col gap-1 text-sm font-semibold text-text-main">
              <span className="font-extrabold text-base text-color-accent-purple">{order.customerName}</span>
              <span>{t('phone')}: {order.customer?.phone || 'No phone recorded'}</span>
              {order.customer?.address && <span className="opacity-80 font-normal leading-relaxed">{order.customer.address}</span>}
            </div>
          </div>

          <div className="flex flex-col gap-2 sm:items-end sm:text-right">
            <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">{t('merchantDetails')}</span>
            <div className="flex flex-col gap-1 text-sm font-semibold text-text-main">
              <span className="font-extrabold text-base text-text-main">{shop.shopName}</span>
              <span>{t('address')}: {shop.address}</span>
              <span>{t('phone')}: {shop.phone}</span>
              <span className="opacity-80">{t('email')}: {shop.email}</span>
            </div>
          </div>
        </div>

        {/* Line Items Table */}
        <div className="flex flex-col gap-3">
          <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">{t('invoiceLineItems')}</span>
          <div className="overflow-hidden border border-border-subtle rounded-xl bg-bg-primary/20">
            <table className="w-full border-collapse text-left text-xs">
              <thead>
                <tr className="bg-bg-secondary border-b border-border-subtle text-[10px] font-extrabold text-text-muted uppercase tracking-wider">
                  <th className="px-4 py-3">{t('itemDesc')}</th>
                  <th className="px-4 py-3 text-center">{t('quantity')}</th>
                  <th className="px-4 py-3 text-right">{t('unitPrice')}</th>
                  <th className="px-4 py-3 text-right">{t('amount')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-subtle font-semibold text-text-main">
                {/* Stitching Service Item */}
                <tr>
                  <td className="px-4 py-4.5">
                    <span className="font-bold block text-sm">{order.apparelType} {t('stitchingService')}</span>
                    <span className="text-[10px] text-text-muted font-normal mt-0.5 block">{t('stitchingServiceDesc')}</span>
                  </td>
                  <td className="px-4 py-4.5 text-center">1</td>
                  <td className="px-4 py-4.5 text-right">{formatCurrency(order.price)}</td>
                  <td className="px-4 py-4.5 text-right font-bold">{formatCurrency(order.price)}</td>
                </tr>

                {/* Lining Material Item (if needsAster is true) */}
                {order.needsAster && (
                  <tr>
                    <td className="px-4 py-4.5">
                      <span className="font-bold block text-sm">{t('liningMaterial')}: {order.asterInventoryItem?.itemName || 'Lining Material'}</span>
                      <span className="text-[10px] text-text-muted font-normal mt-0.5 block">{t('liningMaterialDesc')}</span>
                    </td>
                    <td className="px-4 py-4.5 text-center">{order.asterQuantity} {order.asterInventoryItem?.unit || 'meters'}</td>
                    <td className="px-4 py-4.5 text-right">{formatCurrency(order.asterSellingPrice)}</td>
                    <td className="px-4 py-4.5 text-right font-bold">{formatCurrency(liningTotal)}</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Financial Summary */}
        <div className="flex flex-col sm:flex-row justify-between items-start gap-6 pt-4">
          <div className="flex flex-col gap-2">
            <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">{t('invoiceStatus')}</span>
            <div className="flex items-center gap-2">
              <span className={`px-3 py-1 rounded-lg text-xs font-black uppercase tracking-wider ${getStatusBadgeClass(billingStatus)}`}>
                {tf(billingStatus.toLowerCase(), billingStatus)}
              </span>
              {billingStatus === 'Paid' && <CheckIcon className="w-5 h-5 text-emerald-500" />}
            </div>
            <p className="text-[10px] text-text-muted max-w-xs mt-1 leading-relaxed">{t('invoiceDes')}</p>
          </div>

          <div className="w-full sm:w-[280px] flex flex-col gap-3 text-xs text-text-muted">
            <div className="flex justify-between font-bold">
              <span>{t('subtotal')}</span>
              <span className="text-text-main font-semibold">{formatCurrency(billTotal)}</span>
            </div>
            <div className="flex justify-between font-bold">
              <span>{t('salesTax')} (0%)</span>
              <span className="text-text-main font-semibold">{formatCurrency(0)}</span>
            </div>
            <div className="flex justify-between border-t border-border-subtle pt-2.5 font-bold">
              <span>{t('totalBill')}</span>
              <span className="text-text-main font-semibold">{formatCurrency(billTotal)}</span>
            </div>
            <div className="flex justify-between font-bold">
              <span>{t('totalPaid')}</span>
              <span className="text-emerald-500 font-bold">{formatCurrency(paidAmount)}</span>
            </div>
            <div className="flex justify-between border-t border-border-strong border-double pt-2.5 text-sm font-black">
              <span className="text-text-main uppercase tracking-wider">{t('balanceDue')}</span>
              <span className="text-rose-500">{formatCurrency(balanceDue)}</span>
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
};

export default InvoiceDetails;
