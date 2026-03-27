<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ManagerDashboard from '@/views/ManagerDashboard.vue'
import UserDashboard from '@/views/UserDashboard.vue'
import { useScreenContext } from '@/composables/useScreenContext'

const authStore = useAuthStore()
const { setScreenContext } = useScreenContext()

onMounted(() => {
  setScreenContext({ screen: 'dashboard' })
})
</script>

<template>
  <ManagerDashboard v-if="authStore.isManager" />
  <UserDashboard v-else />
</template>
