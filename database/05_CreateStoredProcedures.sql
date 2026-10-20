-- =====================================================
-- 05. CREATE STORED PROCEDURES - Store Management System
-- Demonstrates: Transactions, TRY/CATCH, CURSOR, JSON
-- =====================================================

USE StoreManagementDB;
GO

-- =====================================================
-- SP 1: sp_CreateInvoice
-- Thanh toán POS - Bán hàng
-- Kỹ thuật: TRANSACTION, TRY/CATCH, OPENJSON
-- =====================================================
CREATE OR ALTER PROCEDURE sp_CreateInvoice
    @CustomerID     INT = NULL,
    @EmployeeID     INT,
    @PaymentMethod  NVARCHAR(50) = N'Tiền mặt',
    @DiscountAmount DECIMAL(18, 0) = 0,
    @Items          NVARCHAR(MAX),  -- JSON: [{"productId":1,"quantity":2}, ...]
    @NewInvoiceID   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Parse JSON items vào bảng tạm
        DECLARE @CartItems TABLE (
            ProductID INT,
            Quantity INT
        );

        INSERT INTO @CartItems (ProductID, Quantity)
        SELECT 
            JSON_VALUE(value, '$.productId'),
            JSON_VALUE(value, '$.quantity')
        FROM OPENJSON(@Items);

        -- 2. Kiểm tra giỏ hàng không rỗng
        IF NOT EXISTS (SELECT 1 FROM @CartItems)
        BEGIN
            RAISERROR(N'Giỏ hàng không được rỗng.', 16, 1);
        END

        -- 3. Kiểm tra tồn kho
        DECLARE @InsufficientProduct NVARCHAR(150);
        SELECT TOP 1 @InsufficientProduct = p.ProductName
        FROM @CartItems ci
        INNER JOIN Products p ON ci.ProductID = p.ProductID
        LEFT JOIN Inventory inv ON ci.ProductID = inv.ProductID
        WHERE ISNULL(inv.StockQuantity, 0) < ci.Quantity;

        IF @InsufficientProduct IS NOT NULL
        BEGIN
            DECLARE @ErrMsg NVARCHAR(500) = N'Sản phẩm [' + @InsufficientProduct + N'] không đủ tồn kho.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- 4. Tính tổng tiền
        DECLARE @SubTotal DECIMAL(18, 0);
        SELECT @SubTotal = SUM(ci.Quantity * p.SellingPrice)
        FROM @CartItems ci
        INNER JOIN Products p ON ci.ProductID = p.ProductID;

        -- Đảm bảo discount không vượt subtotal
        IF @DiscountAmount > @SubTotal
            SET @DiscountAmount = @SubTotal;

        DECLARE @TotalAmount DECIMAL(18, 0) = @SubTotal - @DiscountAmount;

        -- 5. Sinh mã hóa đơn: HD-yyyyMMdd-XXXX
        DECLARE @Today VARCHAR(8) = FORMAT(GETDATE(), 'yyyyMMdd');
        DECLARE @NextSeq INT;
        SELECT @NextSeq = ISNULL(MAX(CAST(RIGHT(InvoiceCode, 4) AS INT)), 0) + 1
        FROM Invoices
        WHERE InvoiceCode LIKE 'HD-' + @Today + '-%';

        DECLARE @InvoiceCode VARCHAR(30) = 'HD-' + @Today + '-' + RIGHT('0000' + CAST(@NextSeq AS VARCHAR(4)), 4);

        -- 6. Insert hóa đơn
        INSERT INTO Invoices (InvoiceCode, CustomerID, EmployeeID, InvoiceDate, SubTotal, DiscountAmount, TotalAmount, PaymentMethod, Status)
        VALUES (@InvoiceCode, @CustomerID, @EmployeeID, GETDATE(), @SubTotal, @DiscountAmount, @TotalAmount, @PaymentMethod, N'Đã thanh toán');

        SET @NewInvoiceID = SCOPE_IDENTITY();

        -- 7. Insert chi tiết hóa đơn (lưu giá tại thời điểm bán)
        INSERT INTO InvoiceDetails (InvoiceID, ProductID, Quantity, UnitPrice)
        SELECT 
            @NewInvoiceID,
            ci.ProductID,
            ci.Quantity,
            p.SellingPrice
        FROM @CartItems ci
        INNER JOIN Products p ON ci.ProductID = p.ProductID;

        -- 8. Trừ tồn kho
        UPDATE inv
        SET inv.StockQuantity = inv.StockQuantity - ci.Quantity,
            inv.LastUpdated = GETDATE()
        FROM Inventory inv
        INNER JOIN @CartItems ci ON inv.ProductID = ci.ProductID;

        -- 9. Cập nhật tổng chi tiêu khách hàng
        IF @CustomerID IS NOT NULL
        BEGIN
            UPDATE Customers
            SET TotalSpent = TotalSpent + @TotalAmount
            WHERE CustomerID = @CustomerID;
        END

        COMMIT TRANSACTION;

        -- Trả về thông tin hóa đơn vừa tạo
        SELECT @NewInvoiceID AS InvoiceID, @InvoiceCode AS InvoiceCode, @TotalAmount AS TotalAmount;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Tạo SP sp_CreateInvoice thành công';
GO

-- =====================================================
-- SP 2: sp_ImportGoods
-- Nhập hàng từ nhà cung cấp
-- Kỹ thuật: TRANSACTION, TRY/CATCH, MERGE (upsert)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_ImportGoods
    @SupplierID         INT,
    @EmployeeID         INT,
    @Items              NVARCHAR(MAX),  -- JSON: [{"productId":1,"quantity":10,"unitPrice":5000}, ...]
    @NewPurchaseOrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Parse JSON
        DECLARE @ImportItems TABLE (
            ProductID INT,
            Quantity INT,
            UnitPrice DECIMAL(18, 0)
        );

        INSERT INTO @ImportItems (ProductID, Quantity, UnitPrice)
        SELECT 
            JSON_VALUE(value, '$.productId'),
            JSON_VALUE(value, '$.quantity'),
            JSON_VALUE(value, '$.unitPrice')
        FROM OPENJSON(@Items);

        -- 2. Kiểm tra items không rỗng
        IF NOT EXISTS (SELECT 1 FROM @ImportItems)
        BEGIN
            RAISERROR(N'Danh sách hàng nhập không được rỗng.', 16, 1);
        END

        -- 3. Tính tổng tiền
        DECLARE @TotalAmount DECIMAL(18, 0);
        SELECT @TotalAmount = SUM(Quantity * UnitPrice) FROM @ImportItems;

        -- 4. Sinh mã phiếu nhập: PN-yyyyMMdd-XXXX
        DECLARE @Today VARCHAR(8) = FORMAT(GETDATE(), 'yyyyMMdd');
        DECLARE @NextSeq INT;
        SELECT @NextSeq = ISNULL(MAX(CAST(RIGHT(POCode, 4) AS INT)), 0) + 1
        FROM PurchaseOrders
        WHERE POCode LIKE 'PN-' + @Today + '-%';

        DECLARE @POCode VARCHAR(30) = 'PN-' + @Today + '-' + RIGHT('0000' + CAST(@NextSeq AS VARCHAR(4)), 4);

        -- 5. Insert phiếu nhập
        INSERT INTO PurchaseOrders (POCode, SupplierID, EmployeeID, OrderDate, TotalAmount, Status)
        VALUES (@POCode, @SupplierID, @EmployeeID, GETDATE(), @TotalAmount, N'Hoàn thành');

        SET @NewPurchaseOrderID = SCOPE_IDENTITY();

        -- 6. Insert chi tiết phiếu nhập
        INSERT INTO PurchaseOrderDetails (PurchaseOrderID, ProductID, Quantity, UnitPrice)
        SELECT @NewPurchaseOrderID, ProductID, Quantity, UnitPrice
        FROM @ImportItems;

        -- 7. Cập nhật tồn kho (MERGE: nếu có thì cộng, chưa có thì thêm mới)
        MERGE Inventory AS target
        USING @ImportItems AS source
        ON target.ProductID = source.ProductID
        WHEN MATCHED THEN
            UPDATE SET 
                target.StockQuantity = target.StockQuantity + source.Quantity,
                target.LastUpdated = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (ProductID, StockQuantity, MinStockLevel, LastUpdated)
            VALUES (source.ProductID, source.Quantity, 5, GETDATE());

        -- 8. Cập nhật giá vốn sản phẩm theo giá nhập mới nhất
        UPDATE p
        SET p.CostPrice = src.UnitPrice,
            p.UpdatedAt = GETDATE()
        FROM Products p
        INNER JOIN @ImportItems src ON p.ProductID = src.ProductID;

        COMMIT TRANSACTION;

        -- Trả về thông tin
        SELECT @NewPurchaseOrderID AS PurchaseOrderID, @POCode AS POCode, @TotalAmount AS TotalAmount;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Tạo SP sp_ImportGoods thành công';
GO

-- =====================================================
-- SP 3: sp_SearchProducts
-- Tìm kiếm sản phẩm với phân trang
-- =====================================================
CREATE OR ALTER PROCEDURE sp_SearchProducts
    @Keyword    NVARCHAR(100) = NULL,
    @CategoryID INT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    -- Tổng số kết quả
    SELECT COUNT(*) AS TotalCount
    FROM vw_ProductStock
    WHERE (@Keyword IS NULL 
           OR ProductName LIKE N'%' + @Keyword + N'%' 
           OR ProductCode LIKE '%' + @Keyword + '%'
           OR Barcode LIKE '%' + @Keyword + '%')
      AND (@CategoryID IS NULL OR CategoryID = @CategoryID);

    -- Dữ liệu phân trang
    SELECT *
    FROM vw_ProductStock
    WHERE (@Keyword IS NULL 
           OR ProductName LIKE N'%' + @Keyword + N'%' 
           OR ProductCode LIKE '%' + @Keyword + '%'
           OR Barcode LIKE '%' + @Keyword + '%')
      AND (@CategoryID IS NULL OR CategoryID = @CategoryID)
    ORDER BY ProductName
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

PRINT N'✅ Tạo SP sp_SearchProducts thành công';
GO

-- =====================================================
-- SP 4: sp_GetDashboardStats
-- Lấy thống kê cho Dashboard
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetDashboardStats
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    -- Result Set 1: KPI Cards
    SELECT 
        (SELECT ISNULL(SUM(TotalAmount), 0) FROM Invoices 
         WHERE CAST(InvoiceDate AS DATE) = @Today AND Status = N'Đã thanh toán') AS TodayRevenue,
        
        (SELECT COUNT(*) FROM Invoices 
         WHERE CAST(InvoiceDate AS DATE) = @Today AND Status = N'Đã thanh toán') AS TodayInvoices,
        
        (SELECT COUNT(*) FROM Products WHERE IsActive = 1) AS TotalProducts,
        
        (SELECT COUNT(*) FROM vw_ProductStock 
         WHERE StockStatus IN (N'Hết hàng', N'Sắp hết')) AS LowStockCount;

    -- Result Set 2: Doanh thu 7 ngày gần nhất
    SELECT TOP 7 SalesDate, TotalInvoices, Revenue
    FROM vw_RevenueByDate
    WHERE SalesDate >= DATEADD(DAY, -7, @Today)
    ORDER BY SalesDate ASC;

    -- Result Set 3: Top 5 sản phẩm bán chạy tháng này
    SELECT * FROM fn_GetTopSellingProducts(
        DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1),
        @Today,
        5
    );
END;
GO

PRINT N'✅ Tạo SP sp_GetDashboardStats thành công';
GO

-- =====================================================
-- SP 5: sp_MonthlyReport
-- Báo cáo tháng sử dụng CURSOR
-- Kỹ thuật: CURSOR (yêu cầu DB Lab)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_MonthlyReport
    @Year  INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Bảng tạm lưu kết quả từng ngày
    CREATE TABLE #DailyReport (
        ReportDate    DATE,
        DayOfWeek     NVARCHAR(20),
        TotalInvoices INT,
        TotalRevenue  DECIMAL(18, 0),
        TotalItemsSold INT
    );

    -- Khai báo biến cho Cursor
    DECLARE @CurrentDate DATE;
    DECLARE @FirstDay DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @LastDay DATE = EOMONTH(@FirstDay);
    DECLARE @DayInvoices INT;
    DECLARE @DayRevenue DECIMAL(18, 0);
    DECLARE @DayItems INT;
    DECLARE @DayName NVARCHAR(20);

    -- ===== CURSOR: Duyệt từng ngày trong tháng =====
    
    -- 1. Khai báo Cursor
    DECLARE cur_Days CURSOR FOR
    SELECT DATEADD(DAY, number, @FirstDay)
    FROM master.dbo.spt_values
    WHERE type = 'P' 
      AND number <= DATEDIFF(DAY, @FirstDay, @LastDay);

    -- 2. Mở Cursor
    OPEN cur_Days;

    -- 3. Fetch dòng đầu tiên
    FETCH NEXT FROM cur_Days INTO @CurrentDate;

    -- 4. Vòng lặp xử lý từng ngày
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Tính số hóa đơn trong ngày
        SELECT @DayInvoices = COUNT(*)
        FROM Invoices
        WHERE CAST(InvoiceDate AS DATE) = @CurrentDate
          AND Status = N'Đã thanh toán';

        -- Tính doanh thu trong ngày
        SELECT @DayRevenue = ISNULL(SUM(TotalAmount), 0)
        FROM Invoices
        WHERE CAST(InvoiceDate AS DATE) = @CurrentDate
          AND Status = N'Đã thanh toán';

        -- Tính tổng số lượng hàng bán trong ngày
        SELECT @DayItems = ISNULL(SUM(d.Quantity), 0)
        FROM InvoiceDetails d
        INNER JOIN Invoices i ON d.InvoiceID = i.InvoiceID
        WHERE CAST(i.InvoiceDate AS DATE) = @CurrentDate
          AND i.Status = N'Đã thanh toán';

        -- Tên ngày trong tuần
        SET @DayName = CASE DATEPART(WEEKDAY, @CurrentDate)
            WHEN 1 THEN N'Chủ nhật'
            WHEN 2 THEN N'Thứ hai'
            WHEN 3 THEN N'Thứ ba'
            WHEN 4 THEN N'Thứ tư'
            WHEN 5 THEN N'Thứ năm'
            WHEN 6 THEN N'Thứ sáu'
            WHEN 7 THEN N'Thứ bảy'
        END;

        -- Insert kết quả vào bảng tạm
        INSERT INTO #DailyReport (ReportDate, DayOfWeek, TotalInvoices, TotalRevenue, TotalItemsSold)
        VALUES (@CurrentDate, @DayName, @DayInvoices, @DayRevenue, @DayItems);

        -- Fetch dòng tiếp theo
        FETCH NEXT FROM cur_Days INTO @CurrentDate;
    END

    -- 5. Đóng và giải phóng Cursor
    CLOSE cur_Days;
    DEALLOCATE cur_Days;

    -- Trả về kết quả chi tiết từng ngày
    SELECT * FROM #DailyReport ORDER BY ReportDate;

    -- Trả về tổng kết tháng
    SELECT 
        COUNT(*) AS TotalDaysWithSales,
        SUM(TotalInvoices) AS MonthlyInvoices,
        SUM(TotalRevenue) AS MonthlyRevenue,
        SUM(TotalItemsSold) AS MonthlyItemsSold,
        CASE WHEN COUNT(*) > 0 
             THEN SUM(TotalRevenue) / COUNT(*) 
             ELSE 0 
        END AS AvgDailyRevenue
    FROM #DailyReport
    WHERE TotalInvoices > 0;

    DROP TABLE #DailyReport;
END;
GO

PRINT N'✅ Tạo SP sp_MonthlyReport (sử dụng CURSOR) thành công';
GO

PRINT N'🎉 Tất cả Stored Procedures đã được tạo thành công!';
GO
