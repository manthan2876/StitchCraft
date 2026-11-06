import { generateMonthEndReport, serializeReportToCSV } from '../services/reportService.js';

// @desc    Get Month-End or custom date range financial and production report
// @route   GET /api/reports/month-end
// @access  Private (Owner, Manager)
export const getMonthEndReport = async (req, res) => {
  try {
    const shopId = req.user?.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop associated with session' });
    }

    const { year, month, startDate, endDate, format } = req.query;

    const report = await generateMonthEndReport({
      shopId,
      year,
      month,
      startDate,
      endDate,
    });

    const isCsv = format === 'csv' || req.headers.accept === 'text/csv';
    if (isCsv) {
      const csvData = serializeReportToCSV(report);
      const safeLabel = report.period.label.replace(/[^a-zA-Z0-9_\-]/g, '_');
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="StitchCraft_Report_${safeLabel}.csv"`);
      return res.send(csvData);
    }

    res.json(report);
  } catch (error) {
    console.error('Month-end report generation error:', error);
    res.status(500).json({ message: error.message });
  }
};
