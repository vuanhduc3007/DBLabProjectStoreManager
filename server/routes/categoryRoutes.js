const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/categories
router.get('/', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .query('SELECT * FROM Categories WHERE IsActive = 1 ORDER BY CategoryName');
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
