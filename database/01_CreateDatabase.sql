-- =====================================================
-- 01. CREATE DATABASE - Store Management System
-- DB Lab Final Project
-- =====================================================

USE master;
GO

-- Drop existing database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'StoreManagementDB')
BEGIN
    ALTER DATABASE StoreManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE StoreManagementDB;
END
GO

-- Create database with Vietnamese collation
CREATE DATABASE StoreManagementDB
COLLATE Vietnamese_CI_AS;
GO

USE StoreManagementDB;
GO

PRINT N'✅ Database StoreManagementDB đã tạo thành công!';
GO
