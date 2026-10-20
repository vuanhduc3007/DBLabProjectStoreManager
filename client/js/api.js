const API_BASE = 'http://localhost:3000/api';

const api = {
    async request(endpoint, options = {}) {
        const url = `${API_BASE}${endpoint}`;
        const config = {
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            ...options
        };
        const response = await fetch(url, config);
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Yêu cầu thất bại');
        return data;
    },
    get: (endpoint) => api.request(endpoint),
    post: (endpoint, body) => api.request(endpoint, { method: 'POST', body: JSON.stringify(body) }),
    put: (endpoint, body) => api.request(endpoint, { method: 'PUT', body: JSON.stringify(body) }),
    delete: (endpoint) => api.request(endpoint, { method: 'DELETE' })
};
