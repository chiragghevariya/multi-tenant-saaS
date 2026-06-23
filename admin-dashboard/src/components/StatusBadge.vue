<script setup>
// Colored pill for a tenant status (active / trial / suspended).
defineProps({ status: String })

const styles = {
  active: 'bg-green-100 text-green-700',
  trial: 'bg-amber-100 text-amber-700',
  suspended: 'bg-red-100 text-red-700',
}
</script>

<template>
  <span
    class="inline-block px-2 py-0.5 rounded-full text-xs font-medium"
    :class="styles[status] || 'bg-gray-100 text-gray-600'"
  >
    {{ status }}
  </span>
</template>
