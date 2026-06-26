import mongoose from 'mongoose';

const shopSchema = new mongoose.Schema(
  {
    shopName: {
      type: String,
      required: [true, 'Please add a shop name'],
      trim: true,
    },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    phone: {
      type: String,
      default: '',
    },
    address: {
      type: String,
      default: '',
    },
    plan: {
      type: String,
      enum: ['Free', 'Basic', 'Premium'],
      default: 'Free',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model('Shop', shopSchema);
