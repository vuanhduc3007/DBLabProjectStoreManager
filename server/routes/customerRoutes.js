const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/customers
router.get('/', async (req, res) => {
    try {
        const { keyword } = req.query;
        const pool = await poolPromise;
        const request = pool.request();
        let query = 'SELECT * FROM Customers WHERE IsActive = 1';
        if (keyword) {
            request.input('keyword', sql.NVarChar(100), '%' + keyword + '%');
            query += ' AND (FullName LIKE @keyword OR Phone LIKE @keyword OR CustomerCode LIKE @keyword)';
        }
        query += ' ORDER BY CreatedAt DESC';
        const result = await request.query(query);
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/customers/search?phone=
router.get('/search', async (req, res) => {
    try {
        const { phone } = req.query;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('phone', sql.VarChar(15), phone)
            .query('SELECT * FROM Customers WHERE Phone = @phone AND IsActive = 1');
        if (result.recordset.length === 0) {
            return res.json({ success: true, data: null, message: 'Không tìm thấy khách hàng.' });
        }
        res.json({ success: true, data: result.recordset[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/customers/:id
router.get('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('id', sql.Int, req.params.id)
            .query('SELECT * FROM Customers WHERE CustomerID = @id');
        if (result.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy khách hàng.' });
        }
        res.json({ success: true, data: result.recordset[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/customers
router.post('/', async (req, res) => {
    try {
        const { fullName, phone, email, address } = req.body;
        const pool = await poolPromise;
        // Auto-generate customer code
        const codeResult = await pool.request().query(
            "SELECT ISNULL(MAX(CAST(REPLACE(CustomerCode, 'KH-', '') AS INT)), 0) + 1 AS NextCode FROM Customers"
        );
        const customerCode = 'KH-' + String(codeResult.recordset[0].NextCode).padStart(5, '0');

        const result = await pool.request()
            .input('code', sql.VarChar(20), customerCode)
            .input('fullName', sql.NVarChar(100), fullName)
            .input('phone', sql.VarChar(15), phone)
            .input('email', sql.VarChar(100), email || null)
            .input('address', sql.NVarChar(255), address || null)
            .query(`
                INSERT INTO Customers (CustomerCode, FullName, Phone, Email, Address)
                VALUES (@code, @fullName, @phone, @email, @address);
                SELECT SCOPE_IDENTITY() AS CustomerID;
            `);
        res.status(201).json({ success: true, message: 'Thêm khách hàng thành công!', data: { customerID: result.recordset[0].CustomerID, customerCode } });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT /api/customers/:id
router.put('/:id', async (req, res) => {
    try {
        const { fullName, phone, email, address } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('id', sql.Int, req.params.id)
            .input('fullName', sql.NVarChar(100), fullName)
            .input('phone', sql.VarChar(15), phone)
            .input('email', sql.VarChar(100), email || null)
            .input('address', sql.NVarChar(255), address || null)
            .query('UPDATE Customers SET FullName=@fullName, Phone=@phone, Email=@email, Address=@address WHERE CustomerID=@id');
        res.json({ success: true, message: 'Cập nhật khách hàng thành công!' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// DELETE /api/customers/:id (soft delete)
router.delete('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('id', sql.Int, req.params.id)
            .query('UPDATE Customers SET IsActive = 0 WHERE CustomerID = @id');
        res.json({ success: true, message: 'Đã xóa khách hàng.' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
