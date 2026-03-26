<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import ManagerDashboard from '@/views/ManagerDashboard.vue'
import UserDashboard from '@/views/UserDashboard.vue'

const authStore = useAuthStore()
</script>

<template>
  <ManagerDashboard v-if="authStore.isManager" />
  <UserDashboard v-else />
</template>
