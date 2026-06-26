import { createClient } from '@supabase/supabase-js';
// ADD THIS IMPORT LINE:
import { api } from './api';

const supabase = createClient(
    import.meta.env.VITE_SUPABASE_URL,
    import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const uploadToPrivateBucket = async (bucket, file) => {
    const fileName = `${Date.now()}-${file.name}`;

    // Now 'api' will be recognized
    const { signedUrl, path } = await api.post('/upload/get-upload-url', {
        bucketName: bucket,
        fileName
    });

    const response = await fetch(signedUrl, {
        method: 'PUT',
        body: file,
        headers: { 'Content-Type': file.type }
    });

    if (!response.ok) throw new Error('Failed to upload file to storage');

    return path;
};

export const getSignedUrl = async (bucket, path) => {
    try {
        // 1. Check if token exists before making the call
        const token = localStorage.getItem('stitchcraft_token');
        if (!token) {
            console.error("No auth token found in localStorage");
            return null;
        }

        // 2. Encode path to handle special characters correctly
        const encodedPath = encodeURIComponent(path);

        // 3. Make request
        const response = await api.get(`/upload/view-url/${bucket}/${encodedPath}`);
        return response.signedUrl;
    } catch (err) {
        console.error("Error fetching signed URL:", err);
        return null;
    }
};

export default supabase;