<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { RadarData } from '@/types'

const props = withDefaults(defineProps<{
  radarData: RadarData
  size?: number
}>(), {
  size: 500,
})

const animated = ref(false)
const tooltip = ref<{ visible: boolean; x: number; y: number; text: string }>({
  visible: false,
  x: 0,
  y: 0,
  text: '',
})

const padding = 60
const viewBoxSize = computed(() => props.size + padding * 2)
const center = computed(() => viewBoxSize.value / 2)
const radius = computed(() => props.size * 0.35)
const levels = 5
const labelOffset = 28

onMounted(() => {
  requestAnimationFrame(() => {
    animated.value = true
  })
})

function angleFor(index: number): number {
  const total = props.radarData.axes.length
  return (Math.PI * 2 * index) / total - Math.PI / 2
}

function pointAt(angle: number, r: number): { x: number; y: number } {
  return {
    x: center.value + Math.cos(angle) * r,
    y: center.value + Math.sin(angle) * r,
  }
}

function levelPolygon(level: number): string {
  const r = (radius.value * level) / levels
  return props.radarData.axes
    .map((_, i) => {
      const pt = pointAt(angleFor(i), r)
      return `${pt.x},${pt.y}`
    })
    .join(' ')
}

function seriesPolygon(values: number[]): string {
  return values
    .map((val, i) => {
      const r = animated.value ? (radius.value * val) / levels : 0
      const pt = pointAt(angleFor(i), r)
      return `${pt.x},${pt.y}`
    })
    .join(' ')
}

function axisEndpoint(index: number): { x: number; y: number } {
  return pointAt(angleFor(index), radius.value)
}

function labelPosition(index: number): { x: number; y: number; anchor: string } {
  const pt = pointAt(angleFor(index), radius.value + labelOffset)
  const angle = angleFor(index)
  let anchor = 'middle'
  if (Math.cos(angle) > 0.1) anchor = 'start'
  else if (Math.cos(angle) < -0.1) anchor = 'end'
  return { ...pt, anchor }
}

function handlePointHover(event: MouseEvent, seriesName: string, axisIndex: number, value: number) {
  const axisName = props.radarData.axes[axisIndex]
  tooltip.value = {
    visible: true,
    x: event.offsetX,
    y: event.offsetY - 10,
    text: `${seriesName}: ${axisName} = ${value}`,
  }
}

function hideTooltip() {
  tooltip.value.visible = false
}
</script>

<template>
  <div class="relative inline-block">
    <svg
      :width="size"
      :height="size"
      :viewBox="`0 0 ${viewBoxSize} ${viewBoxSize}`"
      class="select-none"
      style="overflow: visible;"
    >
      <!-- Level polygons -->
      <polygon
        v-for="level in levels"
        :key="`level-${level}`"
        :points="levelPolygon(level)"
        fill="none"
        :stroke="'var(--color-border)'"
        stroke-width="1"
      />

      <!-- Axis lines -->
      <line
        v-for="(_, i) in radarData.axes"
        :key="`axis-${i}`"
        :x1="center"
        :y1="center"
        :x2="axisEndpoint(i).x"
        :y2="axisEndpoint(i).y"
        :stroke="'var(--color-border)'"
        stroke-width="1"
      />

      <!-- Series polygons -->
      <g v-for="series in radarData.series" :key="`series-${series.user_id}`">
        <polygon
          :points="seriesPolygon(series.values)"
          :fill="series.color"
          fill-opacity="0.15"
          :stroke="series.color"
          stroke-width="2"
          class="transition-all duration-300 ease-out"
        />
        <!-- Data points -->
        <circle
          v-for="(val, i) in series.values"
          :key="`point-${series.user_id}-${i}`"
          :cx="pointAt(angleFor(i), animated ? (radius * val) / levels : 0).x"
          :cy="pointAt(angleFor(i), animated ? (radius * val) / levels : 0).y"
          r="4"
          :fill="series.color"
          :stroke="'var(--color-surface)'"
          stroke-width="2"
          class="cursor-pointer transition-all duration-300 ease-out"
          @mouseenter="handlePointHover($event, series.name, i, val)"
          @mouseleave="hideTooltip"
        />
      </g>

      <!-- Axis labels -->
      <text
        v-for="(axis, i) in radarData.axes"
        :key="`label-${i}`"
        :x="labelPosition(i).x"
        :y="labelPosition(i).y"
        :text-anchor="labelPosition(i).anchor"
        dominant-baseline="middle"
        :fill="'var(--color-text-secondary)'"
        :font-family="'var(--font-family)'"
        font-size="13"
        font-weight="500"
      >
        {{ axis }}
      </text>

      <!-- Level labels -->
      <text
        v-for="level in levels"
        :key="`lvl-label-${level}`"
        :x="center + 4"
        :y="center - (radius * level) / levels - 4"
        :fill="'var(--color-text-muted)'"
        :font-family="'var(--font-family)'"
        font-size="9"
      >
        {{ level }}
      </text>
    </svg>

    <!-- Tooltip -->
    <div
      v-if="tooltip.visible"
      class="absolute pointer-events-none text-white text-xs px-3 py-1.5 rounded-lg shadow-lg whitespace-nowrap z-10"
      :style="{
        left: `${tooltip.x}px`,
        top: `${tooltip.y}px`,
        transform: 'translate(-50%, -100%)',
        backgroundColor: 'var(--color-text-primary)',
      }"
    >
      {{ tooltip.text }}
    </div>
  </div>
</template>
