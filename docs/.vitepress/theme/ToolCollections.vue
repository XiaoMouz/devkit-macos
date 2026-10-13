<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from "vue";
import { useData, withBase } from "vitepress";
import DemoIcon from "./DemoIcon.vue";
import catalog from "../tool-catalog.json";
import { demoTools } from "./demo-tools.mjs";
import { searchTools } from "./tool-search.mjs";
const emit = defineEmits(["layout-change", "try-tool"]);
const { lang } = useData();
const en = computed(() => lang.value === "en");
const groups = [
  {
    name: "数据与转换",
    nameEn: "Data & conversion",
    tools: [...catalog[0].tools, ...catalog[1].tools],
  },
  ...catalog.slice(2),
];
const symbols = [
  "json",
  "hash",
  "uuid",
  "text-case",
  "timestamp",
  "network",
  "color",
  "image",
];
const selected = ref(0);
const query = ref("");
const searchInput = ref(null);
const demoIds = new Set(demoTools.map((tool) => tool.id));
const individualIcons = new Set([
  "json",
  "base64",
  "url-codec",
  "timestamp",
  "uuid",
  "text-case",
  "hash",
  "color",
]);
const toolIcon = (tool) =>
  individualIcons.has(tool.id) ? tool.id : symbols[tool.groupIndex];
const name = (item) => (en.value ? item.nameEn : item.name);
const allTools = groups.flatMap((group, groupIndex) =>
  group.tools.map((tool) => ({ ...tool, groupIndex })),
);
const results = computed(() => {
  const term = query.value.trim().toLowerCase();
  return term
    ? searchTools(allTools, query.value)
    : allTools.filter((tool) => tool.groupIndex === selected.value);
});
function choose(index) {
  selected.value = index;
  query.value = "";
}
function focusSearch(event) {
  if (
    event.key !== "/" ||
    event.metaKey ||
    event.ctrlKey ||
    event.altKey ||
    event.isComposing ||
    event.defaultPrevented
  )
    return;
  if (
    document.querySelector("dialog[open]") ||
    event.target?.closest?.("input, textarea, select, [contenteditable]")
  )
    return;
  event.preventDefault();
  searchInput.value?.focus();
}
function clearSearch() {
  query.value = "";
  searchInput.value?.focus();
}
onMounted(() => window.addEventListener("keydown", focusSearch));
onUnmounted(() => window.removeEventListener("keydown", focusSearch));
watch([results, en], async () => {
  await nextTick();
  emit("layout-change");
});
</script>
<template>
  <div class="tool-explorer">
    <div class="explorer-top">
      <div class="explorer-label">
        <DemoIcon name="grid" /><span>{{
          en ? "Find your next tool" : "找到你需要的工具"
        }}</span>
      </div>
      <label class="explorer-search"
        ><DemoIcon name="search" /><input
          ref="searchInput"
          v-model="query"
          type="search"
          :aria-label="en ? 'Search all 48 tools' : '搜索全部 48 个工具'"
          :placeholder="en ? 'Search by name or purpose' : '搜索名称或用途'"
        /><button
          v-if="query"
          type="button"
          class="search-clear"
          :aria-label="en ? 'Clear tool search' : '清空工具搜索'"
          @click="clearSearch"
        >
          ×</button
        ><kbd v-else aria-hidden="true">/</kbd></label
      >
    </div>
    <div
      class="tool-categories"
      :aria-label="en ? 'Tool categories' : '工具分类'"
    >
      <button
        v-for="(group, i) in groups"
        :key="group.name"
        type="button"
        :aria-pressed="!query.trim() && selected === i"
        @click="choose(i)"
      >
        <DemoIcon :name="symbols[i]" /><span>{{ name(group) }}</span>
      </button>
    </div>
    <div class="explorer-result-heading">
      <h3>
        {{
          query.trim()
            ? en
              ? "Search results"
              : "搜索结果"
            : name(groups[selected])
        }}
      </h3>
      <span role="status" aria-live="polite"
        >{{ results.length }} {{ en ? "tools" : "个工具" }}</span
      >
    </div>
    <div v-if="results.length" class="explorer-results">
      <div v-for="tool in results" :key="tool.id" class="explorer-row">
        <a :href="withBase(`${en ? '/en' : ''}/tools/${tool.id}.html`)">
          <span class="explorer-tool-icon"
            ><DemoIcon :name="toolIcon(tool)"
          /></span>
          <div>
            <h4>{{ name(tool) }}</h4>
            <p>{{ en ? tool.summaryEn : tool.summary }}</p>
          </div>
          <span
            v-if="!demoIds.has(tool.id)"
            class="explorer-open"
            aria-hidden="true"
            >↗</span
          >
        </a>
        <button
          v-if="demoIds.has(tool.id)"
          type="button"
          class="explorer-try"
          :aria-label="(en ? 'Try ' : '网页试用 ') + name(tool)"
          @click="emit('try-tool', tool.id)"
        >
          {{ en ? "Try" : "试用" }}<span aria-hidden="true">↗</span>
        </button>
      </div>
    </div>
    <div v-else class="explorer-empty">
      <p>{{ en ? "No tools match this search." : "没有找到匹配的工具。" }}</p>
      <button type="button" @click="query = ''">
        {{ en ? "Clear search" : "清空搜索" }}
      </button>
    </div>
  </div>
</template>
