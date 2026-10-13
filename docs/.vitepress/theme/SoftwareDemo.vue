<script setup>
import { computed, ref } from "vue";
import { useData, withBase } from "vitepress";
import DemoIcon from "./DemoIcon.vue";
import "./software-demo.css";
import { demoTools, runDemo, jsonTokens } from "./demo-tools.mjs";
const props = defineProps({ darkInitially: Boolean });
const { lang } = useData();
const en = computed(() => lang.value === "en");
const t = (zh, english) => (en.value ? english : zh);
const link = (path) => withBase(`${en.value ? "/en" : ""}${path}`);
const active = ref("json");
const inputElement = ref(null);
const runButton = ref(null);
const query = ref("");
const layout = ref("split");
const dark = ref(props.darkInitially);
const copied = ref(false);
const copyFailed = ref(false);
const favorites = ref(["json", "timestamp", "uuid"]);
const sessions = ref(
  Object.fromEntries(
    demoTools.map((tool) => [
      tool.id,
      {
        input: tool.sample,
        operation: tool.operations[0][0],
        result:
          tool.id === "json" ? runDemo("json", tool.sample, "format") : "",
        error: false,
        stale: false,
        ran: tool.id === "json",
      },
    ]),
  ),
);
const tool = computed(() => demoTools.find((tool) => tool.id === active.value));
const session = computed(() => sessions.value[active.value]);
const groups = computed(() =>
  [
    {
      title: t("收藏", "Favorites"),
      items: demoTools.filter((tool) => favorites.value.includes(tool.id)),
    },
    {
      title: t("编码与转换", "Encoding"),
      items: demoTools.filter((tool) => tool.group === 1),
    },
    {
      title: t("文本与匹配", "Text"),
      items: demoTools.filter((tool) => tool.group === 2),
    },
    {
      title: t("更多演示", "More demos"),
      items: demoTools.filter(
        (tool) => tool.group === 0 && !favorites.value.includes(tool.id),
      ),
    },
  ]
    .map((group) => ({
      ...group,
      items: group.items.filter((tool) =>
        `${tool.zh} ${tool.en}`
          .toLowerCase()
          .includes(query.value.toLowerCase()),
      ),
    }))
    .filter((group) => group.items.length),
);
const resultText = computed(() =>
  session.value.error
    ? t(
        "输入格式不正确。检查内容和所选操作后重试。",
        "Invalid input. Check the content and selected operation, then try again.",
      )
    : session.value.result === "valid-json"
      ? t("JSON 语法校验通过。", "JSON syntax is valid.")
      : session.value.result,
);
const highlighted = computed(() =>
  active.value === "json" &&
  !session.value.error &&
  session.value.operation !== "validate"
    ? jsonTokens(resultText.value)
    : [{ value: resultText.value, type: "plain" }],
);
function changed() {
  session.value.stale = session.value.ran;
  copied.value = false;
  copyFailed.value = false;
}
function run() {
  try {
    session.value.result = runDemo(
      active.value,
      session.value.input,
      session.value.operation,
    );
    session.value.error = false;
  } catch {
    session.value.result = "";
    session.value.error = true;
  }
  session.value.ran = true;
  session.value.stale = false;
  copied.value = false;
  copyFailed.value = false;
}
function select(id) {
  active.value = id;
  copied.value = false;
  copyFailed.value = false;
}
function sample() {
  session.value.input = tool.value.sample;
  session.value.operation = tool.value.operations[0][0];
  run();
}
function favorite() {
  favorites.value = favorites.value.includes(active.value)
    ? favorites.value.filter((id) => id !== active.value)
    : [...favorites.value, active.value];
}
async function copy() {
  try {
    await navigator.clipboard.writeText(resultText.value);
    copied.value = true;
    copyFailed.value = false;
  } catch {
    copyFailed.value = true;
  }
}
function focusInput() {
  (inputElement.value || runButton.value)?.focus({ preventScroll: true });
}
defineExpose({ select, focusInput });
</script>

<template>
  <div
    class="software-demo"
    :class="{ 'demo-dark': dark }"
    :aria-label="t('DevKit 交互演示', 'Interactive DevKit demo')"
  >
    <aside class="software-sidebar">
      <div class="software-window-bar">
        <span class="traffic-lights" aria-hidden="true"><i /><i /><i /></span
        ><DemoIcon name="split" />
      </div>
      <label class="software-search"
        ><DemoIcon name="search" /><input
          v-model="query"
          :placeholder="t('搜索工具', 'Search tools')"
          :aria-label="t('搜索演示工具', 'Search demo tools')"
      /></label>
      <div class="software-tool-list">
        <section v-for="group in groups" :key="group.title">
          <h3>
            {{ group.title }} <span>{{ group.items.length }}</span>
          </h3>
          <button
            v-for="item in group.items"
            :key="item.id"
            type="button"
            :class="{ selected: active === item.id }"
            :aria-pressed="active === item.id"
            @click="select(item.id)"
          >
            <span class="native-tool-icon" :class="`icon-${item.id}`"
              ><DemoIcon :name="item.id" /></span
            ><span>{{ en ? item.en : item.zh }}</span>
          </button>
        </section>
        <p v-if="!groups.length" class="demo-no-match">
          {{ t("没有匹配的演示", "No matching demos") }}
        </p>
      </div>
      <div class="software-sidebar-bottom">
        <a :href="link('/tools/')"
          ><DemoIcon name="grid" />{{ t("48 个工具", "48 tools") }}</a
        ><button
          type="button"
          :aria-label="t('切换演示外观', 'Toggle demo appearance')"
          :aria-pressed="dark"
          @click="dark = !dark"
        >
          <DemoIcon :name="dark ? 'sun' : 'moon'" />
        </button>
      </div>
    </aside>
    <div class="software-main">
      <div class="software-toolbar">
        <h2>{{ en ? tool.en : tool.zh }}</h2>
        <div class="software-toolbar-actions">
          <div class="native-layout">
            <button
              v-for="(icon, mode) in {
                input: 'input',
                result: 'result',
                split: 'split',
              }"
              :key="mode"
              type="button"
              :class="{ selected: layout === mode }"
              :aria-pressed="layout === mode"
              :aria-label="
                mode === 'input'
                  ? t('显示输入', 'Show input')
                  : mode === 'result'
                    ? t('显示结果', 'Show result')
                    : t('对照显示', 'Show side by side')
              "
              @click="layout = mode"
            >
              <DemoIcon :name="icon" />
            </button>
          </div>
          <button
            class="native-favorite"
            type="button"
            :aria-label="t('收藏当前工具', 'Favorite current tool')"
            :aria-pressed="favorites.includes(active)"
            @click="favorite"
          >
            <DemoIcon name="star" /></button
          ><button
            ref="runButton"
            class="native-run"
            type="button"
            @click="run"
          >
            <span aria-hidden="true">▶</span>{{ t("执行", "Run") }}
          </button>
        </div>
      </div>
      <div class="software-options">
        <label
          >{{ t("操作", "Operation")
          }}<select
            v-model="session.operation"
            :aria-label="t('选择操作', 'Choose operation')"
            @change="changed"
          >
            <option
              v-for="operation in tool.operations"
              :key="operation[0]"
              :value="operation[0]"
            >
              {{ operation[en ? 2 : 1] }}
            </option>
          </select></label
        ><a :href="link(`/tools/${active}.html`)"
          >{{ t("使用指南", "Tool guide") }} ↗</a
        >
      </div>
      <div class="software-panels" :class="`layout-${layout}`">
        <section class="native-panel input-panel">
          <div class="native-panel-heading">
            <strong
              ><span class="panel-color input-color"
                ><DemoIcon name="input" /></span
              >{{ active === "json" ? "JSON" : t("输入", "Input") }}</strong
            >
            <div>
              <button type="button" @click="sample">
                {{ t("示例", "Sample") }}</button
              ><button
                type="button"
                :aria-label="t('清空输入', 'Clear input')"
                @click="
                  session.input = '';
                  changed();
                "
              >
                <DemoIcon name="clear" />
              </button>
            </div>
          </div>
          <div v-if="active !== 'uuid'" class="native-editor">
            <span class="line-number" aria-hidden="true">1</span
            ><textarea
              ref="inputElement"
              v-model="session.input"
              :aria-label="t('演示输入', 'Demo input')"
              spellcheck="false"
              autocomplete="off"
              autocapitalize="off"
              maxlength="5000"
              @input="changed"
              @keydown.meta.enter.prevent="run"
              @keydown.ctrl.enter.prevent="run"
            />
          </div>
          <div v-else class="uuid-prompt">
            <DemoIcon name="uuid" />
            <p>UUID v4</p>
            <span>{{
              t(
                "点击执行，生成 3 个随机 UUID。",
                "Run to generate 3 random UUIDs.",
              )
            }}</span>
          </div>
          <div class="native-panel-status">
            <span>{{ session.input.length }} {{ t("字符", "characters") }}</span
            ><span>UTF-8</span>
          </div>
        </section>
        <section class="native-panel output-panel">
          <div class="native-panel-heading">
            <strong
              ><span class="panel-color output-color"
                ><DemoIcon name="result" /></span
              >{{ t("结果", "Result") }}</strong
            ><button
              type="button"
              :disabled="!session.ran || session.error || session.stale"
              @click="copy"
            >
              <DemoIcon :name="copied ? 'check' : 'copy'" />{{
                copied ? t("已复制", "Copied") : t("复制", "Copy")
              }}
            </button>
          </div>
          <div class="native-result" :class="{ 'has-error': session.error }">
            <pre
              v-if="session.ran"
            ><code><span v-for="(token, i) in highlighted" :key="i" :class="`syntax-${token.type}`">{{ token.value }}</span></code></pre>
            <div v-else class="result-placeholder">
              <DemoIcon name="result" /><span>{{
                t("点击执行，查看结果", "Run to see the result")
              }}</span>
            </div>
          </div>
          <div class="native-panel-status" aria-live="polite">
            <span
              :class="{
                complete: session.ran && !session.error && !session.stale,
              }"
              >{{
                copyFailed
                  ? t("复制不可用，请选择文本复制", "Select text to copy")
                  : session.stale
                    ? t("待更新", "Needs update")
                    : session.error
                      ? t("检查输入", "Check input")
                      : session.ran
                        ? t("✓ 已完成", "✓ Complete")
                        : t("等待输入", "Ready")
              }}</span
            ><span>{{ resultText.length }} {{ t("字符", "characters") }}</span>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>
