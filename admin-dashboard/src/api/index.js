import axios from 'axios'

/**
 * Single Axios instance for the whole admin panel.
 * baseURL comes from .env (VITE_API_URL), e.g. http://localhost:8000/api
 */
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: { Accept: 'application/json' },
})

// Attach the super admin JWT to every outgoing request (if we have one).
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// If the server says the token is invalid/expired (401), clear it and bounce to login.
// (We read/clear localStorage directly here to avoid importing the Pinia store — that
//  would create a circular import, since the store imports this file.)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_user')
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  },
)

export default api
