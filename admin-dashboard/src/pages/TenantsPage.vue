<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'
import StatusBadge from '../components/StatusBadge.vue'

const router = useRouter()
const tenants = ref([])
const loading = ref(true)
const error = ref('')

// Filters
const search = ref('')
const planFilter = ref('')
const statusFilter = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await api.get('/admin/tenants')
    tenants.value = data.data
  } catch (e) {
    error.value = e.response?.data?.message || 'Failed to load tenants.'
  } finally {
    loading.value = false
  }
}
onMounted(load)

// Unique plan names for the dropdown.
const plans = computed(() => [...new Set(tenants.value.map((t) => t.plan).filter(Boolean))])

// Apply search + plan + status filters.
const filtered = computed(() =>
  tenants.value.filter((t) => {
    const q = search.value.toLowerCase()
    const matchesSearch =
      !q ||
      t.name.toLowerCase().includes(q) ||
      t.slug.toLowerCase().includes(q) ||
      t.email.toLowerCase().includes(q)
    const matchesPlan = !planFilter.value || t.plan === planFilter.value
    const matchesStatus = !statusFilter.value || t.status === statusFilter.value
    return matchesSearch && matchesPlan && matchesStatus
  }),
)

async function suspend(t) {
  try {
    await api.post(`/admin/tenants/${t.id}/suspend`)
    t.status = 'suspended'
  } catch (e) {
    alert(e.response?.data?.message || 'Could not suspend tenant.')
  }
}
async function activate(t) {
  try {
    await api.post(`/admin/tenants/${t.id}/activate`)
    t.status = 'active'
  } catch (e) {
    alert(e.response?.data?.message || 'Could not activate tenant.')
  }
}
function view(t) {
  router.push({ name: 'tenant-detail', params: { id: t.id } })
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-800 mb-6">Tenants</h1>

    <!-- Filters -->
    <div class="flex flex-wrap gap-3 mb-4">
      <input
        v-model="search"
        placeholder="Search name, slug, email…"
        class="border rounded-lg px-3 py-2 flex-1 min-w-[200px]"
      />
      <select v-model="planFilter" class="border rounded-lg px-3 py-2">
        <option value="">All plans</option>
        <option v-for="p in plans" :key="p" :value="p">{{ p }}</option>
      </select>
      <select v-model="statusFilter" class="border rounded-lg px-3 py-2">
        <option value="">All statuses</option>
        <option value="active">Active</option>
        <option value="trial">Trial</option>
        <option value="suspended">Suspended</option>
      </select>
    </div>

    <div v-if="error" class="mb-4 text-red-600 bg-red-50 border border-red-200 rounded-lg p-3">{{ error }}</div>

    <!-- Table -->
    <div class="bg-white rounded-xl shadow-sm border overflow-hidden">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 text-left text-gray-500">
          <tr>
            <th class="px-4 py-3">Name</th>
            <th>Plan</th>
            <th>Status</th>
            <th>Users</th>
            <th>Created</th>
            <th class="text-right px-4">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="6" class="px-4 py-6 text-gray-400">Loading…</td>
          </tr>
          <tr v-else-if="!filtered.length">
            <td colspan="6" class="px-4 py-6 text-gray-400">No tenants found.</td>
          </tr>
          <tr v-for="t in filtered" :key="t.id" class="border-t hover:bg-gray-50">
            <td class="px-4 py-3">
              <div class="font-medium text-gray-800">{{ t.name }}</div>
              <div class="text-xs text-gray-400">{{ t.slug }}</div>
            </td>
            <td>{{ t.plan || '—' }}</td>
            <td><StatusBadge :status="t.status" /></td>
            <td>{{ t.user_count }}</td>
            <td class="text-gray-500">{{ t.created_at }}</td>
            <td class="px-4 text-right space-x-3 whitespace-nowrap">
              <button @click="view(t)" class="text-primary hover:underline">View</button>
              <button v-if="t.status !== 'suspended'" @click="suspend(t)" class="text-red-600 hover:underline">
                Suspend
              </button>
              <button v-else @click="activate(t)" class="text-green-600 hover:underline">Activate</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
