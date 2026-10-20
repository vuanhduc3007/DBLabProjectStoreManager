const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/reports/dashboard
router.get('/dashboard', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().execute('sp_GetDashboardStats');
        res.json({
            success: true,
            data: {
                kpis: result.recordsets[0][0],
                revenueChart: result.recordsets[1],
                topProducts: result.recordsets[2]
            }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/reports/revenue
router.get('/revenue', async (req, res) => {
    try {
        const pool = await poolPromise;
        const request = pool.request();
        let query = 'SELECT * FROM vw_RevenueByDate WHERE 1=1';
        if (req.query.fromDate) {
            request.input('fromDate', sql.Date, req.query.fromDate);
            query += ' AND SalesDate >= @fromDate';
        }
        if (req.query.toDate) {
            request.input('toDate', sql.Date, req.query.toDate);
            query += ' AND SalesDate <= @toDate';
        }
        query += ' ORDER BY SalesDate DESC';
        const result = await request.query(query);
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/reports/top-products
router.get('/top-products', async (req, res) => {
    try {
        const { fromDate, toDate, topN = 10 } = req.query;
        const pool = await poolPromise;
        const from = fromDate || new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
        const to = toDate || new Date().toISOString().split('T')[0];
        const result = await pool.request()
            .input('fromDate', sql.DateTime2, from)
            .input('toDate', sql.DateTime2, to)
            .input('topN', sql.Int, parseInt(topN))
            .query('SELECT * FROM fn_GetTopSellingProducts(@fromDate, @toDate, @topN)');
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/reports/monthly
router.get('/monthly', async (req, res) => {
    try {
        const { year, month } = req.query;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('Year', sql.Int, parseInt(year) || new Date().getFullYear())
            .input('Month', sql.Int, parseInt(month) || new Date().getMonth() + 1)
            .execute('sp_MonthlyReport');
        res.json({
            success: true,
            data: {
                daily: result.recordsets[0],
                summary: result.recordsets[1][0]
            }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
