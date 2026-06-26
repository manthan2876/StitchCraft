import mongoose from 'mongoose';

const machineSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    name: {
      type: String,
      required: [true, 'Please add machine name/number'],
      trim: true,
    },
    type: {
      type: String,
      required: [true, 'Please add machine type (e.g. Sewing, Overlock, Embroidery)'],
      trim: true,
    },
    status: {
      type: String,
      enum: ['Working', 'Maintenance', 'Broken'],
      default: 'Working',
    },
    notes: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model('Machine', machineSchema);
