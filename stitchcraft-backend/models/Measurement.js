import mongoose from 'mongoose';

const shirtMeasurementSchema = new mongoose.Schema({
  neck: { type: Number, default: 0 },
  chest: { type: Number, default: 0 },
  waist: { type: Number, default: 0 },
  hips: { type: Number, default: 0 },
  shoulder: { type: Number, default: 0 },
  sleeves: { type: Number, default: 0 },
  length: { type: Number, default: 0 },
  frontNeck: { type: Number, default: 0 },
  backNeck: { type: Number, default: 0 },
  notes: { type: String, default: '' },
}, { _id: false });

const pantMeasurementSchema = new mongoose.Schema({
  length: { type: Number, default: 0 },
  waist: { type: Number, default: 0 },
  hips: { type: Number, default: 0 },
  inseam: { type: Number, default: 0 },
  thigh: { type: Number, default: 0 },
  rise: { type: Number, default: 0 },
  bottom: { type: Number, default: 0 },
  notes: { type: String, default: '' },
}, { _id: false });

const measurementSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      required: true,
      unique: true,
    },
    shirt: {
      type: shirtMeasurementSchema,
      default: () => ({}),
    },
    pant: {
      type: pantMeasurementSchema,
      default: () => ({}),
    },
    others: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model('Measurement', measurementSchema);
