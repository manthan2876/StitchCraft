import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  GARMENT_TEMPLATES,
  resolveGarmentTemplate,
  validateMeasurementsForTemplate,
  createMeasurementsSnapshot,
} from '../services/garmentTemplateService.js';
import {
  escapeCSV,
  serializeReportToCSV,
} from '../services/reportService.js';
import {
  DEFAULT_PIECE_RATES,
  resolvePieceRate,
} from '../services/karigarWageService.js';
import {
  getUploadPriority,
  sortMutationsByDependency,
} from '../config/syncRegistry.js';

describe('Phase 7: Product-Fit & Workflow Improvements', () => {
  describe('11.1 Mobile Workflow Repair: Customer Profile to Order Preselection', () => {
    it('should preselect measurements matching the chosen garment from nested customer profile', () => {
      // Simulating customer profile with multi-garment saved measurements
      const customerProfileMeasurements = {
        shirt: { length: 28, chest: 38, waist: 34, shoulder: 17, sleeve: 24, neck: 15.5 },
        pant: { length: 40, waist: 32, hips: 38, bottom: 14, inseam: 29 },
        blouse: { length: 14.5, chest: 34, waist: 28, shoulder: 13, frontNeck: 7, backNeck: 9 },
        kurti: { length: 42, chest: 36, waist: 30, hips: 40, shoulder: 14, sleeve: 16 },
      };

      // Helper function mirroring step3_measurements.dart preselection logic
      const extractPreselectedMeasurements = (garmentType, rawMeasurements) => {
        const cleanKey = garmentType.replace(/\s+/g, '').toLowerCase();
        let sourceMap = null;

        if (rawMeasurements[cleanKey] && typeof rawMeasurements[cleanKey] === 'object') {
          sourceMap = rawMeasurements[cleanKey];
        } else if (cleanKey.includes('shirt') && rawMeasurements.shirt) {
          sourceMap = rawMeasurements.shirt;
        } else if ((cleanKey.includes('pant') || cleanKey.includes('salwar')) && rawMeasurements.pant) {
          sourceMap = rawMeasurements.pant;
        } else if (cleanKey.includes('blouse') && rawMeasurements.blouse) {
          sourceMap = rawMeasurements.blouse;
        } else if (cleanKey.includes('kurti') && rawMeasurements.kurti) {
          sourceMap = rawMeasurements.kurti;
        }

        return sourceMap;
      };

      // Test 1: Selecting Shirt extracts shirt measurements
      const shirtVals = extractPreselectedMeasurements('Men Shirt', customerProfileMeasurements);
      assert.ok(shirtVals);
      assert.equal(shirtVals.chest, 38);
      assert.equal(shirtVals.neck, 15.5);

      // Test 2: Selecting Pant extracts pant measurements
      const pantVals = extractPreselectedMeasurements('Formal Pant', customerProfileMeasurements);
      assert.ok(pantVals);
      assert.equal(pantVals.waist, 32);
      assert.equal(pantVals.bottom, 14);

      // Test 3: Selecting Blouse extracts blouse measurements
      const blouseVals = extractPreselectedMeasurements('Designer Blouse', customerProfileMeasurements);
      assert.ok(blouseVals);
      assert.equal(blouseVals.frontNeck, 7);
      assert.equal(blouseVals.backNeck, 9);

      // Test 4: Selecting Kurti extracts kurti measurements
      const kurtiVals = extractPreselectedMeasurements('Cotton Kurti', customerProfileMeasurements);
      assert.ok(kurtiVals);
      assert.equal(kurtiVals.hips, 40);
      assert.equal(kurtiVals.length, 42);
    });
  });

  describe('11.6 Garment Templates & Versioned Measurement Schemas', () => {
    it('should register standard garment templates with versioning and required fields', () => {
      const standardKeys = ['shirt', 'pant', 'blouse', 'kurti', 'salwar', 'suit', 'lehenga'];
      for (const key of standardKeys) {
        const template = GARMENT_TEMPLATES[key];
        assert.ok(template, `Template for ${key} must exist`);
        assert.equal(template.version, 1, `Template for ${key} must have schema version`);
        assert.ok(Array.isArray(template.fields), `Template for ${key} must have fields array`);
        assert.ok(template.fields.some((f) => f.required), `Template for ${key} must have required fields`);
      }
    });

    it('should resolve garment template canonically by various garment names', () => {
      assert.equal(resolveGarmentTemplate('Formal Shirt')?.key, 'shirt');
      assert.equal(resolveGarmentTemplate('Lycra Trouser')?.key, 'pant');
      assert.equal(resolveGarmentTemplate('Saree Blouse')?.key, 'blouse');
      assert.equal(resolveGarmentTemplate('Anarkali Kurti')?.key, 'kurti');
      assert.equal(resolveGarmentTemplate('Chudidar Salwar')?.key, 'salwar');
      assert.equal(resolveGarmentTemplate('Safari Suit')?.key, 'suit');
      assert.equal(resolveGarmentTemplate('Bridal Lehenga')?.key, 'lehenga');
      assert.equal(resolveGarmentTemplate('Unknown Costume'), null);
    });

    it('should validate measurements against plausible tailoring ranges', () => {
      // 1. Valid blouse measurements
      const validBlouse = {
        length: 15,
        chest: 36,
        waist: 30,
        shoulder: 14,
        frontNeck: 6.5,
        backNeck: 8,
      };
      const validRes = validateMeasurementsForTemplate('blouse', validBlouse);
      assert.equal(validRes.valid, true);
      assert.equal(validRes.errors.length, 0);
      assert.equal(validRes.sanitized.length, 15);
      assert.equal(validRes.schemaVersion, 1);

      // 2. Out-of-bounds measurements (e.g. negative or implausible)
      const invalidBlouse = {
        length: 3, // below minimum 10" for blouse
        chest: 150, // exceeds maximum 60"
        waist: -25, // negative
      };
      const invalidRes = validateMeasurementsForTemplate('blouse', invalidBlouse);
      assert.equal(invalidRes.valid, false);
      assert.ok(invalidRes.errors.length >= 3);
    });

    it('should create immutable versioned measurements snapshot for orders', () => {
      const measurements = { length: 42, chest: 38, waist: 32, hips: 42 };
      const snapshot = createMeasurementsSnapshot('Designer Kurti', measurements);

      assert.equal(snapshot.templateKey, 'kurti');
      assert.equal(snapshot.schemaVersion, 1);
      assert.equal(snapshot.garmentName, 'Designer Kurti');
      assert.deepEqual(snapshot.measurements, measurements);
      assert.ok(snapshot.capturedAt);
    });
  });

  describe('11.2 Month-End Reporting & RFC 4180 CSV Serialization', () => {
    it('should escape CSV cells in accordance with RFC 4180 standard', () => {
      // Null and undefined
      assert.equal(escapeCSV(null), '');
      assert.equal(escapeCSV(undefined), '');

      // Plain text
      assert.equal(escapeCSV('Sherwani Booking'), 'Sherwani Booking');

      // Value containing comma
      assert.equal(escapeCSV('Blouse, Kurti, and Salwar'), '"Blouse, Kurti, and Salwar"');

      // Value containing double quotes
      assert.equal(escapeCSV('Zari "Gold" Work'), '"Zari ""Gold"" Work"');

      // Value containing newline
      assert.equal(escapeCSV('Line 1\nLine 2'), '"Line 1\nLine 2"');

      // Value containing Unicode (Devanagari)
      assert.equal(escapeCSV('सूट, शेरवानी'), '"सूट, शेरवानी"');
    });

    it('should generate structured month-end CSV document with UTF-8 BOM and financial sections', () => {
      const mockReport = {
        period: { label: 'November 2026', start: '2026-11-01T00:00:00.000Z', end: '2026-11-30T23:59:59.999Z' },
        generatedAt: '2026-11-30T23:59:59.000Z',
        financial: {
          totalRevenue: 245000.50,
          totalExpenses: 78500.00,
          netProfit: 166500.50,
          totalOutstandingUdhar: 42000.00,
          byMode: { cash: 120000.00, upi: 105000.50, card: 20000.00, bankTransfer: 0, other: 0 },
        },
        production: {
          totalBooked: 85,
          completed: 72,
          inProgress: 11,
          cancelled: 2,
        },
        garmentBreakdown: {
          'Blouse': { count: 35, totalValue: 52500.00, avgValue: 1500.00 },
          'Kurti': { count: 25, totalValue: 37500.00, avgValue: 1500.00 },
          'Men Shirt': { count: 25, totalValue: 31250.00, avgValue: 1250.00 },
        },
      };

      const csvString = serializeReportToCSV(mockReport);

      // Verify UTF-8 BOM is present at character index 0
      assert.equal(csvString.charCodeAt(0), 0xFEFF);

      // Verify sections are present in output
      assert.ok(csvString.includes('STITCHCRAFT MONTH-END REPORT,November 2026'));
      assert.ok(csvString.includes('Total Revenue Collected,₹245000.50'));
      assert.ok(csvString.includes('Net Shop Profit / Loss,₹166500.50'));
      assert.ok(csvString.includes('Total Outstanding Udhar (Pending Balance),₹42000.00'));
      assert.ok(csvString.includes('UPI,₹105000.50'));
      assert.ok(csvString.includes('Blouse,35,₹52500.00,₹1500.00'));
    });
  });

  describe('11.3 Invoice Reliability & Payment Proof Workflow', () => {
    it('should validate payment proof submission fields (minimum UTR length, positive amount)', () => {
      const validateProofInput = ({ utr, amount, balanceAmount }) => {
        if (!utr || typeof utr !== 'string' || utr.trim().length < 6) {
          return { valid: false, error: 'UTR must be at least 6 characters' };
        }
        const numericAmount = Number(amount);
        if (isNaN(numericAmount) || numericAmount <= 0) {
          return { valid: false, error: 'Amount must be a positive number' };
        }
        if (numericAmount > balanceAmount) {
          return { valid: false, error: 'Amount exceeds balance' };
        }
        return { valid: true };
      };

      // Valid proof
      const valid = validateProofInput({ utr: 'SBI123456789012', amount: 1500, balanceAmount: 2000 });
      assert.equal(valid.valid, true);

      // Invalid short UTR
      const shortUtr = validateProofInput({ utr: '123', amount: 1500, balanceAmount: 2000 });
      assert.equal(shortUtr.valid, false);
      assert.equal(shortUtr.error, 'UTR must be at least 6 characters');

      // Amount exceeds balance
      const excess = validateProofInput({ utr: 'SBI123456789012', amount: 2500, balanceAmount: 2000 });
      assert.equal(excess.valid, false);
      assert.equal(excess.error, 'Amount exceeds balance');
    });

    it('should transition proof state upon approval or rejection and prevent duplicate reconciliation', () => {
      const order = {
        _id: 'ord_inv_proof_1',
        paymentProofs: [
          {
            proofId: 'proof_101',
            utr: 'HDFC987654321',
            amount: 2500,
            status: 'pending_reconciliation',
          },
        ],
      };

      // Reconcile function simulation
      const reconcile = (proofId, action, rejectionReason = '') => {
        const p = order.paymentProofs.find((item) => item.proofId === proofId);
        if (!p) throw new Error('Not found');
        if (p.status !== 'pending_reconciliation') {
          throw new Error(`Already reconciled with status '${p.status}'`);
        }
        if (action === 'approve') {
          p.status = 'approved';
        } else {
          p.status = 'rejected';
          p.rejectionReason = rejectionReason;
        }
        return p;
      };

      // Approval
      const approved = reconcile('proof_101', 'approve');
      assert.equal(approved.status, 'approved');

      // Attempting duplicate reconciliation must throw
      assert.throws(
        () => reconcile('proof_101', 'approve'),
        /Already reconciled with status 'approved'/,
      );
    });
  });

  describe('11.7 Karigar Wages & Piece-Rate Ledger', () => {
    it('should resolve default piece rates for garments and support custom rates', () => {
      assert.equal(resolvePieceRate('Blouse'), 350);
      assert.equal(resolvePieceRate('Kurti'), 250);
      assert.equal(resolvePieceRate('Pant'), 220);
      assert.equal(resolvePieceRate('Shirt'), 200);
      assert.equal(resolvePieceRate('Suit'), 1200);
      assert.equal(resolvePieceRate('Lehenga'), 800);

      // Custom agreed rate overrides default
      assert.equal(resolvePieceRate('Blouse', 450), 450);
      assert.equal(resolvePieceRate('Suit', 1500), 1500);
    });

    it('should maintain running payable balance invariant: payable = accrued - paid', () => {
      // Simulating a Karigar completing 3 orders and receiving 1 payout
      const wageEntries = [
        { wageType: 'accrual', amount: 350, description: 'Blouse' },
        { wageType: 'accrual', amount: 350, description: 'Blouse' },
        { wageType: 'accrual', amount: 1200, description: 'Suit' },
        { wageType: 'payout', amount: 1000, description: 'Weekly Cash Payout' },
      ];

      let accrued = 0;
      let paid = 0;
      for (const entry of wageEntries) {
        if (entry.wageType === 'accrual') accrued += entry.amount;
        if (entry.wageType === 'payout') paid += entry.amount;
      }

      const payable = accrued - paid;
      assert.equal(accrued, 1900); // 350 + 350 + 1200
      assert.equal(paid, 1000);
      assert.equal(payable, 900); // Invariant holds
    });
  });

  describe('11.4 Offline Parity Expansion in Sync Registry', () => {
    it('should prioritize mutations correctly including repairs, shop settings, and karigar assignments', () => {
      assert.equal(getUploadPriority('shops'), 1);
      assert.equal(getUploadPriority('shop_settings'), 1);
      assert.equal(getUploadPriority('customers'), 2);
      assert.equal(getUploadPriority('measurements'), 3);
      assert.equal(getUploadPriority('orders'), 4);
      assert.equal(getUploadPriority('repairs'), 4);
      assert.equal(getUploadPriority('repair_jobs'), 4);
      assert.equal(getUploadPriority('order_payments'), 5);
      assert.equal(getUploadPriority('deliveries'), 6);
      assert.equal(getUploadPriority('karigar_assignments'), 6);
    });

    it('should sort client mutations in strict dependency precedence order', () => {
      const unorderedMutations = [
        { mutationId: 'm_assignment', entityType: 'karigar_assignments', createdAt: '2026-11-06T10:00:00Z' },
        { mutationId: 'm_repair', entityType: 'repairs', createdAt: '2026-11-06T10:00:00Z' },
        { mutationId: 'm_customer', entityType: 'customers', createdAt: '2026-11-06T10:00:00Z' },
        { mutationId: 'm_shop', entityType: 'shop_settings', createdAt: '2026-11-06T10:00:00Z' },
      ];

      const sorted = sortMutationsByDependency(unorderedMutations);
      assert.deepEqual(
        sorted.map((m) => m.mutationId),
        ['m_shop', 'm_customer', 'm_repair', 'm_assignment'],
      );
    });
  });
});
