// Auth module
async function checkAuth() {
    try {
        const result = await api.get('/auth/me');
        if (result.success) {
            sessionStorage.setItem('user', JSON.stringify(result.data));
            return result.data;
        }
    } catch {
        window.location.href = '/pages/login.html';
    }
    return null;
}

async function logout() {
    try {
        await api.post('/auth/logout');
    } catch {}
    sessionStorage.removeItem('user');
    window.location.href = '/pages/login.html';
}

function getCurrentUser() {
    const str = sessionStorage.getItem('user');
    return str ? JSON.parse(str) : null;
}
