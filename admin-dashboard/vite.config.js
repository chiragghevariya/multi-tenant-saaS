import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Vite config for the Vue 3 super-admin dashboard.
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173, // dev server runs at http://localhost:5173
  },
})
