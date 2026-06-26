import mongoose from 'mongoose';

const inventorySchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    itemName: {
      type: String,
      required: [true, 'Please add item name'],
      trim: true,
    },
    itemType: {
      type: String,
      required: [true, 'Please add item type'],
      trim: true,
    },
    quantity: {
      type: Number,
      required: [true, 'Please add quantity'],
      min: [0, 'Quantity cannot be negative'],
      default: 0,
    },
    unit: {
      type: String,
      required: [true, 'Please add unit'],
      default: 'meters',
    },
    minQuantity: {
      type: Number,
      default: 10,
      min: [0, 'Min quantity cannot be negative'],
    },
    status: {
      type: String,
      enum: ['In Stock', 'Low Stock', 'Out of Stock'],
      default: 'In Stock',
    },
    lastPurchaseAmount: {
      type: Number,
      default: 0,
    },
    costPerUnit: {
      type: Number,
      default: 0,
    },
    purchaseHistory: [
      {
        amount: { type: Number, default: 0 },
        date: { type: Date, default: Date.now },
      },
    ],
  },
  {
    timestamps: true,
  }
);

inventorySchema.index({ shopId: 1, itemName: 1 });

inventorySchema.pre('save', function () {
  if (this.quantity === 0) {
    this.status = 'Out of Stock';
  } else if (this.quantity <= this.minQuantity) {
    this.status = 'Low Stock';
  } else {
    this.status = 'In Stock';
  }
});

export default mongoose.model('Inventory', inventorySchema);
