import { defineStore } from 'pinia'
import api from '../api'

/**
 * Super admin authentication state.
 * The token is persisted to localStorage so a page refresh keeps you logged in.
 */
export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('admin_token') || null,
    user: JSON.parse(localStorage.getItem('admin_user') || 'null'),
  }),

  getters: {
    isLoggedIn: (state) => !!state.token,
  },

  actions: {
    // Log in with the super admin credentials (from the Laravel .env).
    async login(email, password) {
      const { data } = await api.post('/admin/login', { email, password })
      this.token = data.access_token
      this.user = data.user
      localStorage.setItem('admin_token', this.token)
      localStorage.setItem('admin_user', JSON.stringify(this.user))
    },

    // Log out (best-effort server call, then clear local state).
    async logout() {
      try {
        await api.post('/admin/logout')
      } catch {
        // ignore network/token errors on logout
      }
      this.clear()
    },

    clear() {
      this.token = null
      this.user = null
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_user')
    },
  },
})
