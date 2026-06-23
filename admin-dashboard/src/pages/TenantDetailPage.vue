<script setup>
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import api from '../api'
import StatusBadge from '../components/StatusBadge.vue'

// :id comes from the route (props: true in the router).
const props = defineProps({ id: [String, Number] })

const tenant = ref(null)
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await api.get(`/admin/tenants/${props.id}`)
    tenant.value = data.data
  } catch (e) {
    error.value = e.response?.data?.message || 'Failed to load tenant.'
  } finally {
    loading.value = false
  }
}
onMounted(load)

async function suspend() {
  try {
    await api.post(`/admin/tenants/${props.id}/suspend`)
    tenant.value.status = 'suspended'
  } catch (e) {
    alert(e.response?.data?.message || 'Could not suspend tenant.')
  }
}
async function activate() {
  try {
    await api.post(`/admin/tenants/${props.id}/activate`)
    tenant.value.status = 'active'
  } catch (e) {
    alert(e.response?.data?.message || 'Could not activate tenant.')
  }
}

// "used / limit" where a null limit means unlimited.
function limitLabel(used, max) {
  return max === null || max === undefined ? `${used} / ∞` : `${used} / ${max}`
}
</script>

<template>
  <div v-if="loading" class="text-gray-500">Loading…</div>
  <div v-else-if="error" class="text-red-600 bg-red-50 border border-red-200 rounded-lg p-4">{{ error }}</div>

  <div v-else-if="tenant">
    <RouterLink :to="{ name: 'tenants' }" class="text-sm text-primary hover:underline">
      ← Back to tenants
    </RouterLink>
    <h1 class="text-2xl font-bold text-gray-800 mt-2 mb-6">{{ tenant.name }}</h1>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Tenant info -->
      <div class="bg-white rounded-xl shadow-sm border p-6 lg:col-span-2">
        <h2 class="font-semibold text-gray-700 mb-3">Tenant info</h2>
        <div class="grid grid-cols-2 gap-y-2 text-sm">
          <span class="text-gray-500">Slug</span><span>{{ tenant.slug }}</span>
          <span class="text-gray-500">Email</span><span>{{ tenant.email }}</span>
          <span class="text-gray-500">Plan</span><span>{{ tenant.plan?.name || '—' }}</span>
          <span class="text-gray-500">Status</span><span><StatusBadge :status="tenant.status" /></span>
        </div>
      </div>

      <!-- Actions -->
      <div class="bg-white rounded-xl shadow-sm border p-6">
        <h2 class="font-semibold text-gray-700 mb-3">Actions</h2>
        <button
          v-if="tenant.status !== 'suspended'"
          @click="suspend"
          class="w-full bg-red-600 text-white py-2 rounded-lg hover:bg-red-700"
        >
          Suspend tenant
        </button>
        <button
          v-else
          @click="activate"
          class="w-full bg-green-600 text-white py-2 rounded-lg hover:bg-green-700"
        >
          Activate tenant
        </button>
      </div>

      <!-- Usage vs limits -->
      <div class="bg-white rounded-xl shadow-sm border p-6">
        <h2 class="font-semibold text-gray-700 mb-3">Usage vs plan limits</h2>
        <div class="space-y-2 text-sm">
          <div class="flex justify-between">
            <span class="text-gray-500">Users</span>
            <span>{{ limitLabel(tenant.usage.user_count, tenant.plan?.max_users) }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-500">Projects</span>
            <span>{{ limitLabel(tenant.usage.project_count, tenant.plan?.max_projects) }}</span>
          </div>
        </div>
      </div>

      <!-- Stripe -->
      <div class="bg-white rounded-xl shadow-sm border p-6 lg:col-span-2">
        <h2 class="font-semibold text-gray-700 mb-3">Stripe subscription</h2>
        <div class="grid grid-cols-2 gap-y-2 text-sm">
          <span class="text-gray-500">Subscription ID</span>
          <span class="font-mono text-xs">{{ tenant.stripe.subscription_id || '—' }}</span>
          <span class="text-gray-500">Status</span><span>{{ tenant.stripe.status || '—' }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
