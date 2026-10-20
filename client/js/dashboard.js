// Dashboard Page Script
let chartInstance = null;

document.addEventListener('DOMContentLoaded', async () => {
    const user = await checkAuth();
    if (!user) return;
    initSidebar();

    await loadDashboardData();
});

async function loadDashboardData() {
    showLoading();
    try {
        const res = await api.get('/reports/dashboard');
        if (res.success && res.data) {
            const { kpis, revenueChart, topProducts } = res.data;

            // Render KPIs
            if (kpis) {
                document.getElementById('kpiTodayRevenue').innerText = formatCurrency(kpis.TodayRevenue || 0);
                document.getElementById('kpiTodayInvoices').innerText = (kpis.TodayInvoices || 0).toLocaleString('vi-VN');
                document.getElementById('kpiTotalProducts').innerText = (kpis.TotalProducts || 0).toLocaleString('vi-VN');
                document.getElementById('kpiLowStock').innerText = (kpis.LowStockCount || 0).toLocaleString('vi-VN');
            }

            // Render Revenue Chart
            renderChart(revenueChart || []);

            // Render Top Products Table
            renderTopProducts(topProducts || []);
        }
    } catch (err) {
        showToast('Không thể nạp dữ liệu thống kê: ' + err.message, 'error');
    } finally {
        hideLoading();
    }
}

function renderChart(data) {
    const ctx = document.getElementById('revenueChart').getContext('2d');
    
    // Sort chronologically if needed
    const sorted = [...data].sort((a, b) => new Date(a.SalesDate) - new Date(b.SalesDate));
    const labels = sorted.map(item => formatDate(item.SalesDate));
    const values = sorted.map(item => item.Revenue || 0);

    if (chartInstance) {
        chartInstance.destroy();
    }

    chartInstance = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels.length ? labels : ['Không có dữ liệu'],
            datasets: [{
                label: 'Doanh thu (VNĐ)',
                data: values.length ? values : [0],
                borderColor: '#0ea5e9',
                backgroundColor: 'rgba(14, 165, 233, 0.15)',
                borderWidth: 2.5,
                fill: true,
                tension: 0.35,
                pointBackgroundColor: '#0ea5e9',
                pointRadius: 4,
                pointHoverRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return 'Doanh thu: ' + formatCurrency(context.parsed.y);
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)'
                    },
                    ticks: {
                        color: '#94a3b8'
                    }
                },
                y: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)'
                    },
                    ticks: {
                        color: '#94a3b8',
                        callback: function(value) {
                            if (value >= 1000000) return (value / 1000000).toFixed(1) + 'M';
                            if (value >= 1000) return (value / 1000).toFixed(0) + 'k';
                            return value;
                        }
                    }
                }
            }
        }
    });
}

function renderTopProducts(products) {
    const tbody = document.getElementById('topProductsBody');
    if (!products || products.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 24px;">
                    Chưa có giao dịch bán hàng nào trong tháng.
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = products.map(p => `
        <tr>
            <td><code>${p.ProductCode}</code></td>
            <td style="font-weight: 500;">${p.ProductName}</td>
            <td>${p.Unit || 'Cái'}</td>
            <td style="font-weight: 600; color: var(--accent);">${p.TotalQuantitySold}</td>
            <td style="font-weight: 600;">${formatCurrency(p.TotalRevenue)}</td>
        </tr>
    `).join('');
}
