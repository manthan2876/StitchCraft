import mongoose from 'mongoose';

const actionLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    action: {
      type: String,
      required: true,
      enum: ['LOGIN', 'LOGOUT', 'UPDATE_PROFILE', 'IMPORT_DATA', 'DOWNLOAD_DATA', 'DELETE_ALL_DATA', 'DELETE_ACCOUNT_REQUEST', 'REACTIVATE_ACCOUNT'],
    },
    details: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model('ActionLog', actionLogSchema);
