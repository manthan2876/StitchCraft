/* src/pages/PublicInvoice.jsx */
import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { useLanguage } from '../context/LanguageContext';
import { formatCurrency, formatDate } from '../utils/formatters';
import {
  MdPrint as PrintIcon,
  MdCheckCircle as CheckIcon,
  MdReceipt as InvoiceIcon,
} from 'react-icons/md';

export const PublicInvoice = () => {
  const { id } = useParams();
  const { t } = useLanguage();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  useEffect(() => {
    const fetchPublicInvoice = async () => {
      try {
        // Fetch from unauthenticated public guest endpoint
        const data = await api.get(`/orders/public/${id}`);
        setOrder(data);
      } catch (err) {
        console.error('Failed to load guest invoice details:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchPublicInvoice();
  }, [id]);

  if (loading) {
    return (
      <div className="w-screen h-screen flex flex-col items-center justify-center bg-bg-primary gap-4 text-xs font-semibold text-text-muted">
        <div className="w-10 h-10 rounded-full border-4 border-color-accent-purple border-t-transparent animate-spin"></div>
        <span>Syncing invoice receipt...</span>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="w-screen h-screen flex items-center justify-center bg-bg-primary p-4">
        <Card className="flex flex-col items-center justify-center py-12 text-center gap-4 max-w-sm w-full">
          <InvoiceIcon className="w-12 h-12 text-text-muted opacity-50" />
          <h4 className="text-base font-bold text-text-main">{tf('invoiceNotFound', 'Invoice Not Found')}</h4>
          <p className="text-xs text-text-muted font-medium">This shared link may have expired or the invoice record does not exist.</p>
        </Card>
      </div>
    );
  }

  // Calculations
  const liningTotal = order.needsAster ? (order.asterQuantity * order.asterSellingPrice) : 0;
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

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="w-screen min-h-screen bg-bg-primary p-4 sm:p-8 select-none text-left">
      <style dangerouslySetInnerHTML={{ __html: `
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

      <div className="max-w-4xl mx-auto flex flex-col gap-6">
        {/* Print controls (hidden on print) */}
        <div className="flex justify-end print-hidden-element">
          <button
            onClick={handlePrint}
            className="px-4 py-2 bg-bg-secondary hover:bg-bg-card-hover text-text-main border border-border-medium hover:border-color-accent-purple/50 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1.5 transition-all"
          >
            <PrintIcon className="w-4 h-4 text-color-accent-purple" />
            <span>{tf('printInvoice', 'Print / Save Invoice')}</span>
          </button>
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
                <h1 className="text-2xl font-black text-text-main tracking-wider">StitchCraft</h1>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-widest mt-0.5">Premium Tailoring ERP</p>
              </div>
            </div>

            <div className="text-left sm:text-right">
              <h2 className="text-lg font-black text-color-accent-purple tracking-wide">INVOICE</h2>
              <div className="flex flex-col gap-0.5 mt-1.5 text-xs text-text-muted font-bold">
                <span>Invoice ID: <strong className="text-text-main font-black">{`INV-${order.orderId}`}</strong></span>
                <span>Order Ref: <strong className="text-text-main">{order.orderId}</strong></span>
                <span>Billing Date: <strong>{formatDate(order.date)}</strong></span>
                <span>Due Date: <strong>{formatDate(order.deliveryDate)}</strong></span>
              </div>
            </div>
          </div>

          {/* Customer & Merchant Profiles */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 border-b border-border-subtle pb-6 text-xs text-text-muted">
            <div className="flex flex-col gap-2">
              <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">Billed To</span>
              <div className="flex flex-col gap-1 text-sm font-semibold text-text-main">
                <span className="font-extrabold text-base text-color-accent-purple">{order.customerName}</span>
                <span>Phone: {order.customer?.phone || 'No phone recorded'}</span>
                {order.customer?.address && <span className="opacity-80 font-normal leading-relaxed">{order.customer.address}</span>}
              </div>
            </div>

            <div className="flex flex-col gap-2 sm:items-end sm:text-right">
              <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">Merchant Details</span>
              <div className="flex flex-col gap-1 text-sm font-semibold text-text-main">
                <span className="font-extrabold text-base text-text-main">StitchCraft Tailors</span>
                <span>102 Main Street, Central Plaza</span>
                <span>Phone: +91 98765 43210</span>
                <span className="opacity-80">support@stitchcraft.com</span>
              </div>
            </div>
          </div>

          {/* Line Items Table */}
          <div className="flex flex-col gap-3">
            <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">Invoice Line Items</span>
            <div className="overflow-hidden border border-border-subtle rounded-xl bg-bg-primary/20">
              <table className="w-full border-collapse text-left text-xs">
                <thead>
                  <tr className="bg-bg-secondary border-b border-border-subtle text-[10px] font-extrabold text-text-muted uppercase tracking-wider">
                    <th className="px-4 py-3">Item Description</th>
                    <th className="px-4 py-3 text-center">Quantity</th>
                    <th className="px-4 py-3 text-right">Unit Price</th>
                    <th className="px-4 py-3 text-right">Amount</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-subtle font-semibold text-text-main">
                  {/* Stitching Service Item */}
                  <tr>
                    <td className="px-4 py-4.5">
                      <span className="font-bold block text-sm">{order.apparelType} Stitching Service</span>
                      <span className="text-[10px] text-text-muted font-normal mt-0.5 block">Custom tailoring stitching service package</span>
                    </td>
                    <td className="px-4 py-4.5 text-center">1</td>
                    <td className="px-4 py-4.5 text-right">{formatCurrency(order.price)}</td>
                    <td className="px-4 py-4.5 text-right font-bold">{formatCurrency(order.price)}</td>
                  </tr>

                  {/* Lining Material Item (if needsAster is true) */}
                  {order.needsAster && (
                    <tr>
                      <td className="px-4 py-4.5">
                        <span className="font-bold block text-sm">Lining / Astar Material: {order.asterInventoryItem?.itemName || 'Lining Material'}</span>
                        <span className="text-[10px] text-text-muted font-normal mt-0.5 block">Material used for inner garment lining support</span>
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
              <span className="text-[9px] font-extrabold uppercase tracking-widest text-text-muted/60">Invoice Status</span>
              <div className="flex items-center gap-2">
                <span className={`px-3 py-1 rounded-lg text-xs font-black uppercase tracking-wider ${getStatusBadgeClass(billingStatus)}`}>
                  {billingStatus}
                </span>
                {billingStatus === 'Paid' && <CheckIcon className="w-5 h-5 text-emerald-500" />}
              </div>
              <p className="text-[10px] text-text-muted max-w-xs mt-1 leading-relaxed">
                This is a secure electronic copy of your tailoring invoice at StitchCraft. Thank you for your custom business.
              </p>
            </div>

            <div className="w-full sm:w-[280px] flex flex-col gap-3 text-xs text-text-muted">
              <div className="flex justify-between font-bold">
                <span>Subtotal</span>
                <span className="text-text-main font-semibold">{formatCurrency(billTotal)}</span>
              </div>
              <div className="flex justify-between font-bold">
                <span>Sales Tax (0%)</span>
                <span className="text-text-main font-semibold">{formatCurrency(0)}</span>
              </div>
              <div className="flex justify-between border-t border-border-subtle pt-2.5 font-bold">
                <span>Total Bill</span>
                <span className="text-text-main font-semibold">{formatCurrency(billTotal)}</span>
              </div>
              <div className="flex justify-between font-bold">
                <span>Total Paid</span>
                <span className="text-emerald-500 font-bold">{formatCurrency(paidAmount)}</span>
              </div>
              <div className="flex justify-between border-t border-border-strong border-double pt-2.5 text-sm font-black">
                <span className="text-text-main uppercase tracking-wider">Balance Due</span>
                <span className="text-rose-500">{formatCurrency(balanceDue)}</span>
              </div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default PublicInvoice;
