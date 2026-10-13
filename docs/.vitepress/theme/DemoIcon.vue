<script setup>
defineProps({ name: String });
const paths = {
  hash: "M9 3 7 21M17 3l-2 18M3 9h18M2 15h18",
  network:
    "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0M3 12h18M12 3c5 5 5 13 0 18-5-5-5-13 0-18",
  color: "M12 3C8 8 5 12 5 15a7 7 0 0 0 14 0c0-3-3-7-7-12Z",
  image: "M3 3h18v18H3ZM3 16l5-5 4 4 3-3 6 6M17 7h.01",
  json: "M8 3H6a2 2 0 0 0-2 2v4a3 3 0 0 1-2 3 3 3 0 0 1 2 3v4a2 2 0 0 0 2 2h2m8-18h2a2 2 0 0 1 2 2v4a3 3 0 0 0 2 3 3 3 0 0 0-2 3v4a2 2 0 0 1-2 2h-2",
  base64: "M4 7h16m-4-4 4 4-4 4M20 17H4m4-4-4 4 4 4",
  "url-codec":
    "m10 13 4-4m-7 6-1 1a4 4 0 0 0 6 6l3-3a4 4 0 0 0 0-6m2-4 1-1a4 4 0 0 0-6-6L9 5a4 4 0 0 0 0 6",
  timestamp: "M12 8v5H8m14-1a10 10 0 1 1-20 0 10 10 0 0 1 20 0",
  uuid: "m12 2 2.5 7.5L22 12l-7.5 2.5L12 22l-2.5-7.5L2 12l7.5-2.5Z",
  "text-case": "m2 18 5-12 5 12M4 14h6m6-3h4v7h-4a3 3 0 0 1 0-6h4",
  search: "m16 16 5 5M18 10A8 8 0 1 1 2 10a8 8 0 0 1 16 0",
  copy: "M8 8h13v13H8ZM16 8V3H3v13h5",
  clear: "M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7",
  star: "m12 2 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1Z",
  split: "M3 4h18v16H3ZM12 4v16",
  input: "M12 5H3v16h16v-9M9 15l2-6 9-8 3 3-9 9Z",
  result: "M5 3h9l5 5v13H5ZM14 3v6h5M8 13h8m-8 4h8",
  chevron: "m6 9 6 6 6-6",
  arrow: "M5 12h14m-5-5 5 5-5 5",
  download: "M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5",
  terminal: "m4 5 6 7-6 7m9 0h7",
  moon: "M20 15A9 9 0 0 1 9 4a9 9 0 1 0 11 11Z",
  sun: "M12 1v3m0 16v3M1 12h3m16 0h3M4 4l2 2m12 12 2 2M4 20l2-2M18 6l2-2M17 12a5 5 0 1 1-10 0 5 5 0 0 1 10 0",
  grid: "M3 3h7v7H3ZM14 3h7v7h-7ZM3 14h7v7H3ZM14 14h7v7h-7Z",
  check: "m4 12 5 5L20 6",
};
</script>
<template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.6"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <path :d="paths[name] || paths.grid" />
  </svg>
</template>
