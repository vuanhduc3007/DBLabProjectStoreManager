-- =====================================================
-- 02. CREATE TABLES - Store Management System
-- 11 Tables across 7 modules
-- =====================================================

USE StoreManagementDB;
GO

-- =====================================================
-- Module 1: System Administration (RBAC)
-- =====================================================

-- Table 1: Roles (Vai trò hệ thống)
CREATE TABLE Roles (
    RoleID      INT IDENTITY(1,1) PRIMARY KEY,
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255) NULL,
    CreatedAt   DATETIME2 DEFAULT GETDATE()
);
GO
PRINT N'✅ Tạo bảng Roles thành công';
GO

-- Table 2: Users (Tài khoản đăng nhập)
CREATE TABLE Users (
    UserID       INT IDENTITY(1,1) PRIMARY KEY,
    Username     VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    RoleID       INT NOT NULL,
    IsActive     BIT NOT NULL DEFAULT 1,
    LastLogin    DATETIME2 NULL,
    CreatedAt    DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);
GO
PRINT N'✅ Tạo bảng Users thành công';
GO

-- =====================================================
-- Module 2: Human Resources
-- =====================================================

-- Table 3: Employees (Nhân viên)
CREATE TABLE Employees (
    EmployeeID   INT IDENTITY(1,1) PRIMARY KEY,
    UserID       INT NULL UNIQUE,
    EmployeeCode VARCHAR(20) NOT NULL UNIQUE,
    FullName     NVARCHAR(100) NOT NULL,
    Gender       NVARCHAR(10) NULL CHECK (Gender IN (N'Nam', N'Nữ', N'Khác')),
    DateOfBirth  DATE NULL,
    Phone        VARCHAR(15) NOT NULL UNIQUE,
    Email        VARCHAR(100) NULL,
    Address      NVARCHAR(255) NULL,
    Position     NVARCHAR(50) NOT NULL,
    HireDate     DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    BasicSalary  DECIMAL(18, 0) NOT NULL DEFAULT 0,
    Status       NVARCHAR(20) NOT NULL DEFAULT N'Đang làm việc',
    CONSTRAINT FK_Employees_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL,
    CONSTRAINT CK_Employees_Salary CHECK (BasicSalary >= 0),
    CONSTRAINT CK_Employees_Phone CHECK (Phone LIKE '0%'),
    CONSTRAINT CK_Employees_Status CHECK (Status IN (N'Đang làm việc', N'Tạm nghỉ', N'Đã nghỉ việc'))
);
GO
PRINT N'✅ Tạo bảng Employees thành công';
GO

-- =====================================================
-- Module 3: Catalog & Products
-- =====================================================

-- Table 4: Categories (Danh mục hàng hóa)
CREATE TABLE Categories (
    CategoryID   INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description  NVARCHAR(255) NULL,
    IsActive     BIT NOT NULL DEFAULT 1
);
GO
PRINT N'✅ Tạo bảng Categories thành công';
GO

-- Table 5: Products (Sản phẩm)
CREATE TABLE Products (
    ProductID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode VARCHAR(30) NOT NULL UNIQUE,
    Barcode     VARCHAR(30) NULL UNIQUE,
    ProductName NVARCHAR(150) NOT NULL,
    CategoryID  INT NOT NULL,
    Unit        NVARCHAR(30) NOT NULL DEFAULT N'Cái',
    CostPrice   DECIMAL(18, 0) NOT NULL DEFAULT 0,
    SellingPrice DECIMAL(18, 0) NOT NULL DEFAULT 0,
    ImageUrl    VARCHAR(500) NULL,
    Description NVARCHAR(MAX) NULL,
    IsActive    BIT NOT NULL DEFAULT 1,
    CreatedAt   DATETIME2 DEFAULT GETDATE(),
    UpdatedAt   DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    CONSTRAINT CK_Products_CostPrice CHECK (CostPrice >= 0),
    CONSTRAINT CK_Products_SellingPrice CHECK (SellingPrice >= 0),
    CONSTRAINT CK_Products_PriceLogic CHECK (SellingPrice >= CostPrice)
);
GO
PRINT N'✅ Tạo bảng Products thành công';
GO

-- =====================================================
-- Module 4: Customer Management (CRM)
-- =====================================================

-- Table 6: Customers (Khách hàng)
CREATE TABLE Customers (
    CustomerID   INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode VARCHAR(20) NOT NULL UNIQUE,
    FullName     NVARCHAR(100) NOT NULL,
    Phone        VARCHAR(15) NOT NULL UNIQUE,
    Email        VARCHAR(100) NULL,
    Address      NVARCHAR(255) NULL,
    TotalSpent   DECIMAL(18, 0) NOT NULL DEFAULT 0,
    CreatedAt    DATETIME2 DEFAULT GETDATE(),
    IsActive     BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_Customers_Phone CHECK (Phone LIKE '0%'),
    CONSTRAINT CK_Customers_TotalSpent CHECK (TotalSpent >= 0)
);
GO
PRINT N'✅ Tạo bảng Customers thành công';
GO

-- =====================================================
-- Module 5: Supplier Management
-- =====================================================

-- Table 7: Suppliers (Nhà cung cấp)
CREATE TABLE Suppliers (
    SupplierID   INT IDENTITY(1,1) PRIMARY KEY,
    SupplierCode VARCHAR(20) NOT NULL UNIQUE,
    SupplierName NVARCHAR(150) NOT NULL,
    ContactPerson NVARCHAR(100) NULL,
    Phone        VARCHAR(15) NOT NULL,
    Email        VARCHAR(100) NULL,
    Address      NVARCHAR(255) NULL,
    IsActive     BIT NOT NULL DEFAULT 1
);
GO
PRINT N'✅ Tạo bảng Suppliers thành công';
GO

-- =====================================================
-- Module 6: Inventory Management
-- =====================================================

-- Table 8: Inventory (Tồn kho)
CREATE TABLE Inventory (
    InventoryID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductID     INT NOT NULL UNIQUE,
    StockQuantity INT NOT NULL DEFAULT 0,
    MinStockLevel INT NOT NULL DEFAULT 5,
    LastUpdated   DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CK_Inventory_Stock CHECK (StockQuantity >= 0),
    CONSTRAINT CK_Inventory_MinStock CHECK (MinStockLevel >= 0)
);
GO
PRINT N'✅ Tạo bảng Inventory thành công';
GO

-- =====================================================
-- Module 7: Purchasing (Nhập hàng)
-- =====================================================

-- Table 9: PurchaseOrders (Phiếu nhập hàng)
CREATE TABLE PurchaseOrders (
    PurchaseOrderID INT IDENTITY(1,1) PRIMARY KEY,
    POCode          VARCHAR(30) NOT NULL UNIQUE,
    SupplierID      INT NOT NULL,
    EmployeeID      INT NOT NULL,
    OrderDate       DATETIME2 DEFAULT GETDATE(),
    TotalAmount     DECIMAL(18, 0) NOT NULL DEFAULT 0,
    Status          NVARCHAR(30) NOT NULL DEFAULT N'Hoàn thành',
    Note            NVARCHAR(MAX) NULL,
    CONSTRAINT FK_PO_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    CONSTRAINT FK_PO_Employees FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT CK_PO_Status CHECK (Status IN (N'Chờ duyệt', N'Hoàn thành', N'Đã hủy'))
);
GO
PRINT N'✅ Tạo bảng PurchaseOrders thành công';
GO

-- Table 10: PurchaseOrderDetails (Chi tiết phiếu nhập)
CREATE TABLE PurchaseOrderDetails (
    PODetailID      INT IDENTITY(1,1) PRIMARY KEY,
    PurchaseOrderID INT NOT NULL,
    ProductID       INT NOT NULL,
    Quantity        INT NOT NULL,
    UnitPrice       DECIMAL(18, 0) NOT NULL,
    LineTotal       AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_PODetail_PO FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrders(PurchaseOrderID) ON DELETE CASCADE,
    CONSTRAINT FK_PODetail_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CK_PODetail_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_PODetail_Price CHECK (UnitPrice >= 0)
);
GO
PRINT N'✅ Tạo bảng PurchaseOrderDetails thành công';
GO

-- =====================================================
-- Module 7: Sales (Bán hàng)
-- =====================================================

-- Table 11: Invoices (Hóa đơn bán hàng)
CREATE TABLE Invoices (
    InvoiceID      INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceCode    VARCHAR(30) NOT NULL UNIQUE,
    CustomerID     INT NULL,  -- NULL = khách vãng lai
    EmployeeID     INT NOT NULL,
    InvoiceDate    DATETIME2 DEFAULT GETDATE(),
    SubTotal       DECIMAL(18, 0) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18, 0) NOT NULL DEFAULT 0,
    TotalAmount    DECIMAL(18, 0) NOT NULL DEFAULT 0,
    PaymentMethod  NVARCHAR(50) NOT NULL DEFAULT N'Tiền mặt',
    Status         NVARCHAR(30) NOT NULL DEFAULT N'Đã thanh toán',
    Note           NVARCHAR(255) NULL,
    CONSTRAINT FK_Invoices_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    CONSTRAINT FK_Invoices_Employees FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT CK_Invoices_PaymentMethod CHECK (PaymentMethod IN (N'Tiền mặt', N'Chuyển khoản', N'Thẻ POS', N'Ví điện tử')),
    CONSTRAINT CK_Invoices_Status CHECK (Status IN (N'Đã thanh toán', N'Đã hủy'))
);
GO
PRINT N'✅ Tạo bảng Invoices thành công';
GO

-- Table 12: InvoiceDetails (Chi tiết hóa đơn)
CREATE TABLE InvoiceDetails (
    InvoiceDetailID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID       INT NOT NULL,
    ProductID       INT NOT NULL,
    Quantity        INT NOT NULL,
    UnitPrice       DECIMAL(18, 0) NOT NULL,
    LineTotal       AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_InvDetail_Invoices FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID) ON DELETE CASCADE,
    CONSTRAINT FK_InvDetail_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CK_InvDetail_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_InvDetail_Price CHECK (UnitPrice >= 0)
);
GO
PRINT N'✅ Tạo bảng InvoiceDetails thành công';
GO

PRINT N'';
PRINT N'🎉 Tất cả 11 bảng đã được tạo thành công!';
GO
