import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { escapeCSV, buildCSV, filterByDateRange } from '../src/utils/csv.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Frontend CSV Escaping & SPA Deployment Hardening (5.1 & 5.4)', () => {
  describe('RFC 4180 CSV Escaping', () => {
    it('should return empty string for null and undefined', () => {
      assert.equal(escapeCSV(null), '');
      assert.equal(escapeCSV(undefined), '');
    });

    it('should leave plain text and numbers unchanged', () => {
      assert.equal(escapeCSV('Sherwani Booking'), 'Sherwani Booking');
      assert.equal(escapeCSV(4500), '4500');
      assert.equal(escapeCSV(0), '0');
    });

    it('should quote values containing commas', () => {
      assert.equal(
        escapeCSV('Payment for Suit, Shirt, and Pant'),
        '"Payment for Suit, Shirt, and Pant"'
      );
    });

    it('should escape double quotes by doubling them inside quoted strings', () => {
      assert.equal(
        escapeCSV('Order "VIP" Royal Blue'),
        '"Order ""VIP"" Royal Blue"'
      );
    });

    it('should quote values containing newlines or carriage returns', () => {
      assert.equal(
        escapeCSV('Line 1\nLine 2'),
        '"Line 1\nLine 2"'
      );
      assert.equal(
        escapeCSV('Line 1\r\nLine 2'),
        '"Line 1\r\nLine 2"'
      );
    });

    it('should preserve regional Unicode characters cleanly', () => {
      const hindi = 'कुर्ता, पजामा और अस्तर';
      assert.equal(escapeCSV(hindi), '"कुर्ता, पजामा और अस्तर"');
    });

    it('should build a multi-row CSV document correctly', () => {
      const headers = ['Date', 'Type', 'Description', 'Amount'];
      const rows = [
        ['10/05/2026', 'Sales', 'Order #101: Silk Kurta, White', 2500],
        ['11/05/2026', 'Payment', 'Received cash with "thank you" note', 1500],
      ];
      const csv = buildCSV(headers, rows);
      const lines = csv.split('\n');

      assert.equal(lines.length, 3);
      assert.equal(lines[0], 'Date,Type,Description,Amount');
      assert.equal(lines[1], '10/05/2026,Sales,"Order #101: Silk Kurta, White",2500');
      assert.equal(lines[2], '11/05/2026,Payment,"Received cash with ""thank you"" note",1500');
    });
  });

  describe('Ledger Date-Range Filtering', () => {
    const entries = [
      { id: '1', date: '2026-05-01T08:00:00.000Z', amount: 1000 },
      { id: '2', date: '2026-05-15T12:00:00.000Z', amount: 2000 },
      { id: '3', date: '2026-05-31T18:00:00.000Z', amount: 3000 },
      { id: '4', date: '2026-06-05T10:00:00.000Z', amount: 4000 },
      { id: '5', date: 'bad-date', amount: 0 },
    ];

    it('should return all entries when no range is provided', () => {
      const filtered = filterByDateRange(entries);
      assert.equal(filtered.length, 5);
    });

    it('should filter entries within start and end date inclusive', () => {
      const filtered = filterByDateRange(entries, 'date', '2026-05-10', '2026-05-31');
      assert.equal(filtered.length, 2);
      assert.deepEqual(filtered.map(e => e.id), ['2', '3']);
    });

    it('should filter entries with only start date', () => {
      const filtered = filterByDateRange(entries, 'date', '2026-06-01', '');
      assert.equal(filtered.length, 1);
      assert.equal(filtered[0].id, '4');
    });

    it('should filter entries with only end date', () => {
      const filtered = filterByDateRange(entries, 'date', '', '2026-05-10');
      assert.equal(filtered.length, 1);
      assert.equal(filtered[0].id, '1');
    });
  });

  describe('Vercel SPA Deployment Rewrites Smoke Test', () => {
    it('should include catch-all rewrites in root vercel.json for SPA routing', () => {
      const rootVercelPath = path.resolve(__dirname, '../../vercel.json');
      assert.ok(fs.existsSync(rootVercelPath), 'root vercel.json must exist');

      const config = JSON.parse(fs.readFileSync(rootVercelPath, 'utf8'));
      assert.ok(Array.isArray(config.rewrites), 'vercel.json must have rewrites array');

      const spaRewrite = config.rewrites.find(
        (r) => (r.source === '/(.*)' || r.source === '/(.*)') && r.destination === '/index.html'
      );
      assert.ok(
        spaRewrite,
        'vercel.json must route all SPA client paths (e.g. /dashboard, /orders, /invoice/share/:token) to /index.html'
      );
    });

    it('should verify stitchcraft-frontend vercel.json also preserves SPA rewrites', () => {
      const frontendVercelPath = path.resolve(__dirname, '../vercel.json');
      assert.ok(fs.existsSync(frontendVercelPath), 'frontend vercel.json must exist');

      const config = JSON.parse(fs.readFileSync(frontendVercelPath, 'utf8'));
      assert.ok(Array.isArray(config.rewrites));
      assert.ok(config.rewrites.some((r) => r.destination === '/index.html'));
    });
  });
});

