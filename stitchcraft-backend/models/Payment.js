import mongoose from 'mongoose';

const paymentSchema = new mongoose.Schema(
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
    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    paidAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    balanceAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    paymentType: {
      type: String,
      enum: ['Cash', 'Online', 'Card'],
      default: 'Cash',
    },
    status: {
      type: String,
      enum: ['Pending', 'Paid', 'Partial'],
      default: 'Pending',
    },
  },
  {
    timestamps: true,
  }
);

// Auto-calculate balance before save
paymentSchema.pre('save', function () {
  this.balanceAmount = this.totalAmount - this.paidAmount;
  if (this.balanceAmount <= 0) {
    this.status = 'Paid';
    this.balanceAmount = 0;
  } else if (this.paidAmount > 0) {
    this.status = 'Partial';
  } else {
    this.status = 'Pending';
  }
});

export default mongoose.model('Payment', paymentSchema);
