const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../config/db');

// POST /api/auth/login
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return res.status(400).json({ success: false, message: 'Vui lòng nhập tên đăng nhập và mật khẩu.' });
        }

        const pool = await poolPromise;
        const result = await pool.request()
            .input('username', sql.VarChar(50), username)
            .query(`
                SELECT u.UserID, u.Username, u.PasswordHash, u.IsActive,
                       r.RoleName,
                       e.EmployeeID, e.FullName, e.EmployeeCode
                FROM Users u
                INNER JOIN Roles r ON u.RoleID = r.RoleID
                LEFT JOIN Employees e ON u.UserID = e.UserID
                WHERE u.Username = @username
            `);

        if (result.recordset.length === 0) {
            return res.status(401).json({ success: false, message: 'Tên đăng nhập không tồn tại.' });
        }

        const user = result.recordset[0];

        if (!user.IsActive) {
            return res.status(401).json({ success: false, message: 'Tài khoản đã bị khóa.' });
        }

        // Plain text password comparison for demo
        if (password !== user.PasswordHash) {
            return res.status(401).json({ success: false, message: 'Mật khẩu không đúng.' });
        }

        // Update last login
        await pool.request()
            .input('userID', sql.Int, user.UserID)
            .query('UPDATE Users SET LastLogin = GETDATE() WHERE UserID = @userID');

        // Set session
        req.session.user = {
            userID: user.UserID,
            username: user.Username,
            roleName: user.RoleName,
            employeeID: user.EmployeeID,
            fullName: user.FullName || user.Username,
            employeeCode: user.EmployeeCode
        };

        res.json({
            success: true,
            message: 'Đăng nhập thành công!',
            data: req.session.user
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/auth/logout
router.post('/logout', (req, res) => {
    req.session.destroy(err => {
        if (err) return res.status(500).json({ success: false, message: 'Lỗi đăng xuất.' });
        res.json({ success: true, message: 'Đăng xuất thành công.' });
    });
});

// GET /api/auth/me
router.get('/me', (req, res) => {
    if (!req.session || !req.session.user) {
        return res.status(401).json({ success: false, message: 'Chưa đăng nhập.' });
    }
    res.json({ success: true, data: req.session.user });
});

module.exports = router;
