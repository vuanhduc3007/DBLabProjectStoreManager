const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/employees
router.get('/', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .query("SELECT * FROM Employees WHERE Status = N'Đang làm việc' ORDER BY EmployeeCode");
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/employees/:id
router.get('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('id', sql.Int, req.params.id)
            .query('SELECT * FROM Employees WHERE EmployeeID = @id');
        if (result.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy nhân viên.' });
        }
        res.json({ success: true, data: result.recordset[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
