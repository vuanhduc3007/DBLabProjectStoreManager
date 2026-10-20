const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// GET /api/products — Search + paginate
router.get('/', async (req, res) => {
    try {
        const { keyword, categoryId, page = 1, pageSize = 20 } = req.query;
        const pool = await poolPromise;
        const request = pool.request();
        request.input('Keyword', sql.NVarChar(100), keyword || null);
        request.input('CategoryID', sql.Int, categoryId ? parseInt(categoryId) : null);
        request.input('PageNumber', sql.Int, parseInt(page));
        request.input('PageSize', sql.Int, parseInt(pageSize));

        const result = await request.execute('sp_SearchProducts');
        res.json({
            success: true,
            data: result.recordsets[1],
            totalCount: result.recordsets[0][0].TotalCount
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/products/:id
router.get('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('id', sql.Int, req.params.id)
            .query(`
                SELECT p.*, c.CategoryName, ISNULL(inv.StockQuantity, 0) AS StockQuantity
                FROM Products p
                INNER JOIN Categories c ON p.CategoryID = c.CategoryID
                LEFT JOIN Inventory inv ON p.ProductID = inv.ProductID
                WHERE p.ProductID = @id
            `);
        if (result.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm.' });
        }
        res.json({ success: true, data: result.recordset[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/products
router.post('/', async (req, res) => {
    try {
        const { productCode, barcode, productName, categoryId, unit, costPrice, sellingPrice, description } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('productCode', sql.VarChar(30), productCode)
            .input('barcode', sql.VarChar(30), barcode || null)
            .input('productName', sql.NVarChar(150), productName)
            .input('categoryId', sql.Int, categoryId)
            .input('unit', sql.NVarChar(30), unit || N'Cái')
            .input('costPrice', sql.Decimal(18, 0), costPrice)
            .input('sellingPrice', sql.Decimal(18, 0), sellingPrice)
            .input('description', sql.NVarChar(sql.MAX), description || null)
            .query(`
                INSERT INTO Products (ProductCode, Barcode, ProductName, CategoryID, Unit, CostPrice, SellingPrice, Description)
                VALUES (@productCode, @barcode, @productName, @categoryId, @unit, @costPrice, @sellingPrice, @description);
                SELECT SCOPE_IDENTITY() AS ProductID;
            `);
        res.status(201).json({ success: true, message: 'Thêm sản phẩm thành công!', data: { productID: result.recordset[0].ProductID } });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT /api/products/:id
router.put('/:id', async (req, res) => {
    try {
        const { productName, barcode, categoryId, unit, costPrice, sellingPrice, description, isActive } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('id', sql.Int, req.params.id)
            .input('productName', sql.NVarChar(150), productName)
            .input('barcode', sql.VarChar(30), barcode || null)
            .input('categoryId', sql.Int, categoryId)
            .input('unit', sql.NVarChar(30), unit)
            .input('costPrice', sql.Decimal(18, 0), costPrice)
            .input('sellingPrice', sql.Decimal(18, 0), sellingPrice)
            .input('description', sql.NVarChar(sql.MAX), description || null)
            .input('isActive', sql.Bit, isActive !== undefined ? isActive : 1)
            .query(`
                UPDATE Products SET
                    ProductName = @productName, Barcode = @barcode, CategoryID = @categoryId,
                    Unit = @unit, CostPrice = @costPrice, SellingPrice = @sellingPrice,
                    Description = @description, IsActive = @isActive
                WHERE ProductID = @id
            `);
        res.json({ success: true, message: 'Cập nhật sản phẩm thành công!' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// DELETE /api/products/:id (soft delete)
router.delete('/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('id', sql.Int, req.params.id)
            .query('UPDATE Products SET IsActive = 0 WHERE ProductID = @id');
        res.json({ success: true, message: 'Đã xóa sản phẩm.' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
