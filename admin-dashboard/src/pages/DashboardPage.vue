<script setup>
import { onMounted, ref } from 'vue'
import api from '../api'
import StatCard from '../components/StatCard.vue'
import StatusBadge from '../components/StatusBadge.vue'
import SignupsChart from '../components/SignupsChart.vue'

const stats = ref(null)
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    const { data } = await api.get('/admin/stats')
    stats.value = data.data
  } catch (e) {
    error.value = e.response?.data?.message || 'Failed to load the dashboard.'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-800 mb-6">Dashboard</h1>

    <div v-if="loading" class="text-gray-500">Loading…</div>
    <div v-else-if="error" class="text-red-600 bg-red-50 border border-red-200 rounded-lg p-4">{{ error }}</div>

    <template v-else>
      <!-- Stat cards -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard label="Total Tenants" :value="stats.total_tenants" />
        <StatCard label="Active Subscriptions" :value="stats.active_subscriptions" />
        <StatCard label="MRR" :value="`$${stats.mrr}`" accent="text-green-600" />
        <StatCard label="New This Month" :value="stats.new_this_month" />
      </div>

      <!-- Signups line chart -->
      <div class="bg-white rounded-xl shadow-sm border p-6 mb-8">
        <h2 class="font-semibold text-gray-700 mb-4">Tenant signups (last 6 months)</h2>
        <SignupsChart :data="stats.signups_per_month" />
      </div>

      <!-- Recent tenants -->
      <div class="bg-white rounded-xl shadow-sm border p-6">
        <h2 class="font-semibold text-gray-700 mb-4">Recent tenants</h2>
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-gray-500 border-b">
              <th class="py-2">Name</th>
              <th>Plan</th>
              <th>Status</th>
              <th>Created</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="t in stats.recent_tenants" :key="t.id" class="border-b last:border-0">
              <td class="py-2 font-medium text-gray-800">{{ t.name }}</td>
              <td>{{ t.plan || '—' }}</td>
              <td><StatusBadge :status="t.status" /></td>
              <td class="text-gray-500">{{ t.created_at }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>
