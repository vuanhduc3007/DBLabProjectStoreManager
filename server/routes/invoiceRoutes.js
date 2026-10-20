const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/invoices
router.get('/', async (req, res) => {
    try {
        const { fromDate, toDate, status } = req.query;
        const pool = await poolPromise;
        const request = pool.request();
        let query = `
            SELECT i.*, c.FullName AS CustomerName, c.Phone AS CustomerPhone,
                   e.FullName AS EmployeeName
            FROM Invoices i
            LEFT JOIN Customers c ON i.CustomerID = c.CustomerID
            INNER JOIN Employees e ON i.EmployeeID = e.EmployeeID
            WHERE 1=1
        `;
        if (fromDate) {
            request.input('fromDate', sql.Date, fromDate);
            query += ' AND CAST(i.InvoiceDate AS DATE) >= @fromDate';
        }
        if (toDate) {
            request.input('toDate', sql.Date, toDate);
            query += ' AND CAST(i.InvoiceDate AS DATE) <= @toDate';
        }
        if (status) {
            request.input('status', sql.NVarChar(30), status);
            query += ' AND i.Status = @status';
        }
        query += ' ORDER BY i.InvoiceDate DESC';
        const result = await request.query(query);
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/invoices/:id — Invoice with details
router.get('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        const request = pool.request().input('id', sql.Int, req.params.id);

        const invoiceResult = await request.query(`
            SELECT i.*, c.FullName AS CustomerName, c.Phone AS CustomerPhone,
                   e.FullName AS EmployeeName
            FROM Invoices i
            LEFT JOIN Customers c ON i.CustomerID = c.CustomerID
            INNER JOIN Employees e ON i.EmployeeID = e.EmployeeID
            WHERE i.InvoiceID = @id
        `);

        if (invoiceResult.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy hóa đơn.' });
        }

        const detailsResult = await pool.request()
            .input('invoiceId', sql.Int, req.params.id)
            .query(`
                SELECT d.*, p.ProductCode, p.ProductName, p.Unit
                FROM InvoiceDetails d
                INNER JOIN Products p ON d.ProductID = p.ProductID
                WHERE d.InvoiceID = @invoiceId
            `);

        res.json({
            success: true,
            data: {
                ...invoiceResult.recordset[0],
                details: detailsResult.recordset
            }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/invoices/checkout — POS Checkout
router.post('/checkout', async (req, res) => {
    try {
        const { customerID, employeeID, paymentMethod, discountAmount, items } = req.body;

        if (!items || items.length === 0) {
            return res.status(400).json({ success: false, message: 'Giỏ hàng trống.' });
        }

        const pool = await poolPromise;
        const request = pool.request();
        request.input('CustomerID', sql.Int, customerID || null);
        request.input('EmployeeID', sql.Int, employeeID);
        request.input('PaymentMethod', sql.NVarChar(50), paymentMethod || N'Tiền mặt');
        request.input('DiscountAmount', sql.Decimal(18, 0), discountAmount || 0);
        request.input('Items', sql.NVarChar(sql.MAX), JSON.stringify(items));
        request.output('NewInvoiceID', sql.Int);

        const result = await request.execute('sp_CreateInvoice');

        res.status(201).json({
            success: true,
            message: 'Thanh toán thành công!',
            data: result.recordset[0]
        });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

module.exports = router;
