import mongoose from 'mongoose';
import Counter from './Counter.js';

const customerSchema = new mongoose.Schema(
  {
    customerId: {
      type: String,
      unique: true,
    },
    name: {
      type: String,
      required: [true, 'Please add customer name'],
    },
    phone: {
      type: String,
      required: [true, 'Please add phone number'],
    },
    email: {
      type: String,
      default: '',
    },
    address: {
      type: String,
      default: '',
    },
    ordersCount: {
      type: Number,
      default: 0,
    },
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

customerSchema.index({ shopId: 1, customerId: 1 });

// Auto-increment customerId pre-save hook
customerSchema.pre('save', async function () {
  if (this.isNew) {
    const counter = await Counter.findOneAndUpdate(
      { id: 'customerId' },
      { $inc: { seq: 1 } },
      { returnDocument: 'after', upsert: true }
    );
    this.customerId = `CUST-${String(counter.seq).padStart(3, '0')}`;
  }
});

// Transform returned payload
customerSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret.customerId;
    return ret;
  },
});

export default mongoose.model('Customer', customerSchema);
