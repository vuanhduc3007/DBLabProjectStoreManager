require('dotenv').config();
const express = require('express');
const cors = require('cors');
const session = require('express-session');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(cors({
    origin: function (origin, callback) {
        // Allow requests with no origin (file://, mobile apps, curl, etc.)
        callback(null, true);
    },
    credentials: true
}));

app.use(session({
    secret: process.env.SESSION_SECRET || 'store-secret-2026',
    resave: false,
    saveUninitialized: false,
    cookie: {
        maxAge: 24 * 60 * 60 * 1000, // 24 hours
        httpOnly: true,
        sameSite: 'lax'
    }
}));

// Serve static frontend files
app.use(express.static(path.join(__dirname, '..', 'client')));

// API Routes
app.use('/api/auth',       require('./routes/authRoutes'));
app.use('/api/products',   require('./routes/productRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/customers',  require('./routes/customerRoutes'));
app.use('/api/employees',  require('./routes/employeeRoutes'));
app.use('/api/suppliers',  require('./routes/supplierRoutes'));
app.use('/api/invoices',   require('./routes/invoiceRoutes'));
app.use('/api/purchases',  require('./routes/purchaseRoutes'));
app.use('/api/inventory',  require('./routes/inventoryRoutes'));
app.use('/api/reports',    require('./routes/reportRoutes'));

// Error handler
app.use((err, req, res, next) => {
    console.error('Server Error:', err);
    res.status(500).json({ success: false, message: 'Lỗi hệ thống: ' + err.message });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
    console.log(`📂 Frontend: http://localhost:${PORT}/pages/login.html`);
});
