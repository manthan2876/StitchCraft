import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const supabaseAdmin = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

// @desc    Get a signed upload URL for a private bucket
// @route   POST /api/upload/get-upload-url
export const getUploadUrl = async (req, res) => {
    const { bucketName, fileName } = req.body;

    try {
        const { data, error } = await supabaseAdmin.storage
            .from(bucketName)
            .createSignedUploadUrl(fileName);

        if (error) throw error;
        res.json(data);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

export const getViewUrl = async (req, res) => {
    const { bucket } = req.params;
    const rawPath = decodeURIComponent(req.params.path);

    // LOGIC: Extract filename if a full URL is passed
    // If it starts with http, take the part after the last slash, 
    // removing any query params (?token=...)
    const fileName = rawPath.startsWith('http')
        ? rawPath.split('/').pop().split('?')[0]
        : rawPath;

    console.log("Fetching signed URL for:", bucket, "File:", fileName);

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

// Add this temporary debug route to uploadController.js
export const listBucketFiles = async (req, res) => {
    const { bucket } = req.params;
    try {
        const { data, error } = await supabaseAdmin.storage
            .from(bucket)
            .list(); // Lists the top-level files

        if (error) throw error;
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};