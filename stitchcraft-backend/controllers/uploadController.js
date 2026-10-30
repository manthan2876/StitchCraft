import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const supabaseAdmin = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

const allowedBuckets = new Set(
    (process.env.UPLOAD_BUCKETS || 'profile-images,maap-images')
        .split(',')
        .map((bucket) => bucket.trim())
        .filter(Boolean),
);

const getOwnedPath = (shopId, fileName) => {
    if (typeof shopId !== 'string' || typeof fileName !== 'string') return null;
    const cleanFileName = fileName.trim();
    if (!cleanFileName || cleanFileName.length > 255 || cleanFileName.includes('/') ||
        cleanFileName.includes('\\') || cleanFileName === '.' || cleanFileName === '..') {
        return null;
    }
    return `${shopId}/${cleanFileName}`;
};

// @desc    Get a signed upload URL for a private bucket
// @route   POST /api/upload/get-upload-url
export const getUploadUrl = async (req, res) => {
    const { bucketName, fileName } = req.body;
    const path = getOwnedPath(req.user.shopId?.toString(), fileName);

    if (!req.user.shopId || typeof bucketName !== 'string' ||
        !allowedBuckets.has(bucketName) || !path) {
        return res.status(400).json({ message: 'Invalid upload destination' });
    }
    try {
        const { data, error } = await supabaseAdmin.storage
            .from(bucketName)
            .createSignedUploadUrl(path);

        if (error) throw error;
        res.json(data);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

export const getViewUrl = async (req, res) => {
    const bucket = req.params.bucket || req.query.bucket;
    const encodedPath = req.params.path || req.query.path;
    let fileName;
    try {
        fileName = decodeURIComponent(encodedPath || '');
    } catch {
        return res.status(400).json({ message: 'Invalid file path' });
    }
    const ownerPrefix = `${req.user.shopId?.toString()}/`;

    if (!req.user.shopId || !allowedBuckets.has(bucket) || !fileName.startsWith(ownerPrefix) ||
        fileName.length > 512 || fileName.includes('..')) {
        return res.status(400).json({ message: 'Invalid file path' });
    }
    try {
        const { data, error } = await supabaseAdmin.storage
            .from(bucket)
            .createSignedUrl(fileName, 3600);

        if (error) throw error;
        res.json({ signedUrl: data.signedUrl });
    } catch (err) {
        console.error("Supabase Error:", err);
        res.status(500).json({ message: err.message });
    }
};
