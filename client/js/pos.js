// POS Terminal Script
let allProducts = [];
let cart = [];
let currentCustomer = null;
let loggedUser = null;

document.addEventListener('DOMContentLoaded', async () => {
    loggedUser = await checkAuth();
    if (!loggedUser) return;
    initSidebar();

    // Display Cashier
    const cashierEl = document.getElementById('cashierBadge');
    if (cashierEl) {
        cashierEl.innerHTML = `<i class="fas fa-user-circle"></i> Thu ngân: <strong>${loggedUser.fullName || loggedUser.username}</strong>`;
    }

    await loadCategories();
    await loadProducts();

    // Search and filter listeners
    const searchInput = document.getElementById('posSearchInput');
    searchInput.addEventListener('input', filterProducts);
    document.getElementById('posCategoryFilter').addEventListener('change', filterProducts);

    // Enter to lookup customer
    document.getElementById('customerPhoneInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') lookupCustomer();
    });

    // F9 shortcut for checkout
    window.addEventListener('keydown', (e) => {
        if (e.key === 'F9') {
            e.preventDefault();
            handleCheckout();
        }
    });
});

async function loadCategories() {
    try {
        const res = await api.get('/categories');
        if (res.success && res.data) {
            const select = document.getElementById('posCategoryFilter');
            select.innerHTML = '<option value="">-- Tất cả nhóm --</option>' +
                res.data.map(c => `<option value="${c.CategoryID}">${c.CategoryName}</option>`).join('');
        }
    } catch (err) {
        console.error('Lỗi danh mục:', err);
    }
}

async function loadProducts() {
    showLoading();
    try {
        const res = await api.get('/products?page=1&pageSize=100');
        if (res.success) {
            allProducts = res.data || [];
            renderProductGrid(allProducts);
        }
    } catch (err) {
        showToast('Lỗi tải sản phẩm: ' + err.message, 'error');
    } finally {
        hideLoading();
    }
}

function filterProducts() {
    const keyword = document.getElementById('posSearchInput').value.trim().toLowerCase();
    const catId = document.getElementById('posCategoryFilter').value;

    const filtered = allProducts.filter(p => {
        const matchName = (p.ProductName || '').toLowerCase().includes(keyword);
        const matchCode = (p.ProductCode || '').toLowerCase().includes(keyword);
        const matchBarcode = (p.Barcode || '').toLowerCase().includes(keyword);
        const matchCat = catId ? p.CategoryID == catId : true;
        return (matchName || matchCode || matchBarcode) && matchCat;
    });

    renderProductGrid(filtered);
}

function renderProductGrid(products) {
    const grid = document.getElementById('posProductGrid');
    if (!products || products.length === 0) {
        grid.innerHTML = `
            <div class="empty-state" style="grid-column: 1 / -1; padding: 40px;">
                <i class="fas fa-search" style="font-size: 2rem; opacity: 0.5;"></i>
                <p>Không tìm thấy sản phẩm nào phù hợp.</p>
            </div>
        `;
        return;
    }

    grid.innerHTML = products.map(p => {
        const isOutOfStock = (p.StockQuantity || 0) <= 0;
        return `
            <div class="product-card ${isOutOfStock ? 'out-of-stock' : ''}" onclick="addToCart(${p.ProductID})">
                <div class="p-name">${p.ProductName}</div>
                <div class="p-price">${formatCurrency(p.SellingPrice)}</div>
                <div class="p-stock">
                    <i class="fas fa-box"></i> Tồn: <strong>${p.StockQuantity || 0}</strong> ${p.Unit || 'Cái'}
                    ${isOutOfStock ? '<span style="color:var(--danger); margin-left:4px;">(Hết)</span>' : ''}
                </div>
            </div>
        `;
    }).join('');
}

// ================= Cart Operations ================= //
function addToCart(productId) {
    const product = allProducts.find(p => p.ProductID === productId);
    if (!product) return;

    if ((product.StockQuantity || 0) <= 0) {
        showToast(`Sản phẩm [${product.ProductName}] đã hết hàng!`, 'warning');
        return;
    }

    const existing = cart.find(item => item.productID === productId);
    if (existing) {
        if (existing.quantity + 1 > product.StockQuantity) {
            showToast(`Số lượng trong giỏ đã đạt tồn kho tối đa (${product.StockQuantity})!`, 'warning');
            return;
        }
        existing.quantity += 1;
    } else {
        cart.push({
            productID: product.ProductID,
            productCode: product.ProductCode,
            productName: product.ProductName,
            unit: product.Unit || 'Cái',
            unitPrice: product.SellingPrice,
            stockQuantity: product.StockQuantity,
            quantity: 1
        });
    }

    updateCartUI();
}

function updateItemQuantity(productId, newQty) {
    const item = cart.find(i => i.productID === productId);
    if (!item) return;

    let qty = parseInt(newQty);
    if (isNaN(qty) || qty <= 0) qty = 1;
    if (qty > item.stockQuantity) {
        showToast(`Tồn kho chỉ còn ${item.stockQuantity} sản phẩm!`, 'warning');
        qty = item.stockQuantity;
    }

    item.quantity = qty;
    updateCartUI();
}

function removeFromCart(productId) {
    cart = cart.filter(i => i.productID !== productId);
    updateCartUI();
}

function clearCart() {
    if (cart.length === 0) return;
    cart = [];
    currentCustomer = null;
    document.getElementById('customerPhoneInput').value = '';
    document.getElementById('customerInfoDisplay').innerHTML = '<i class="fas fa-user"></i> Khách hàng: <strong>Khách vãng lai</strong>';
    document.getElementById('discountInput').value = 0;
    updateCartUI();
}

function updateCartUI() {
    const container = document.getElementById('cartItemsContainer');
    document.getElementById('cartCount').innerText = cart.reduce((sum, item) => sum + item.quantity, 0);

    if (cart.length === 0) {
        container.innerHTML = `
            <div class="empty-state" style="padding: 40px 10px;">
                <i class="fas fa-cart-arrow-down" style="font-size: 2.5rem; opacity: 0.5;"></i>
                <p style="margin-top: 8px;">Giỏ hàng đang trống.<br>Nhấp vào sản phẩm để chọn mua.</p>
            </div>
        `;
        updateCartTotals();
        return;
    }

    container.innerHTML = cart.map(item => `
        <div class="pos-cart-item">
            <div class="item-name">
                <div style="font-weight: 500;">${item.productName}</div>
                <small style="color: var(--text-muted);">${formatCurrency(item.unitPrice)} / ${item.unit}</small>
            </div>
            <input type="number" class="item-qty" min="1" max="${item.stockQuantity}" value="${item.quantity}" 
                   onchange="updateItemQuantity(${item.productID}, this.value)">
            <div class="item-price">${formatCurrency(item.quantity * item.unitPrice)}</div>
            <button class="item-remove" onclick="removeFromCart(${item.productID})" title="Xóa">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `).join('');

    updateCartTotals();
}

function updateCartTotals() {
    const subtotal = cart.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);
    let discount = parseFloat(document.getElementById('discountInput').value) || 0;
    if (discount < 0) discount = 0;
    if (discount > subtotal) discount = subtotal;

    const total = subtotal - discount;

    document.getElementById('summarySubTotal').innerText = formatCurrency(subtotal);
    document.getElementById('summaryTotalAmount').innerText = formatCurrency(total);
}

// ================= Customer Lookup ================= //
async function lookupCustomer() {
    const phone = document.getElementById('customerPhoneInput').value.trim();
    if (!phone) {
        currentCustomer = null;
        document.getElementById('customerInfoDisplay').innerHTML = '<i class="fas fa-user"></i> Khách hàng: <strong>Khách vãng lai</strong>';
        return;
    }

    showLoading();
    try {
        const res = await api.get(`/customers/search?phone=${encodeURIComponent(phone)}`);
        if (res.success && res.data) {
            currentCustomer = res.data;
            document.getElementById('customerInfoDisplay').innerHTML = `
                <i class="fas fa-check-circle" style="color:var(--success);"></i> 
                <strong>${currentCustomer.FullName}</strong> (${currentCustomer.CustomerCode}) - Đã chi: ${formatCurrency(currentCustomer.TotalSpent)}
            `;
            showToast(`Tìm thấy khách hàng ${currentCustomer.FullName}!`);
        } else {
            currentCustomer = null;
            document.getElementById('customerInfoDisplay').innerHTML = `
                <span style="color:var(--warning);"><i class="fas fa-exclamation-circle"></i> Chưa đăng ký thành viên</span>
            `;
            showToast('Không tìm thấy khách hàng với số điện thoại này.', 'warning');
        }
    } catch (err) {
        showToast('Lỗi tra cứu: ' + err.message, 'error');
    } finally {
        hideLoading();
    }
}

// ================= Checkout Transaction ================= //
async function handleCheckout() {
    if (cart.length === 0) {
        showToast('Giỏ hàng trống! Hãy chọn ít nhất một sản phẩm.', 'warning');
        return;
    }

    const subtotal = cart.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);
    const discount = parseFloat(document.getElementById('discountInput').value) || 0;
    const paymentMethod = document.getElementById('paymentMethodSelect').value;
    const employeeId = (loggedUser && loggedUser.employeeID) ? loggedUser.employeeID : 3; // Default cashier fallback

    const itemsPayload = cart.map(item => ({
        productId: item.productID,
        quantity: item.quantity
    }));

    const btn = document.getElementById('btnCheckout');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> ĐANG XỬ LÝ GIAO DỊCH...';

    try {
        const res = await api.post('/invoices/checkout', {
            customerID: currentCustomer ? currentCustomer.CustomerID : null,
            employeeID: employeeId,
            paymentMethod: paymentMethod,
            discountAmount: discount,
            items: itemsPayload
        });

        if (res.success) {
            showToast('Giao dịch bán hàng thành công! Mã: ' + (res.data.InvoiceCode || ''));
            
            // Build receipt for printable modal
            showReceiptModal({
                invoiceCode: res.data.InvoiceCode,
                invoiceDate: new Date(),
                customerName: currentCustomer ? currentCustomer.FullName : 'Khách vãng lai',
                cashierName: loggedUser.fullName || loggedUser.username,
                paymentMethod: paymentMethod,
                items: [...cart],
                subTotal: subtotal,
                discount: discount,
                totalAmount: res.data.TotalAmount || (subtotal - discount)
            });

            // Reset cart
            clearCart();

            // Refresh products to get updated stock quantities from database
            await loadProducts();
        }
    } catch (err) {
        showToast('Giao dịch thất bại: ' + err.message, 'error');
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-check-circle"></i> THANH TOÁN (F9)';
    }
}

// ================= Receipt & Print ================= //
function showReceiptModal(data) {
    const area = document.getElementById('receiptPrintArea');
    area.innerHTML = `
        <div style="text-align: center; border-bottom: 1px dashed var(--border); padding-bottom: 12px; margin-bottom: 12px;">
            <h2 style="color: var(--accent); margin-bottom: 2px;">🏪 STORE MANAGER</h2>
            <p style="color: var(--text-muted); font-size: 0.75rem;">123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh</p>
            <p style="color: var(--text-muted); font-size: 0.75rem;">Hotline: 1900 1234</p>
        </div>

        <div style="margin-bottom: 12px; font-size: 0.8rem; line-height: 1.5;">
            <div><strong>Mã HĐ:</strong> ${data.invoiceCode}</div>
            <div><strong>Thời gian:</strong> ${formatDateTime(data.invoiceDate)}</div>
            <div><strong>Thu ngân:</strong> ${data.cashierName}</div>
            <div><strong>Khách hàng:</strong> ${data.customerName}</div>
            <div><strong>Thanh toán:</strong> ${data.paymentMethod}</div>
        </div>

        <table style="width: 100%; font-size: 0.8rem; margin-bottom: 12px; border-top: 1px dashed var(--border);">
            <thead>
                <tr style="border-bottom: 1px solid var(--border-light);">
                    <th style="padding: 6px 0; text-align: left;">Sản phẩm</th>
                    <th style="padding: 6px 0; text-align: center;">SL</th>
                    <th style="padding: 6px 0; text-align: right;">Đơn giá</th>
                    <th style="padding: 6px 0; text-align: right;">T.Tiền</th>
                </tr>
            </thead>
            <tbody>
                ${data.items.map(item => `
                    <tr>
                        <td style="padding: 6px 0;">${item.productName}</td>
                        <td style="padding: 6px 0; text-align: center;">${item.quantity}</td>
                        <td style="padding: 6px 0; text-align: right;">${formatCurrency(item.unitPrice)}</td>
                        <td style="padding: 6px 0; text-align: right; font-weight: 500;">${formatCurrency(item.quantity * item.unitPrice)}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>

        <div style="border-top: 1px dashed var(--border); padding-top: 8px; font-size: 0.85rem;">
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                <span>Cộng tiền hàng:</span>
                <span>${formatCurrency(data.subTotal)}</span>
            </div>
            ${data.discount > 0 ? `
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px; color: var(--warning);">
                <span>Chiết khấu:</span>
                <span>-${formatCurrency(data.discount)}</span>
            </div>` : ''}
            <div style="display: flex; justify-content: space-between; font-size: 1.1rem; font-weight: 700; color: var(--accent); margin-top: 6px; padding-top: 6px; border-top: 1px solid var(--border-light);">
                <span>THÀNH TIỀN:</span>
                <span>${formatCurrency(data.totalAmount)}</span>
            </div>
        </div>

        <div style="text-align: center; margin-top: 16px; font-size: 0.75rem; color: var(--text-muted);">
            <p>Cảm ơn Quý khách đã mua sắm!</p>
            <p>Hẹn gặp lại quý khách lần sau.</p>
        </div>
    `;

    openModal('receiptModal');
}

function printReceipt() {
    window.print();
}
