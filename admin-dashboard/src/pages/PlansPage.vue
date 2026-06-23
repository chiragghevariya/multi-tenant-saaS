<script setup>
import { onMounted, ref } from 'vue'
import api from '../api'

const plans = ref([])
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    const { data } = await api.get('/admin/plans')
    plans.value = data.data
  } catch (e) {
    error.value = e.response?.data?.message || 'Failed to load plans.'
  } finally {
    loading.value = false
  }
})

// price is stored in cents; show whole dollars.
function price(cents) {
  return `$${(cents / 100).toFixed(0)}`
}
// null limit = unlimited.
function limit(v) {
  return v === null || v === undefined ? 'Unlimited' : v
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-800 mb-6">Plans</h1>

    <div v-if="loading" class="text-gray-500">Loading…</div>
    <div v-else-if="error" class="text-red-600 bg-red-50 border border-red-200 rounded-lg p-4">{{ error }}</div>

    <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div v-for="p in plans" :key="p.id" class="bg-white rounded-xl shadow-sm border p-6">
        <h2 class="text-lg font-semibold text-gray-800">{{ p.name }}</h2>
        <div class="mt-2 text-3xl font-bold text-primary">
          {{ price(p.price) }}<span class="text-sm font-normal text-gray-400">/mo</span>
        </div>

        <ul class="mt-4 space-y-1 text-sm text-gray-600">
          <li>👤 Users: <strong>{{ limit(p.max_users) }}</strong></li>
          <li>📁 Projects: <strong>{{ limit(p.max_projects) }}</strong></li>
          <li v-for="(val, key) in (p.features || {})" :key="key">
            <span :class="val ? 'text-green-600' : 'text-gray-300'">{{ val ? '✓' : '✗' }}</span>
            {{ key.replace(/_/g, ' ') }}
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
