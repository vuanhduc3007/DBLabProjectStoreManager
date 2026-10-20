const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/inventory
router.get('/', async (req, res) => {
    try {
        const { keyword, status } = req.query;
        const pool = await poolPromise;
        const request = pool.request();
        let query = 'SELECT * FROM vw_ProductStock WHERE 1=1';
        if (keyword) {
            request.input('keyword', sql.NVarChar(100), '%' + keyword + '%');
            query += ' AND (ProductName LIKE @keyword OR ProductCode LIKE @keyword)';
        }
        if (status) {
            request.input('status', sql.NVarChar(30), status);
            query += ' AND StockStatus = @status';
        }
        query += ' ORDER BY StockQuantity ASC';
        const result = await request.query(query);
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
