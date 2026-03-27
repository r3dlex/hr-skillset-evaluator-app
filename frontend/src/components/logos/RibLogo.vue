<script setup lang="ts">
withDefaults(defineProps<{
  color?: string
  size?: number
  showText?: boolean
}>(), {
  color: '#0166B1',
  size: 32,
  showText: true,
})
</script>

<template>
  <div class="flex items-center gap-2">
    <!-- RIB circular triskelion/pinwheel logo -->
    <svg
      :width="size"
      :height="size"
      :viewBox="'0 0 64 64'"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="32" cy="32" r="30" :fill="color" />
      <!-- Three curved blade/swoosh shapes forming a pinwheel -->
      <!-- Blade 1: top -->
      <path
        d="M32 12 C32 12 40 20 40 28 C40 32 36 34 32 32 C28 30 24 24 32 12Z"
        fill="white"
        opacity="0.95"
      />
      <!-- Blade 2: bottom-left -->
      <path
        d="M16 44 C16 44 16 34 22 28 C25 25 29 26 30 30 C31 34 26 40 16 44Z"
        fill="white"
        opacity="0.95"
      />
      <!-- Blade 3: bottom-right -->
      <path
        d="M48 44 C48 44 38 46 32 42 C29 40 29 36 32 34 C35 32 44 34 48 44Z"
        fill="white"
        opacity="0.95"
      />
      <!-- Center dot -->
      <circle cx="32" cy="32" r="4" fill="white" opacity="0.9" />
    </svg>

    <!-- "RIB" text -->
    <span
      v-if="showText"
      class="font-bold tracking-tight"
      :style="{ color, fontSize: `${size * 0.6}px`, lineHeight: 1 }"
    >
      RIB
    </span>
  </div>
</template>
