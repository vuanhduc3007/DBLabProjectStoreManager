// Common utilities

function initSidebar() {
    const user = getCurrentUser();
    const currentPath = window.location.pathname;
    const navItems = [
        { href: '/index.html', icon: 'fa-chart-pie', label: 'Dashboard' },
        { href: '/pages/products.html', icon: 'fa-box', label: 'Sản phẩm' },
        { href: '/pages/customers.html', icon: 'fa-users', label: 'Khách hàng' },
        { href: '/pages/pos.html', icon: 'fa-cash-register', label: 'Bán hàng POS' },
        { href: '/pages/purchase.html', icon: 'fa-truck', label: 'Nhập hàng' },
        { href: '/pages/reports.html', icon: 'fa-chart-bar', label: 'Báo cáo' },
    ];

    const sidebar = document.getElementById('sidebar');
    if (!sidebar) return;

    const initial = user ? user.fullName.charAt(0).toUpperCase() : 'U';
    sidebar.innerHTML = `
        <div class="sidebar-header">
            <div class="logo"><span class="logo-icon">🏪</span>Store Manager</div>
            <div class="subtitle">Hệ thống quản lý cửa hàng</div>
        </div>
        <nav class="sidebar-nav">
            ${navItems.map(item => `
                <a class="nav-item ${currentPath.endsWith(item.href) ? 'active' : ''}" href="${item.href}">
                    <i class="fas ${item.icon}"></i> ${item.label}
                </a>
            `).join('')}
        </nav>
        <div class="sidebar-footer">
            <div class="user-info">
                <div class="user-avatar">${initial}</div>
                <div>
                    <div class="user-name">${user ? user.fullName : 'User'}</div>
                    <div class="user-role">${user ? user.roleName : ''}</div>
                </div>
            </div>
            <button class="btn btn-outline btn-block btn-sm" onclick="logout()">
                <i class="fas fa-sign-out-alt"></i> Đăng xuất
            </button>
        </div>
    `;
}

// Toast notifications
function showToast(message, type = 'success') {
    let container = document.querySelector('.toast-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'toast-container';
        document.body.appendChild(container);
    }
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    const icon = type === 'success' ? 'fa-check-circle' : type === 'error' ? 'fa-exclamation-circle' : 'fa-exclamation-triangle';
    toast.innerHTML = `<i class="fas ${icon}"></i> ${message}`;
    container.appendChild(toast);
    setTimeout(() => { toast.remove(); }, 3500);
}

// Loading
function showLoading() {
    let overlay = document.querySelector('.loading-overlay');
    if (!overlay) {
        overlay = document.createElement('div');
        overlay.className = 'loading-overlay';
        overlay.innerHTML = '<div class="spinner"></div>';
        document.body.appendChild(overlay);
    }
    overlay.classList.add('active');
}

function hideLoading() {
    const overlay = document.querySelector('.loading-overlay');
    if (overlay) overlay.classList.remove('active');
}

// Format currency (VND)
function formatCurrency(amount) {
    if (amount === null || amount === undefined) return '0 đ';
    return Number(amount).toLocaleString('vi-VN') + ' đ';
}

// Format date
function formatDate(dateString) {
    if (!dateString) return '';
    const d = new Date(dateString);
    return d.toLocaleDateString('vi-VN');
}

function formatDateTime(dateString) {
    if (!dateString) return '';
    const d = new Date(dateString);
    return d.toLocaleDateString('vi-VN') + ' ' + d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
}

// Stock status badge
function stockBadge(status) {
    if (status === 'Hết hàng') return '<span class="badge badge-danger">Hết hàng</span>';
    if (status === 'Sắp hết') return '<span class="badge badge-warning">Sắp hết</span>';
    return '<span class="badge badge-success">Bình thường</span>';
}

// Modal helpers
function openModal(id) {
    document.getElementById(id).classList.add('active');
}
function closeModal(id) {
    document.getElementById(id).classList.remove('active');
}
