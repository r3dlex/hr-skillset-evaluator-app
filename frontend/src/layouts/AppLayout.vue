<script setup lang="ts">
import Sidebar from '@/components/Sidebar.vue'
</script>

<template>
  <div class="flex min-h-screen">
    <Sidebar />
    <main class="flex-1 ml-[260px] bg-[#f8f9fa] min-h-screen">
      <div class="p-8">
        <slot />
      </div>
    </main>
  </div>
</template>
