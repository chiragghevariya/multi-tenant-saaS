<script setup>
// The shell around every authenticated page: sidebar nav + logout + content area.
import { RouterLink, RouterView, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()

const nav = [
  { name: 'dashboard', label: 'Dashboard', icon: '▦' },
  { name: 'tenants', label: 'Tenants', icon: '🏢' },
  { name: 'plans', label: 'Plans', icon: '🏷️' },
]

async function logout() {
  await auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <div class="min-h-screen flex bg-gray-50">
    <!-- Sidebar -->
    <aside class="w-64 bg-white border-r flex flex-col">
      <div class="h-16 flex items-center px-6 text-xl font-bold text-primary">SaaS Admin</div>

      <nav class="flex-1 px-3 space-y-1">
        <RouterLink
          v-for="item in nav"
          :key="item.name"
          :to="{ name: item.name }"
          class="flex items-center gap-3 px-3 py-2 rounded-lg text-gray-700 hover:bg-gray-100"
          active-class="bg-primary/10 text-primary font-medium"
        >
          <span>{{ item.icon }}</span> {{ item.label }}
        </RouterLink>
      </nav>

      <div class="p-3 border-t">
        <div class="px-3 py-2 text-sm text-gray-500 truncate">{{ auth.user?.email }}</div>
        <button
          @click="logout"
          class="w-full text-left px-3 py-2 rounded-lg text-red-600 hover:bg-red-50"
        >
          Logout
        </button>
      </div>
    </aside>

    <!-- Page content -->
    <main class="flex-1 overflow-auto">
      <div class="max-w-6xl mx-auto p-8">
        <RouterView />
      </div>
    </main>
  </div>
</template>
