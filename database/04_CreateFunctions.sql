-- =====================================================
-- 04. CREATE FUNCTIONS - Store Management System
-- =====================================================

USE StoreManagementDB;
GO

-- =====================================================
-- Function 1 (Scalar): fn_GetTotalRevenue
-- Tính tổng doanh thu trong khoảng thời gian
-- =====================================================
CREATE OR ALTER FUNCTION fn_GetTotalRevenue(
    @FromDate DATETIME2,
    @ToDate DATETIME2
)
RETURNS DECIMAL(18, 0)
AS
BEGIN
    DECLARE @Total DECIMAL(18, 0);
    
    SELECT @Total = ISNULL(SUM(TotalAmount), 0)
    FROM Invoices
    WHERE InvoiceDate >= @FromDate 
      AND InvoiceDate < DATEADD(DAY, 1, @ToDate)
      AND Status = N'Đã thanh toán';
    
    RETURN @Total;
END;
GO

PRINT N'✅ Tạo Function fn_GetTotalRevenue thành công';
GO

-- =====================================================
-- Function 2 (Table-Valued): fn_GetTopSellingProducts
-- Lấy top N sản phẩm bán chạy nhất
-- =====================================================
CREATE OR ALTER FUNCTION fn_GetTopSellingProducts(
    @FromDate DATETIME2,
    @ToDate DATETIME2,
    @TopN INT
)
RETURNS TABLE
AS
RETURN (
    SELECT TOP (@TopN)
        p.ProductID,
        p.ProductCode,
        p.ProductName,
        c.CategoryName,
        p.Unit,
        SUM(d.Quantity) AS TotalQuantitySold,
        SUM(d.LineTotal) AS TotalRevenue
    FROM InvoiceDetails d
    INNER JOIN Invoices i ON d.InvoiceID = i.InvoiceID
    INNER JOIN Products p ON d.ProductID = p.ProductID
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
    WHERE i.InvoiceDate >= @FromDate 
      AND i.InvoiceDate < DATEADD(DAY, 1, @ToDate)
      AND i.Status = N'Đã thanh toán'
    GROUP BY p.ProductID, p.ProductCode, p.ProductName, c.CategoryName, p.Unit
    ORDER BY TotalRevenue DESC
);
GO

PRINT N'✅ Tạo Function fn_GetTopSellingProducts thành công';
GO

PRINT N'🎉 Tất cả Functions đã được tạo thành công!';
GO
