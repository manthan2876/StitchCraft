import { createClient } from '@supabase/supabase-js';
import crypto from 'node:crypto';
import path from 'node:path';
import 'dotenv/config';

const isTest = process.env.NODE_ENV === 'test' ||
  process.env.npm_lifecycle_event === 'test' ||
  process.argv.some(arg => arg.includes('test'));

const supabaseUrl = process.env.SUPABASE_URL || (isTest ? 'https://placeholder.supabase.co' : 'https://placeholder.supabase.co');
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || (isTest ? 'placeholder-key-for-test-suite' : 'placeholder-key');

const supabaseAdmin = createClient(
  supabaseUrl,
  supabaseKey
);

export const ALLOWED_BUCKETS = new Set(
  (process.env.UPLOAD_BUCKETS || 'profile-images,maap-images')
    .split(',')
    .map((bucket) => bucket.trim())
    .filter(Boolean),
);

export const ALLOWED_MIME_TYPES = new Map([
  ['image/jpeg', '.jpg'],
  ['image/jpg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
  ['image/heic', '.heic'],
  ['application/pdf', '.pdf'],
]);

export const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB (Phase 4, 8.3)

/**
 * Validate MIME type and map to trusted file extension
 */
export const validateMimeType = (mimeType) => {
  if (!mimeType || typeof mimeType !== 'string') return null;
  const cleanMime = mimeType.trim().toLowerCase();
  return ALLOWED_MIME_TYPES.get(cleanMime) || null;
};

/**
 * Generate randomized tenant-isolated storage path
 */
export const getOwnedPath = (shopId, fileName, mimeType, entityType) => {
  if (typeof shopId !== 'string' || !shopId.trim()) return null;

  // Determine trusted file extension
  let ext = validateMimeType(mimeType);
  if (!ext && fileName && typeof fileName === 'string') {
    const rawExt = path.extname(fileName).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.webp', '.heic', '.pdf'].includes(rawExt)) {
      ext = rawExt === '.jpeg' ? '.jpg' : rawExt;
    }
  }

  if (!ext) return null;

  // Generate randomized UUID filename (Phase 4, 8.3)
  const randomFileName = `${crypto.randomUUID()}${ext}`;
  const validFolder = entityType && ['customers', 'orders', 'fabrics', 'measurements', 'profiles'].includes(entityType)
    ? entityType
    : 'media';

  return {
    storagePath: `${shopId}/${validFolder}/${randomFileName}`,
    fileName: randomFileName,
  };
};

// @desc    Get a signed upload URL with MIME and size verification (Phase 4, 8.3)
// @route   POST /api/upload/get-upload-url
export const getUploadUrl = async (req, res) => {
  try {
    const { bucketName, fileName, mimeType, fileSize, entityType } = req.body;
    const shopId = req.user?.shopId?.toString();

    if (!shopId) {
      return res.status(401).json({ message: 'No active shop associated with session' });
    }

    if (typeof bucketName !== 'string' || !ALLOWED_BUCKETS.has(bucketName)) {
      return res.status(400).json({ message: 'Invalid upload destination bucket' });
    }

    // Validate file size server-side
    if (fileSize !== undefined) {
      const numSize = Number(fileSize);
      if (isNaN(numSize) || numSize <= 0) {
        return res.status(400).json({ message: 'Invalid file size provided' });
      }
      if (numSize > MAX_FILE_SIZE_BYTES) {
        return res.status(400).json({
          message: `File size exceeds the 10MB limit (provided: ${(numSize / (1024 * 1024)).toFixed(2)}MB)`,
        });
      }
    }

    // Validate MIME type server-side
    if (mimeType && !validateMimeType(mimeType)) {
      return res.status(400).json({
        message: 'Invalid MIME type. Allowed formats: JPEG, PNG, WebP, HEIC, and PDF.',
      });
    }

    const pathData = getOwnedPath(shopId, fileName, mimeType, entityType);
    if (!pathData) {
      return res.status(400).json({
        message: 'Invalid upload destination or unsupported file extension',
      });
    }

    const { data, error } = await supabaseAdmin.storage
      .from(bucketName)
      .createSignedUploadUrl(pathData.storagePath);

    if (error) throw error;

    res.json({
      ...data,
      path: pathData.storagePath,
      fileName: pathData.fileName,
      storagePath: pathData.storagePath,
    });
  } catch (err) {
    console.error('Get upload URL error:', err);
    res.status(500).json({ message: err.message });
  }
};

// @desc    Get a short-lived signed view URL for private media (Phase 4, 8.3)
// @route   GET /api/upload/view-url
export const getViewUrl = async (req, res) => {
  try {
    const bucket = req.params.bucket || req.query.bucket;
    const encodedPath = req.params.path || req.query.path;
    const shopId = req.user?.shopId?.toString();

    if (!shopId) {
      return res.status(401).json({ message: 'No active shop associated with session' });
    }

    if (!bucket || !ALLOWED_BUCKETS.has(bucket)) {
      return res.status(400).json({ message: 'Invalid or unauthorized bucket' });
    }

    let filePath;
    try {
      filePath = decodeURIComponent(encodedPath || '');
    } catch {
      return res.status(400).json({ message: 'Invalid file path' });
    }

    if (!filePath || filePath.length > 512 || filePath.includes('..')) {
      return res.status(400).json({ message: 'Invalid file path' });
    }

    // Strict tenant boundary enforcement: cannot view media from other shops (P0/Phase 4)
    const ownerPrefix = `${shopId}/`;
    if (!filePath.startsWith(ownerPrefix)) {
      return res.status(403).json({
        message: 'Forbidden: cross-tenant access to media files is strictly prohibited',
      });
    }

    // Short-lived signed URL (15 minutes = 900 seconds)
    const { data, error } = await supabaseAdmin.storage
      .from(bucket)
      .createSignedUrl(filePath, 900);

    if (error) throw error;
    res.json({ signedUrl: data.signedUrl, expiresIn: 900 });
  } catch (err) {
    console.error('Get view URL error:', err);
    res.status(500).json({ message: err.message });
  }
};

// @desc    Delete a media file (owner / manager only)
// @route   DELETE /api/upload/file
export const deleteMediaFile = async (req, res) => {
  try {
    const { bucket, path: filePath } = req.body;
    const shopId = req.user?.shopId?.toString();

    if (!shopId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (req.user?.role !== 'owner' && req.user?.role !== 'manager') {
      return res.status(403).json({ message: 'Forbidden: only owners and managers can delete media' });
    }

    const ownerPrefix = `${shopId}/`;
    if (!filePath || !filePath.startsWith(ownerPrefix)) {
      return res.status(403).json({ message: 'Forbidden: cannot delete files belonging to other shops' });
    }

    const { error } = await supabaseAdmin.storage
      .from(bucket || 'profile-images')
      .remove([filePath]);

    if (error) throw error;
    res.json({ message: 'Media file deleted successfully' });
  } catch (err) {
    console.error('Delete media error:', err);
    res.status(500).json({ message: err.message });
  }
};

export default {
  getUploadUrl,
  getViewUrl,
  deleteMediaFile,
  validateMimeType,
  getOwnedPath,
  ALLOWED_BUCKETS,
  ALLOWED_MIME_TYPES,
  MAX_FILE_SIZE_BYTES,
};
