-- =====================================================
-- 03. CREATE VIEWS - Store Management System
-- =====================================================

USE StoreManagementDB;
GO

-- =====================================================
-- View 1: vw_ProductStock
-- Trạng thái tồn kho sản phẩm với cảnh báo
-- =====================================================
CREATE OR ALTER VIEW vw_ProductStock
AS
SELECT 
    p.ProductID,
    p.ProductCode,
    p.Barcode,
    p.ProductName,
    c.CategoryID,
    c.CategoryName,
    p.Unit,
    p.CostPrice,
    p.SellingPrice,
    ISNULL(inv.StockQuantity, 0) AS StockQuantity,
    ISNULL(inv.MinStockLevel, 5) AS MinStockLevel,
    CASE 
        WHEN ISNULL(inv.StockQuantity, 0) = 0 THEN N'Hết hàng'
        WHEN ISNULL(inv.StockQuantity, 0) <= ISNULL(inv.MinStockLevel, 5) THEN N'Sắp hết'
        ELSE N'Bình thường'
    END AS StockStatus,
    p.IsActive,
    p.CreatedAt,
    p.UpdatedAt
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory inv ON p.ProductID = inv.ProductID
WHERE p.IsActive = 1;
GO

PRINT N'✅ Tạo View vw_ProductStock thành công';
GO

-- =====================================================
-- View 2: vw_RevenueByDate
-- Doanh thu theo ngày
-- =====================================================
CREATE OR ALTER VIEW vw_RevenueByDate
AS
SELECT 
    CAST(i.InvoiceDate AS DATE) AS SalesDate,
    COUNT(DISTINCT i.InvoiceID) AS TotalInvoices,
    SUM(i.TotalAmount) AS Revenue,
    SUM(i.DiscountAmount) AS TotalDiscount
FROM Invoices i
WHERE i.Status = N'Đã thanh toán'
GROUP BY CAST(i.InvoiceDate AS DATE);
GO

PRINT N'✅ Tạo View vw_RevenueByDate thành công';
GO

-- =====================================================
-- View 3: vw_EmployeeSales
-- Thống kê bán hàng theo nhân viên
-- =====================================================
CREATE OR ALTER VIEW vw_EmployeeSales
AS
SELECT 
    e.EmployeeID,
    e.EmployeeCode,
    e.FullName,
    e.Position,
    COUNT(i.InvoiceID) AS TotalInvoices,
    ISNULL(SUM(i.TotalAmount), 0) AS TotalRevenue
FROM Employees e
LEFT JOIN Invoices i ON e.EmployeeID = i.EmployeeID AND i.Status = N'Đã thanh toán'
WHERE e.Status = N'Đang làm việc'
GROUP BY e.EmployeeID, e.EmployeeCode, e.FullName, e.Position;
GO

PRINT N'✅ Tạo View vw_EmployeeSales thành công';
GO

PRINT N'🎉 Tất cả Views đã được tạo thành công!';
GO
