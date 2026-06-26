import mongoose from 'mongoose';

const ledgerEntrySchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: [0, 'Amount cannot be negative'],
    },
    category: {
      type: String,
      enum: ['Inventory', 'Salary', 'Rent', 'Other'],
      required: true,
    },
    description: {
      type: String,
      default: '',
    },
    date: {
      type: Date,
      default: Date.now,
    },
    referenceId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index to optimize queries filter by shop and date/category
ledgerEntrySchema.index({ shopId: 1, category: 1 });
ledgerEntrySchema.index({ shopId: 1, date: -1 });

export default mongoose.model('LedgerEntry', ledgerEntrySchema);
