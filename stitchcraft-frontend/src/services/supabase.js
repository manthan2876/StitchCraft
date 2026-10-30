import { createClient } from '@supabase/supabase-js';
import { api } from './api.js';

const supabase = createClient(
    import.meta.env.VITE_SUPABASE_URL,
    import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const uploadToPrivateBucket = async (bucket, file) => {
    const fileName = `${crypto.randomUUID()}-${file.name}`;

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
        const token = localStorage.getItem('stitchcraft_token');
        if (!token) {
            return null;
        }

        const encodedPath = encodeURIComponent(path);

        const response = await api.get(`/upload/view-url/${bucket}/${encodedPath}`);
        return response.signedUrl;
    } catch (err) {
        console.error('Error fetching signed URL:', err);
        return null;
    }
};

export default supabase;