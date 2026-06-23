import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

// Boot the Vue app: state (Pinia) + routing (Vue Router).
const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
