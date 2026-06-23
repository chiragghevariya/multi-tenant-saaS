import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

import AdminLayout from '../layouts/AdminLayout.vue'
import LoginPage from '../pages/LoginPage.vue'
import DashboardPage from '../pages/DashboardPage.vue'
import TenantsPage from '../pages/TenantsPage.vue'
import TenantDetailPage from '../pages/TenantDetailPage.vue'
import PlansPage from '../pages/PlansPage.vue'

// Named routes. The protected pages live inside the AdminLayout (sidebar shell).
const routes = [
  { path: '/login', name: 'login', component: LoginPage, meta: { public: true } },
  {
    path: '/',
    component: AdminLayout,
    children: [
      { path: '', redirect: { name: 'dashboard' } },
      { path: 'dashboard', name: 'dashboard', component: DashboardPage },
      { path: 'tenants', name: 'tenants', component: TenantsPage },
      // props: true -> the :id is passed to the page as a prop.
      { path: 'tenants/:id', name: 'tenant-detail', component: TenantDetailPage, props: true },
      { path: 'plans', name: 'plans', component: PlansPage },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Auth guard: block protected pages when not logged in; skip login when already in.
router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isLoggedIn) {
    return { name: 'login' }
  }
  if (to.name === 'login' && auth.isLoggedIn) {
    return { name: 'dashboard' }
  }
})

export default router
