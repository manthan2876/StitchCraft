import mongoose from 'mongoose';

const transactionSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: [0, 'Amount cannot be negative'],
    },
    paymentType: {
      type: String,
      enum: ['Cash', 'UPI', 'Card', 'Online'],
      default: 'Cash',
    },
    type: {
      type: String,
      enum: ['Payment', 'Refund'],
      default: 'Payment',
    },
    date: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index to optimize order-based and shop-based queries
transactionSchema.index({ shopId: 1, orderId: 1 });

export default mongoose.model('Transaction', transactionSchema);
