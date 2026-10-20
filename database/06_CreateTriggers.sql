-- =====================================================
-- 06. CREATE TRIGGERS - Store Management System
-- =====================================================

USE StoreManagementDB;
GO

-- =====================================================
-- Trigger 1: trg_PreventDeleteInvoice
-- Không cho phép xóa hóa đơn - phải hủy thay vì xóa
-- Kỹ thuật: INSTEAD OF DELETE
-- =====================================================
CREATE OR ALTER TRIGGER trg_PreventDeleteInvoice
ON Invoices
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    RAISERROR(N'Không được phép xóa hóa đơn. Vui lòng cập nhật trạng thái thành "Đã hủy" thay vì xóa.', 16, 1);
END;
GO

PRINT N'✅ Tạo Trigger trg_PreventDeleteInvoice thành công';
GO

-- =====================================================
-- Trigger 2: trg_AutoCreateInventory
-- Tự động tạo bản ghi tồn kho khi thêm sản phẩm mới
-- Kỹ thuật: AFTER INSERT
-- =====================================================
CREATE OR ALTER TRIGGER trg_AutoCreateInventory
ON Products
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inventory (ProductID, StockQuantity, MinStockLevel, LastUpdated)
    SELECT i.ProductID, 0, 5, GETDATE()
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1 FROM Inventory inv WHERE inv.ProductID = i.ProductID
    );
END;
GO

PRINT N'✅ Tạo Trigger trg_AutoCreateInventory thành công';
GO

-- =====================================================
-- Trigger 3: trg_UpdateProductTimestamp
-- Tự động cập nhật UpdatedAt khi sửa sản phẩm
-- Kỹ thuật: AFTER UPDATE
-- =====================================================
CREATE OR ALTER TRIGGER trg_UpdateProductTimestamp
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ cập nhật nếu không phải đang update UpdatedAt
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE p
        SET p.UpdatedAt = GETDATE()
        FROM Products p
        INNER JOIN inserted i ON p.ProductID = i.ProductID;
    END
END;
GO

PRINT N'✅ Tạo Trigger trg_UpdateProductTimestamp thành công';
GO

PRINT N'🎉 Tất cả Triggers đã được tạo thành công!';
GO
