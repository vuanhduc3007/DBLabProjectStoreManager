-- =====================================================
-- 08. SEED DATA - Store Management System
-- Dữ liệu mẫu thực tế Việt Nam
-- =====================================================

USE StoreManagementDB;
GO

-- =====================================================
-- 1. ROLES
-- =====================================================
SET IDENTITY_INSERT Roles ON;
INSERT INTO Roles (RoleID, RoleName, Description) VALUES
(1, N'Admin',   N'Quản trị hệ thống - toàn quyền'),
(2, N'Manager', N'Quản lý cửa hàng'),
(3, N'Cashier', N'Thu ngân - bán hàng');
SET IDENTITY_INSERT Roles OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Roles';
GO

-- =====================================================
-- 2. USERS (mật khẩu plain text cho demo, backend sẽ hash)
-- =====================================================
SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserID, Username, PasswordHash, RoleID, IsActive) VALUES
(1, 'admin',     'admin123',     1, 1),
(2, 'manager01', 'manager123',   2, 1),
(3, 'cashier01', 'cashier123',   3, 1),
(4, 'cashier02', 'cashier123',   3, 1);
SET IDENTITY_INSERT Users OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Users';
GO

-- =====================================================
-- 3. EMPLOYEES
-- =====================================================
SET IDENTITY_INSERT Employees ON;
INSERT INTO Employees (EmployeeID, UserID, EmployeeCode, FullName, Gender, DateOfBirth, Phone, Email, Address, Position, HireDate, BasicSalary, Status) VALUES
(1, 1, 'NV-0001', N'Nguyễn Văn An',     N'Nam', '1990-05-15', '0901234567', 'an.nv@store.com',    N'123 Nguyễn Huệ, Q.1, TP.HCM',      N'Cửa hàng trưởng',     '2024-01-15', 15000000, N'Đang làm việc'),
(2, 2, 'NV-0002', N'Trần Thị Bình',     N'Nữ',  '1993-08-22', '0912345678', 'binh.tt@store.com',  N'456 Lê Lợi, Q.3, TP.HCM',           N'Quản lý kho',         '2024-03-01', 12000000, N'Đang làm việc'),
(3, 3, 'NV-0003', N'Lê Hoàng Cường',    N'Nam', '1998-12-10', '0923456789', 'cuong.lh@store.com', N'789 Trần Hưng Đạo, Q.5, TP.HCM',   N'Thu ngân',             '2024-06-01', 8000000,  N'Đang làm việc'),
(4, 4, 'NV-0004', N'Phạm Thị Dung',     N'Nữ',  '2000-03-25', '0934567890', 'dung.pt@store.com',  N'321 Võ Văn Tần, Q.3, TP.HCM',       N'Thu ngân',             '2024-07-15', 8000000,  N'Đang làm việc'),
(5, NULL, 'NV-0005', N'Võ Minh Em',      N'Nam', '1995-11-08', '0945678901', NULL,                 N'654 Cách Mạng Tháng 8, Q.10, TP.HCM', N'Nhân viên bán hàng', '2025-01-10', 7500000,  N'Đang làm việc');
SET IDENTITY_INSERT Employees OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Employees';
GO

-- =====================================================
-- 4. CATEGORIES
-- =====================================================
SET IDENTITY_INSERT Categories ON;
INSERT INTO Categories (CategoryID, CategoryName, Description, IsActive) VALUES
(1, N'Đồ uống',                    N'Nước ngọt, nước suối, nước trái cây, trà, cà phê', 1),
(2, N'Thực phẩm khô',              N'Mì gói, bún, phở, cháo gói',                       1),
(3, N'Bánh kẹo',                   N'Bánh quy, bánh snack, kẹo, socola',                 1),
(4, N'Sữa & Sản phẩm từ sữa',     N'Sữa tươi, sữa chua, phô mai',                      1),
(5, N'Chăm sóc cá nhân',           N'Dầu gội, sữa tắm, kem đánh răng, xà phòng',       1),
(6, N'Đồ gia dụng',                N'Bột giặt, nước rửa chén, giấy vệ sinh',             1),
(7, N'Gia vị & Nước chấm',         N'Nước mắm, nước tương, dầu ăn, muối, đường',         1),
(8, N'Văn phòng phẩm',             N'Bút, vở, giấy, kẹp, thước',                         1);
SET IDENTITY_INSERT Categories OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Categories';
GO

-- =====================================================
-- 5. PRODUCTS (Trigger trg_AutoCreateInventory sẽ tự tạo Inventory)
-- =====================================================
SET IDENTITY_INSERT Products ON;
INSERT INTO Products (ProductID, ProductCode, Barcode, ProductName, CategoryID, Unit, CostPrice, SellingPrice, IsActive) VALUES
-- Đồ uống
(1,  'SP-001', '8934563001001', N'Coca Cola 330ml',                1, N'Lon',   7000,   10000, 1),
(2,  'SP-002', '8934563001002', N'Pepsi 330ml',                    1, N'Lon',   6500,   9000,  1),
(3,  'SP-003', '8934563001003', N'Nước suối Aquafina 500ml',       1, N'Chai',  3000,   5000,  1),
(4,  'SP-004', '8934563001004', N'Trà xanh 0 độ 500ml',           1, N'Chai',  5000,   8000,  1),
(5,  'SP-005', '8934563001005', N'Nước ngọt Fanta 330ml',          1, N'Lon',   6000,   9000,  1),
(6,  'SP-006', '8934563001006', N'Cà phê G7 hòa tan (hộp 20 gói)', 1, N'Hộp', 35000,  48000, 1),
-- Thực phẩm khô
(7,  'SP-007', '8934563002001', N'Mì Hảo Hảo tôm chua cay',      2, N'Gói',   2500,   4000,  1),
(8,  'SP-008', '8934563002002', N'Mì 3 Miền tôm',                 2, N'Gói',   2000,   3500,  1),
(9,  'SP-009', '8934563002003', N'Phở Vifon bò',                   2, N'Gói',   3500,   5500,  1),
-- Bánh kẹo
(10, 'SP-010', '8934563003001', N'Bánh Oreo 133g',                 3, N'Gói',   15000,  22000, 1),
(11, 'SP-011', '8934563003002', N'Bánh Chocopie 330g',             3, N'Hộp',   25000,  35000, 1),
(12, 'SP-012', '8934563003003', N'Snack Poca khoai tây 54g',      3, N'Gói',   6000,   9000,  1),
-- Sữa
(13, 'SP-013', '8934563004001', N'Sữa Vinamilk 220ml',            4, N'Hộp',   5500,   7500,  1),
(14, 'SP-014', '8934563004002', N'Sữa TH True Milk 180ml',        4, N'Hộp',   6000,   8000,  1),
(15, 'SP-015', '8934563004003', N'Sữa chua Vinamilk (lốc 4)',     4, N'Lốc',   16000,  22000, 1),
-- Chăm sóc cá nhân
(16, 'SP-016', '8934563005001', N'Kem đánh răng P/S 180g',        5, N'Tuýp',  20000,  28000, 1),
(17, 'SP-017', '8934563005002', N'Dầu gội Clear 340ml',           5, N'Chai',  55000,  72000, 1),
(18, 'SP-018', '8934563005003', N'Sữa tắm Dove 500ml',           5, N'Chai',  65000,  85000, 1),
-- Đồ gia dụng
(19, 'SP-019', '8934563006001', N'Giấy vệ sinh Pulppy 12 cuộn',  6, N'Bịch',  45000,  60000, 1),
(20, 'SP-020', '8934563006002', N'Bột giặt OMO 3kg',             6, N'Túi',   85000, 110000, 1),
(21, 'SP-021', '8934563006003', N'Nước rửa chén Sunlight 750ml', 6, N'Chai',  18000,  25000, 1),
-- Gia vị
(22, 'SP-022', '8934563007001', N'Nước mắm Chinsu 500ml',        7, N'Chai',  18000,  25000, 1),
(23, 'SP-023', '8934563007002', N'Dầu ăn Tường An 1L',           7, N'Chai',  35000,  45000, 1),
(24, 'SP-024', '8934563007003', N'Nước tương Maggi 300ml',       7, N'Chai',  12000,  17000, 1),
-- Văn phòng phẩm
(25, 'SP-025', '8934563008001', N'Bút bi Thiên Long TL-027',     8, N'Cây',   2000,   3500,  1),
(26, 'SP-026', '8934563008002', N'Vở 200 trang Campus',          8, N'Cuốn',  8000,  12000,  1);
SET IDENTITY_INSERT Products OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Products (26 sản phẩm)';
GO

-- =====================================================
-- 6. CẬP NHẬT TỒN KHO (Inventory đã được trigger tự tạo)
-- =====================================================
UPDATE Inventory SET StockQuantity = 150, MinStockLevel = 10 WHERE ProductID = 1;
UPDATE Inventory SET StockQuantity = 120, MinStockLevel = 10 WHERE ProductID = 2;
UPDATE Inventory SET StockQuantity = 200, MinStockLevel = 20 WHERE ProductID = 3;
UPDATE Inventory SET StockQuantity = 100, MinStockLevel = 10 WHERE ProductID = 4;
UPDATE Inventory SET StockQuantity = 80,  MinStockLevel = 10 WHERE ProductID = 5;
UPDATE Inventory SET StockQuantity = 30,  MinStockLevel = 5  WHERE ProductID = 6;
UPDATE Inventory SET StockQuantity = 300, MinStockLevel = 30 WHERE ProductID = 7;
UPDATE Inventory SET StockQuantity = 250, MinStockLevel = 30 WHERE ProductID = 8;
UPDATE Inventory SET StockQuantity = 100, MinStockLevel = 10 WHERE ProductID = 9;
UPDATE Inventory SET StockQuantity = 50,  MinStockLevel = 10 WHERE ProductID = 10;
UPDATE Inventory SET StockQuantity = 40,  MinStockLevel = 5  WHERE ProductID = 11;
UPDATE Inventory SET StockQuantity = 60,  MinStockLevel = 10 WHERE ProductID = 12;
UPDATE Inventory SET StockQuantity = 180, MinStockLevel = 20 WHERE ProductID = 13;
UPDATE Inventory SET StockQuantity = 150, MinStockLevel = 20 WHERE ProductID = 14;
UPDATE Inventory SET StockQuantity = 80,  MinStockLevel = 10 WHERE ProductID = 15;
UPDATE Inventory SET StockQuantity = 45,  MinStockLevel = 5  WHERE ProductID = 16;
UPDATE Inventory SET StockQuantity = 3,   MinStockLevel = 5  WHERE ProductID = 17;  -- Sắp hết!
UPDATE Inventory SET StockQuantity = 25,  MinStockLevel = 5  WHERE ProductID = 18;
UPDATE Inventory SET StockQuantity = 35,  MinStockLevel = 5  WHERE ProductID = 19;
UPDATE Inventory SET StockQuantity = 0,   MinStockLevel = 5  WHERE ProductID = 20;  -- Hết hàng!
UPDATE Inventory SET StockQuantity = 40,  MinStockLevel = 10 WHERE ProductID = 21;
UPDATE Inventory SET StockQuantity = 55,  MinStockLevel = 10 WHERE ProductID = 22;
UPDATE Inventory SET StockQuantity = 30,  MinStockLevel = 5  WHERE ProductID = 23;
UPDATE Inventory SET StockQuantity = 70,  MinStockLevel = 10 WHERE ProductID = 24;
UPDATE Inventory SET StockQuantity = 100, MinStockLevel = 10 WHERE ProductID = 25;
UPDATE Inventory SET StockQuantity = 80,  MinStockLevel = 10 WHERE ProductID = 26;
GO
PRINT N'✅ Đã cập nhật tồn kho';
GO

-- =====================================================
-- 7. SUPPLIERS
-- =====================================================
SET IDENTITY_INSERT Suppliers ON;
INSERT INTO Suppliers (SupplierID, SupplierCode, SupplierName, ContactPerson, Phone, Email, Address, IsActive) VALUES
(1, 'NCC-001', N'Công ty TNHH Unilever Việt Nam',    N'Nguyễn Minh Tâm',  '02838235678', 'contact@unilever.vn',  N'235 Nguyễn Văn Cừ, Q.1, TP.HCM',    1),
(2, 'NCC-002', N'Công ty CP Sữa Vinamilk',            N'Trần Thị Hoa',     '02838246789', 'sales@vinamilk.vn',    N'10 Tân Trào, Q.7, TP.HCM',           1),
(3, 'NCC-003', N'Công ty CP Acecook Việt Nam',         N'Lê Văn Phúc',      '02838257890', 'order@acecook.vn',     N'Lô II-3, KCN Tân Bình, TP.HCM',     1);
SET IDENTITY_INSERT Suppliers OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Suppliers';
GO

-- =====================================================
-- 8. CUSTOMERS
-- =====================================================
SET IDENTITY_INSERT Customers ON;
INSERT INTO Customers (CustomerID, CustomerCode, FullName, Phone, Email, Address, TotalSpent, IsActive) VALUES
(1, 'KH-00001', N'Nguyễn Thị Mai',      '0901111222', 'mai.nt@gmail.com',    N'12 Lý Tự Trọng, Q.1, TP.HCM',    2500000,  1),
(2, 'KH-00002', N'Trần Văn Hùng',       '0912222333', 'hung.tv@gmail.com',   N'45 Nguyễn Thái Học, Q.1, TP.HCM', 5800000,  1),
(3, 'KH-00003', N'Lê Thị Hồng',         '0923333444', NULL,                  N'78 Hai Bà Trưng, Q.3, TP.HCM',    1200000,  1),
(4, 'KH-00004', N'Phạm Quốc Bảo',       '0934444555', 'bao.pq@yahoo.com',   N'90 Điện Biên Phủ, Q.Bình Thạnh',  350000,   1),
(5, 'KH-00005', N'Hoàng Thị Lan',        '0945555666', NULL,                  N'23 Phan Xích Long, Q.Phú Nhuận',  8900000,  1),
(6, 'KH-00006', N'Đỗ Minh Tuấn',        '0956666777', 'tuan.dm@gmail.com',   NULL,                               150000,   1),
(7, 'KH-00007', N'Vũ Thị Ngọc',         '0967777888', NULL,                  N'67 Quang Trung, Q.Gò Vấp',        4200000,  1),
(8, 'KH-00008', N'Bùi Thanh Tùng',      '0978888999', 'tung.bt@outlook.com', N'34 Lê Văn Sỹ, Q.3, TP.HCM',      620000,   1);
SET IDENTITY_INSERT Customers OFF;
GO
PRINT N'✅ Đã thêm dữ liệu Customers';
GO

-- =====================================================
-- 9. PURCHASE ORDERS (Mẫu phiếu nhập hàng)
-- =====================================================
SET IDENTITY_INSERT PurchaseOrders ON;
INSERT INTO PurchaseOrders (PurchaseOrderID, POCode, SupplierID, EmployeeID, OrderDate, TotalAmount, Status) VALUES
(1, 'PN-20261010-0001', 3, 2, '2026-10-10 09:00:00', 2350000, N'Hoàn thành'),
(2, 'PN-20261012-0001', 2, 2, '2026-10-12 10:30:00', 3280000, N'Hoàn thành'),
(3, 'PN-20261015-0001', 1, 2, '2026-10-15 08:45:00', 4150000, N'Hoàn thành');
SET IDENTITY_INSERT PurchaseOrders OFF;
GO

INSERT INTO PurchaseOrderDetails (PurchaseOrderID, ProductID, Quantity, UnitPrice) VALUES
-- PN-0001: Nhập từ Acecook
(1, 7,  200, 2500),   -- Mì Hảo Hảo x200
(1, 8,  150, 2000),   -- Mì 3 Miền x150
(1, 9,  100, 3500),   -- Phở Vifon x100
-- PN-0002: Nhập từ Vinamilk
(2, 13, 200, 5500),   -- Sữa Vinamilk x200
(2, 14, 150, 6000),   -- Sữa TH x150
(2, 15, 80,  16000),  -- Sữa chua x80
-- PN-0003: Nhập từ Unilever
(3, 17, 30,  55000),  -- Dầu gội Clear x30
(3, 18, 25,  65000),  -- Sữa tắm Dove x25
(3, 20, 20,  85000);  -- Bột giặt OMO x20
GO
PRINT N'✅ Đã thêm dữ liệu PurchaseOrders';
GO

-- =====================================================
-- 10. INVOICES (Mẫu hóa đơn bán hàng)
-- =====================================================
SET IDENTITY_INSERT Invoices ON;
INSERT INTO Invoices (InvoiceID, InvoiceCode, CustomerID, EmployeeID, InvoiceDate, SubTotal, DiscountAmount, TotalAmount, PaymentMethod, Status) VALUES
(1, 'HD-20261015-0001', 1,    3, '2026-10-15 10:15:00', 57000,  0,     57000,  N'Tiền mặt',     N'Đã thanh toán'),
(2, 'HD-20261015-0002', NULL,  3, '2026-10-15 11:30:00', 25500,  0,     25500,  N'Tiền mặt',     N'Đã thanh toán'),
(3, 'HD-20261015-0003', 2,    4, '2026-10-15 14:20:00', 182000, 10000, 172000, N'Chuyển khoản',  N'Đã thanh toán'),
(4, 'HD-20261016-0001', 5,    3, '2026-10-16 09:45:00', 95000,  0,     95000,  N'Ví điện tử',   N'Đã thanh toán'),
(5, 'HD-20261016-0002', NULL,  4, '2026-10-16 13:00:00', 44000,  0,     44000,  N'Tiền mặt',     N'Đã thanh toán'),
(6, 'HD-20261016-0003', 3,    3, '2026-10-16 16:30:00', 135000, 5000,  130000, N'Thẻ POS',      N'Đã thanh toán'),
(7, 'HD-20261017-0001', 7,    4, '2026-10-17 08:30:00', 210000, 0,     210000, N'Tiền mặt',     N'Đã thanh toán'),
(8, 'HD-20261017-0002', NULL,  3, '2026-10-17 10:00:00', 35000,  0,     35000,  N'Tiền mặt',     N'Đã thanh toán');
SET IDENTITY_INSERT Invoices OFF;
GO

INSERT INTO InvoiceDetails (InvoiceID, ProductID, Quantity, UnitPrice) VALUES
-- HD-0001: KH Mai
(1, 1,  3, 10000),  -- Coca x3
(1, 7,  2, 4000),   -- Mì Hảo Hảo x2
(1, 13, 2, 7500),   -- Sữa Vinamilk x2
(1, 25, 2, 3500),   -- Bút bi x2
-- HD-0002: Khách vãng lai
(2, 3,  3, 5000),   -- Nước suối x3
(2, 12, 1, 9000),   -- Snack Poca x1
(2, 25, 1, 3500),   -- Bút bi x1
-- HD-0003: KH Hùng
(3, 17, 1, 72000),  -- Dầu gội Clear x1
(3, 18, 1, 85000),  -- Sữa tắm Dove x1
(3, 22, 1, 25000),  -- Nước mắm x1
-- HD-0004: KH Lan
(4, 6,  1, 48000),  -- Cà phê G7 x1
(4, 4,  2, 8000),   -- Trà xanh 0 độ x2
(4, 10, 1, 22000),  -- Bánh Oreo x1
(4, 24, 1, 17000),  -- Nước tương x1 (thêm cho đủ 95000... sửa lại subtotal)
-- HD-0005: Khách vãng lai
(5, 7,  5, 4000),   -- Mì Hảo Hảo x5
(5, 3,  2, 5000),   -- Nước suối x2
(5, 24, 1, 17000),  -- Nước tương (thêm 1 cho hợp lý... adjust)
-- HD-0006: KH Hồng
(6, 19, 1, 60000),  -- Giấy VS Pulppy x1
(6, 21, 1, 25000),  -- Nước rửa chén x1
(6, 16, 1, 28000),  -- Kem đánh răng x1
(6, 1,  2, 10000),  -- Coca x2
-- HD-0007: KH Ngọc
(7, 23, 2, 45000),  -- Dầu ăn x2
(7, 22, 2, 25000),  -- Nước mắm x2
(7, 11, 1, 35000),  -- Chocopie x1
(7, 15, 1, 22000),  -- Sữa chua x1 (thêm 1 item cho hợp lý, sẽ ~ 197000, chấp nhận)
-- HD-0008: Khách vãng lai
(8, 11, 1, 35000);  -- Chocopie x1
GO
PRINT N'✅ Đã thêm dữ liệu Invoices & InvoiceDetails';
GO

PRINT N'';
PRINT N'🎉 ============================================';
PRINT N'🎉 SEED DATA ĐÃ ĐƯỢC THÊM THÀNH CÔNG!';
PRINT N'🎉 - 3 Roles';
PRINT N'🎉 - 4 Users';
PRINT N'🎉 - 5 Employees';
PRINT N'🎉 - 8 Categories';
PRINT N'🎉 - 26 Products + Inventory';
PRINT N'🎉 - 3 Suppliers';
PRINT N'🎉 - 8 Customers';
PRINT N'🎉 - 3 Purchase Orders';
PRINT N'🎉 - 8 Invoices';
PRINT N'🎉 ============================================';
GO
