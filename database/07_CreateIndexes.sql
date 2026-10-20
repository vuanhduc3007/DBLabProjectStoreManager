-- =====================================================
-- 07. CREATE INDEXES - Store Management System
-- Tối ưu hiệu năng truy vấn
-- =====================================================

USE StoreManagementDB;
GO

-- 1. Filtered Index trên Barcode (quét mã vạch POS)
CREATE NONCLUSTERED INDEX IX_Products_Barcode 
ON Products(Barcode) 
WHERE Barcode IS NOT NULL;
GO
PRINT N'✅ Tạo Index IX_Products_Barcode';
GO

-- 2. Index trên SĐT khách hàng (tra cứu nhanh tại quầy)
CREATE NONCLUSTERED INDEX IX_Customers_Phone 
ON Customers(Phone);
GO
PRINT N'✅ Tạo Index IX_Customers_Phone';
GO

-- 3. Covering Index trên hóa đơn (báo cáo doanh thu)
CREATE NONCLUSTERED INDEX IX_Invoices_Date_Status
ON Invoices(InvoiceDate, Status)
INCLUDE (TotalAmount, SubTotal, DiscountAmount, CustomerID, EmployeeID);
GO
PRINT N'✅ Tạo Index IX_Invoices_Date_Status';
GO

-- 4. FK Index trên InvoiceDetails (tối ưu JOIN)
CREATE NONCLUSTERED INDEX IX_InvoiceDetails_InvoiceID 
ON InvoiceDetails(InvoiceID);
GO
PRINT N'✅ Tạo Index IX_InvoiceDetails_InvoiceID';
GO

-- 5. FK Index trên InvoiceDetails theo ProductID
CREATE NONCLUSTERED INDEX IX_InvoiceDetails_ProductID 
ON InvoiceDetails(ProductID);
GO
PRINT N'✅ Tạo Index IX_InvoiceDetails_ProductID';
GO

PRINT N'🎉 Tất cả Indexes đã được tạo thành công!';
GO
