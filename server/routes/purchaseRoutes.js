const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/purchases
router.get('/', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT po.*, s.SupplierName, e.FullName AS EmployeeName
            FROM PurchaseOrders po
            INNER JOIN Suppliers s ON po.SupplierID = s.SupplierID
            INNER JOIN Employees e ON po.EmployeeID = e.EmployeeID
            ORDER BY po.OrderDate DESC
        `);
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/purchases/:id
router.get('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        const headerResult = await pool.request()
            .input('id', sql.Int, req.params.id)
            .query(`
                SELECT po.*, s.SupplierName, e.FullName AS EmployeeName
                FROM PurchaseOrders po
                INNER JOIN Suppliers s ON po.SupplierID = s.SupplierID
                INNER JOIN Employees e ON po.EmployeeID = e.EmployeeID
                WHERE po.PurchaseOrderID = @id
            `);
        if (headerResult.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy phiếu nhập.' });
        }
        const detailsResult = await pool.request()
            .input('poId', sql.Int, req.params.id)
            .query(`
                SELECT d.*, p.ProductCode, p.ProductName, p.Unit
                FROM PurchaseOrderDetails d
                INNER JOIN Products p ON d.ProductID = p.ProductID
                WHERE d.PurchaseOrderID = @poId
            `);
        res.json({
            success: true,
            data: { ...headerResult.recordset[0], details: detailsResult.recordset }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/purchases — Import goods
router.post('/', async (req, res) => {
    try {
        const { supplierID, employeeID, items } = req.body;
        if (!items || items.length === 0) {
            return res.status(400).json({ success: false, message: 'Danh sách hàng nhập trống.' });
        }

        const pool = await poolPromise;
        const request = pool.request();
        request.input('SupplierID', sql.Int, supplierID);
        request.input('EmployeeID', sql.Int, employeeID);
        request.input('Items', sql.NVarChar(sql.MAX), JSON.stringify(items));
        request.output('NewPurchaseOrderID', sql.Int);

        const result = await request.execute('sp_ImportGoods');

        res.status(201).json({
            success: true,
            message: 'Nhập hàng thành công!',
            data: result.recordset[0]
        });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

module.exports = router;
