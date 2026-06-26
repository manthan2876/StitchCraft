import mongoose from 'mongoose';

const karigarSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    name: {
      type: String,
      required: [true, 'Please add karigar name'],
      trim: true,
    },
    phone: {
      type: String,
      required: [true, 'Please add phone number'],
      trim: true,
    },
    specialization: {
      type: String,
      default: 'General',
      trim: true,
    },
    status: {
      type: String,
      enum: ['Active', 'Inactive'],
      default: 'Active',
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model('Karigar', karigarSchema);
