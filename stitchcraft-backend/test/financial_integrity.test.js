import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('P0-03 & P1-05: Financial Integrity, Idempotency, and Delivery Credit', () => {
  it('should enforce payment idempotency and prevent duplicate transaction creation', () => {
    const transactions = [];
    const simulateRecordPayment = ({ shopId, orderId, amount, paymentType, idempotencyKey }) => {
      if (idempotencyKey) {
        const existing = transactions.find(t => t.shopId === shopId && t.idempotencyKey === idempotencyKey);
        if (existing) {
          return { transaction: existing, deduplicated: true };
        }
      }
      const newTx = {
        _id: `tx-${transactions.length + 1}`,
        shopId,
        orderId,
        amount: Number(amount),
        paymentType,
        type: 'Payment',
        idempotencyKey: idempotencyKey || null,
        date: new Date().toISOString(),
      };
      transactions.push(newTx);
      return { transaction: newTx, deduplicated: false };
    };

    const idemKey = 'uuid-payment-mut-001';
    const firstCall = simulateRecordPayment({
      shopId: 'shop-101',
      orderId: 'order-1',
      amount: 500,
      paymentType: 'UPI',
      idempotencyKey: idemKey,
    });
    assert.equal(firstCall.deduplicated, false);
    assert.equal(transactions.length, 1);
    assert.equal(transactions[0].amount, 500);

    // Replay with identical idempotencyKey
    const replayCall = simulateRecordPayment({
      shopId: 'shop-101',
      orderId: 'order-1',
      amount: 500,
      paymentType: 'UPI',
      idempotencyKey: idemKey,
    });
    assert.equal(replayCall.deduplicated, true);
    assert.equal(transactions.length, 1); // Exactly one transaction created
  });

  it('should record immutable refund transactions without mutating original payment records', () => {
    const transactions = [
      {
        _id: 'tx-1',
        shopId: 'shop-101',
        orderId: 'order-1',
        amount: 2000,
        paymentType: 'Cash',
        type: 'Payment',
        date: '2026-11-01T10:00:00.000Z',
      },
    ];

    const simulateRefund = ({ shopId, orderId, amount, reason, processedBy }) => {
      const totalPaid = transactions
        .filter(t => t.orderId === orderId && t.shopId === shopId)
        .reduce((sum, t) => t.type === 'Payment' ? sum + t.amount : (t.type === 'Refund' ? sum - t.amount : sum), 0);

      if (!reason || !reason.trim()) {
        throw new Error('A reason is required to record a refund or reversal');
      }
      if (amount <= 0) {
        throw new Error('Please provide a positive refund amount');
      }
      if (amount > totalPaid) {
        throw new Error('Refund amount exceeds total paid amount');
      }

      const refundTx = {
        _id: `tx-refund-${transactions.length + 1}`,
        shopId,
        orderId,
        amount: Number(amount),
        type: 'Refund',
        reason: reason.trim(),
        processedBy,
        date: new Date().toISOString(),
      };
      transactions.push(refundTx);
      return refundTx;
    };

    // Original payment record before refund
    const originalPaymentAmount = transactions[0].amount;

    const refund = simulateRefund({
      shopId: 'shop-101',
      orderId: 'order-1',
      amount: 500,
      reason: 'Customer altered neckline design, lining cost waived',
      processedBy: 'Ramesh Masterji',
    });

    // Verify refund entry
    assert.equal(refund.type, 'Refund');
    assert.equal(refund.amount, 500);
    assert.equal(refund.reason, 'Customer altered neckline design, lining cost waived');
    assert.equal(refund.processedBy, 'Ramesh Masterji');

    // Verify original payment transaction was NEVER mutated
    assert.equal(transactions[0].amount, originalPaymentAmount);
    assert.equal(transactions[0].type, 'Payment');

    // Verify net paid calculation
    const netPaid = transactions.reduce((sum, t) => t.type === 'Payment' ? sum + t.amount : sum - t.amount, 0);
    assert.equal(netPaid, 1500);

    // Verify refund exceeding net balance is rejected
    assert.throws(() => {
      simulateRefund({
        shopId: 'shop-101',
        orderId: 'order-1',
        amount: 2000, // exceeds remaining 1500
        reason: 'Over-refund attempt',
        processedBy: 'Ramesh Masterji',
      });
    }, /exceeds total paid amount/);

    // Verify refund without reason is rejected
    assert.throws(() => {
      simulateRefund({
        shopId: 'shop-101',
        orderId: 'order-1',
        amount: 100,
        reason: '   ',
        processedBy: 'Ramesh Masterji',
      });
    }, /A reason is required/);
  });

  it('should enforce explicit credit confirmation, reason, and prevent duplicate delivery', () => {
    const delivery = {
      _id: 'del-1',
      orderId: 'ord-101',
      shopId: 'shop-1',
      status: 'Pending',
    };

    const payment = {
      orderId: 'ord-101',
      totalAmount: 2500,
      paidAmount: 1500,
      balanceAmount: 1000,
    };

    const processDelivery = (delDoc, payDoc, body, user) => {
      if (delDoc.status === 'Delivered') {
        throw new Error('Order has already been marked as delivered');
      }

      if (payDoc && payDoc.balanceAmount > 0) {
        if (!body.allowCredit) {
          return {
            requiresCreditApproval: true,
            balanceAmount: payDoc.balanceAmount,
          };
        }
        const reason = (body.creditReason || body.reason || '').trim();
        if (!reason) {
          throw new Error('A reason is required to approve delivery on credit (udhar).');
        }
        delDoc.allowCredit = true;
        delDoc.creditReason = reason;
        delDoc.creditApprovedBy = user.name || 'Owner';
        delDoc.creditApprovedAt = new Date().toISOString();
      }

      delDoc.status = 'Delivered';
      delDoc.deliveredBy = user.name || 'Owner';
      delDoc.deliveredAt = new Date().toISOString();
      return delDoc;
    };

    // Unpaid balance without allowCredit flags credit approval
    const unconfirmed = processDelivery(delivery, payment, { allowCredit: false }, { name: 'Owner' });
    assert.equal(unconfirmed.requiresCreditApproval, true);
    assert.equal(unconfirmed.balanceAmount, 1000);
    assert.equal(delivery.status, 'Pending');

    // allowCredit without reason throws error
    assert.throws(() => {
      processDelivery(delivery, payment, { allowCredit: true, creditReason: '' }, { name: 'Owner' });
    }, /A reason is required to approve delivery on credit/);

    // allowCredit with valid reason approves delivery on credit
    const confirmed = processDelivery(
      delivery,
      payment,
      { allowCredit: true, creditReason: 'Customer regular, promised payment on Saturday' },
      { name: 'Masterji Ramesh' }
    );
    assert.equal(confirmed.status, 'Delivered');
    assert.equal(confirmed.allowCredit, true);
    assert.equal(confirmed.creditReason, 'Customer regular, promised payment on Saturday');
    assert.equal(confirmed.creditApprovedBy, 'Masterji Ramesh');

    // Attempting delivery again rejects duplicate delivery
    assert.throws(() => {
      processDelivery(delivery, payment, { allowCredit: true, creditReason: 'Retry' }, { name: 'Owner' });
    }, /already been marked as delivered/);
  });
});

