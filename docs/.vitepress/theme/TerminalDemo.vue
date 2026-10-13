<script setup>
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useData } from "vitepress";
import { terminalExamples as examples } from "./terminal-examples.mjs";
const { lang } = useData();
const en = computed(() => lang.value === "en");
const t = (zh, english) => (en.value ? english : zh);
const element = ref(null);
const playback = ref(null);
const current = ref(0);
const typed = ref(examples[0].command.length);
const phase = ref("idle");
const outputVisible = ref(true);
const paused = ref(false);
const ready = ref(false);
const reduced = ref(false);
const visited = ref([]);
const announcement = ref("");
const progress = ref(0);
const progressTrack = ref(null);
const example = computed(() => examples[current.value]);
let gsap,
  timeline,
  setProgress,
  observer,
  media,
  inView = false,
  autoStarted = false,
  disposed = false;

function syncPlayback() {
  if (!timeline || reduced.value) return;
  if (inView && !document.hidden && !paused.value) timeline.resume();
  else timeline.pause();
}
function showComplete(index) {
  timeline?.kill();
  current.value = index;
  typed.value = examples[index].command.length;
  outputVisible.value = true;
  phase.value = "complete";
  progress.value = 100;
  setProgress?.(1);
  paused.value = false;
  if (playback.value && gsap) gsap.set(playback.value, { opacity: 1, y: 0 });
}
function play(index = 0, sequential = true) {
  autoStarted = true;
  if (!gsap || reduced.value) {
    showComplete(index);
    return;
  }
  timeline?.kill();
  paused.value = false;
  visited.value = [];
  progress.value = 0;
  setProgress?.(0);
  const indices = sequential ? examples.map((_, i) => i).slice(index) : [index];
  current.value = index;
  typed.value = 0;
  outputVisible.value = false;
  phase.value = "typing";
  gsap.set(playback.value, { opacity: 1, y: 0 });
  timeline = gsap.timeline({
    paused: true,
    onUpdate: () => {
      const value = timeline?.progress() || 0;
      setProgress?.(value);
      progress.value = Math.floor(value * 20) * 5;
    },
    onComplete: () => {
      phase.value = "complete";
      progress.value = 100;
      setProgress?.(1);
    },
  });
  indices.forEach((exampleIndex, position) => {
    const recipe = examples[exampleIndex];
    const cursor = { value: 0 };
    timeline.call(() => {
      current.value = exampleIndex;
      typed.value = 0;
      outputVisible.value = false;
      phase.value = "typing";
      announcement.value =
        t("演示：", "Example: ") + (en.value ? recipe.en : recipe.zh);
    });
    if (position)
      timeline.fromTo(
        playback.value,
        { opacity: 0, y: 10 },
        { opacity: 1, y: 0, duration: 0.25, immediateRender: false },
      );
    timeline
      .to(cursor, {
        value: recipe.command.length,
        duration: Math.max(1.4, recipe.command.length / 42),
        ease: "none",
        onUpdate: () => {
          typed.value = Math.floor(cursor.value);
        },
      })
      .call(() => {
        phase.value = "running";
      })
      .to({}, { duration: 0.45 })
      .call(() => {
        outputVisible.value = true;
        phase.value = "result";
        visited.value = [...visited.value, exampleIndex];
        announcement.value =
          (en.value ? recipe.en : recipe.zh) + t("，已完成。", ", complete.");
      })
      .to({}, { duration: 1.8 });
    if (position < indices.length - 1)
      timeline.to(playback.value, { opacity: 0, y: -10, duration: 0.25 });
  });
  syncPlayback();
}
function toggle() {
  if (phase.value === "complete" || phase.value === "idle") {
    play();
    return;
  }
  paused.value = !paused.value;
  syncPlayback();
}
function motionChanged(event) {
  reduced.value = event.matches;
  if (reduced.value) showComplete(current.value);
}
onMounted(async () => {
  const module = await import("gsap");
  if (disposed) return;
  gsap = module.gsap;
  setProgress = gsap.quickSetter(progressTrack.value, "scaleX");
  media = window.matchMedia("(prefers-reduced-motion: reduce)");
  reduced.value = media.matches;
  media.addEventListener("change", motionChanged);
  document.addEventListener("visibilitychange", syncPlayback);
  ready.value = true;
  observer = new IntersectionObserver(
    (entries) => {
      inView =
        entries[0].isIntersecting && entries[0].intersectionRatio >= 0.35;
      if (inView && !autoStarted && !reduced.value) play();
      else syncPlayback();
    },
    { threshold: [0, 0.35] },
  );
  observer.observe(element.value);
});
onUnmounted(() => {
  disposed = true;
  timeline?.kill();
  observer?.disconnect();
  media?.removeEventListener("change", motionChanged);
  document.removeEventListener("visibilitychange", syncPlayback);
});
</script>
<template>
  <div
    ref="element"
    class="terminal-demo"
    role="region"
    :aria-label="t('CLI 命令演示', 'CLI command demo')"
  >
    <div class="terminal-top" aria-hidden="true">
      <span class="terminal-lights"><i /><i /><i /></span>
    </div>
    <div class="terminal-screen">
      <div ref="playback" class="terminal-playback">
        <div class="terminal-example-title">
          {{ en ? example.en : example.zh }}
        </div>
        <div class="terminal-command">
          <span class="terminal-prompt" aria-hidden="true">❯</span>
          <pre>{{ example.command.slice(0, typed) }}<span v-if="phase === 'typing'" class="terminal-caret" :class="{ 'is-paused': paused }" aria-hidden="true"/></pre>
        </div>
        <div
          v-if="phase === 'running'"
          class="terminal-running"
          aria-hidden="true"
        >
          •••
        </div>
        <pre v-if="outputVisible" class="terminal-output">{{
          example.output
        }}</pre>
        <div v-if="outputVisible" class="terminal-return" aria-hidden="true">
          <span>❯</span><i />
        </div>
      </div>
    </div>
    <div
      v-show="!reduced"
      class="terminal-progress"
      role="progressbar"
      :aria-label="t('命令演示进度', 'Command demo progress')"
      :aria-valuenow="progress"
      :aria-valuemin="0"
      :aria-valuemax="100"
    >
      <i ref="progressTrack" />
    </div>
    <div v-if="ready" class="terminal-controls">
      <div
        class="terminal-steps"
        :aria-label="t('选择命令示例', 'Choose a command example')"
      >
        <button
          v-for="(item, i) in examples"
          :key="item.id"
          type="button"
          :aria-pressed="current === i"
          @click="play(i, false)"
        >
          <span
            class="terminal-step-dot"
            :class="{ done: visited.includes(i) }"
            aria-hidden="true"
          />{{ item.label }}
        </button>
      </div>
      <div class="terminal-transport">
        <button
          v-if="!reduced && phase !== 'complete' && phase !== 'idle'"
          type="button"
          @click="toggle"
        >
          {{ paused ? t("继续", "Resume") : t("暂停", "Pause") }}</button
        ><button type="button" @click="play()">
          <span aria-hidden="true">↺</span
          >{{ reduced ? t("重置", "Reset") : t("重播", "Replay") }}
        </button>
      </div>
    </div>
    <p class="terminal-announcement" role="status" aria-live="polite">
      {{ announcement }}
    </p>
  </div>
</template>
