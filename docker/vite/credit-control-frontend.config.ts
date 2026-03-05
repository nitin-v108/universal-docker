/**
 * Docker-only Vite config – mounted over vite.config when running in docker-compose.
 * Keeps project source unchanged; this file lives in docker/vite/ (env repo).
 */
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  server: {
    host: '0.0.0.0',
    port: 5173,
    allowedHosts: ['dev-cc.integra-paybill2.co.uk'],
  },
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          react: ['react', 'react-dom'],
          ui: ['react-bootstrap', 'bootstrap'],
        },
      },
    },
  },
})
