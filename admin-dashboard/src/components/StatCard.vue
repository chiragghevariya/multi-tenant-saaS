<script setup>
// A small dashboard metric card.
defineProps({
  label: String,
  value: [String, Number],
  accent: { type: String, default: 'text-primary' }, // tailwind text-color class
})
</script>

<template>
  <div class="bg-white rounded-xl shadow-sm border p-5">
    <div class="text-sm text-gray-500">{{ label }}</div>
    <div class="mt-2 text-3xl font-bold" :class="accent">{{ value }}</div>
  </div>
</template>
