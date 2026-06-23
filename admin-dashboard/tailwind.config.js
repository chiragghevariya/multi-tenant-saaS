/** @type {import('tailwindcss').Config} */
export default {
  // Files Tailwind scans for class names.
  content: ['./index.html', './src/**/*.{vue,js}'],
  theme: {
    extend: {
      colors: {
        // Primary brand color (indigo) used across the admin panel.
        primary: {
          DEFAULT: '#4F46E5', // indigo-600
          dark: '#4338CA', // indigo-700
          light: '#6366F1', // indigo-500
        },
      },
    },
  },
  plugins: [],
}
