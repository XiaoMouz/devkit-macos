<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref } from "vue";
import { useData, withBase } from "vitepress";
import SoftwareDemo from "./SoftwareDemo.vue";
import ToolCollections from "./ToolCollections.vue";
import TerminalDemo from "./TerminalDemo.vue";
import { demoTools } from "./demo-tools.mjs";

const { lang } = useData();
const en = computed(() => lang.value === "en");
const t = (zh, english) => (en.value ? english : zh);
const href = (path) => withBase(`${en.value ? "/en" : ""}${path}`);
const download = "https://github.com/luolayo/devkit-macos/releases/latest";
const root = ref(null);
const software = ref(null);
const activeSection = ref("");
const lightbox = ref(null);
const selectedShot = ref(0);
const activeFeature = ref(0);
const featurePinned = ref(false);
const featureScenes = computed(() => [
  {
    name: "JSON",
    title: t("复杂数据，清晰呈现。", "Complex data. Clearly presented."),
    description: t(
      "格式化、查询、对比、校验。八种操作，在同一个工作台完成。",
      "Format, query, compare, and validate. Eight operations in one workspace.",
    ),
    image: "json-workspace.png",
    link: "/guides/json.html",
    class: "scene-json",
  },
  {
    name: t("编码转换", "Encoding"),
    title: t("转换之间，流畅自如。", "Conversions without the detour."),
    description: t(
      "Base64、URL、Data URL。输入内容，转换，再带走结果。",
      "Base64, URL, Data URL. Enter your content, convert it, and take the result.",
    ),
    image: "base64.png",
    link: "/tools/base64.html",
    class: "scene-encoding",
  },
  {
    name: t("图片处理", "Images"),
    title: t("好素材，从这里开始。", "Your next asset starts here."),
    description: t(
      "调整尺寸、转换格式、生成二维码和网站图标。预览满意，再导出。",
      "Resize, convert, and create QR codes and favicons. Preview, then export.",
    ),
    image: "qr-code.png",
    link: "/guides/images.html",
    class: "scene-images",
  },
]);
let motion,
  featureTimeline,
  introTimeline,
  sectionObserver,
  refreshScroll,
  disposed = false;

function selectFeature(index) {
  if (!featureTimeline?.scrollTrigger) return;
  const trigger = featureTimeline.scrollTrigger;
  const time = [0.4, 2.15, 3.9][index];
  window.scrollTo({
    top:
      trigger.start +
      ((trigger.end - trigger.start) * time) / featureTimeline.duration(),
    behavior: "smooth",
  });
}
async function tryTool(id) {
  if (!demoTools.some((tool) => tool.id === id)) return;
  software.value?.select(id);
  await nextTick();
  const workbench = root.value?.querySelector(".intro-workbench");
  const destination = introTimeline?.scrollTrigger
    ? introTimeline.scrollTrigger.end - 1
    : window.scrollY + workbench.getBoundingClientRect().top - 78;
  const immediate =
    window.matchMedia("(prefers-reduced-motion: reduce)").matches ||
    Math.abs(window.scrollY - destination) > window.innerHeight * 1.5;
  window.scrollTo({
    top: destination,
    behavior: immediate ? "auto" : "smooth",
  });
  software.value?.focusInput();
}
function galleryKey(event) {
  if (event.altKey || event.ctrlKey || event.metaKey) return;
  const next = {
    ArrowLeft: selectedShot.value - 1,
    ArrowRight: selectedShot.value + 1,
    Home: 0,
    End: featureScenes.value.length - 1,
  }[event.key];
  if (next === undefined) return;
  event.preventDefault();
  selectedShot.value = Math.max(
    0,
    Math.min(featureScenes.value.length - 1, next),
  );
}
async function openScreenshot(index) {
  selectedShot.value = index;
  await nextTick();
  lightbox.value.showModal();
}

onMounted(async () => {
  sectionObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) activeSection.value = entry.target.id;
      }
    },
    { rootMargin: "-20% 0px -70% 0px" },
  );
  root.value
    .querySelectorAll("#playground, #features, #tools, #cli, #download")
    .forEach((section) => sectionObserver.observe(section));
  const [core, plugin] = await Promise.all([
    import("gsap"),
    import("gsap/ScrollTrigger"),
  ]);
  if (disposed || !root.value) return;
  const { gsap } = core;
  const { ScrollTrigger } = plugin;
  gsap.registerPlugin(ScrollTrigger);
  const select = gsap.utils.selector(root.value);
  motion = gsap.matchMedia();
  refreshScroll = () => ScrollTrigger.refresh();
  motion.add("(prefers-reduced-motion: no-preference)", () => {
    gsap
      .timeline({ defaults: { ease: "power3.out" } })
      .from(
        select(".intro-copy > *"),
        { y: 24, opacity: 0, duration: 1, stagger: 0.09 },
        0,
      )
      .from(
        select(".intro-arrival"),
        { y: 70, opacity: 0, duration: 1.25 },
        0.25,
      );
    select(".scroll-heading").forEach((element) =>
      gsap.from(element, {
        y: 38,
        opacity: 0.15,
        ease: "power2.out",
        scrollTrigger: {
          trigger: element,
          start: "top 94%",
          end: "top 65%",
          scrub: 0.7,
        },
      }),
    );
    gsap.from(select(".tool-explorer"), {
      y: 35,
      opacity: 0.4,
      scrollTrigger: {
        trigger: select(".tool-explorer")[0],
        start: "top 92%",
        end: "top 64%",
        scrub: 0.7,
      },
    });
    gsap.fromTo(
      select(".terminal-parallax"),
      { y: 60, scale: 0.95 },
      {
        y: -15,
        scale: 1,
        ease: "none",
        scrollTrigger: {
          trigger: select(".cli-section")[0],
          start: "top 85%",
          end: "center 40%",
          scrub: 0.8,
        },
      },
    );
    gsap.from(select(".download-banner"), {
      y: 30,
      opacity: 0.5,
      scrollTrigger: {
        trigger: select(".download-section")[0],
        start: "top 90%",
        end: "center 75%",
        scrub: 0.8,
      },
    });
  });

  // Tablet widths use the same scroll story as desktop, including the 930px review viewport.
  motion.add(
    "(min-width: 760px) and (min-height: 620px) and (prefers-reduced-motion: no-preference)",
    () => {
      const intro = select(".intro-stage")[0];
      const workbench = select(".intro-workbench")[0];
      introTimeline = gsap
        .timeline({
          scrollTrigger: {
            trigger: intro,
            pin: true,
            start: "top top",
            end: () => `+=${Math.round(window.innerHeight * 0.65)}`,
            scrub: 0.8,
            anticipatePin: 1,
            invalidateOnRefresh: true,
          },
        })
        .to(select(".intro-copy"), { y: -90, autoAlpha: 0, duration: 0.65 }, 0)
        .fromTo(
          select(".intro-motion"),
          { scale: 0.9, y: 0 },
          {
            scale: 1,
            y: () =>
              Math.max(
                80,
                (window.innerHeight - workbench.offsetHeight) / 2 + 24,
              ) - workbench.offsetTop,
            duration: 1,
            ease: "power1.inOut",
          },
          0,
        );

      const stage = select(".feature-stage")[0];
      const track = select(".feature-track")[0];
      const visuals = select(".feature-visual");
      stage.classList.add("is-pinned");
      featurePinned.value = true;
      gsap.set(visuals, { scale: 0.94 });
      featureTimeline = gsap
        .timeline({
          onUpdate: () => {
            const time = featureTimeline?.time() || 0;
            activeFeature.value = time < 1.35 ? 0 : time < 3.05 ? 1 : 2;
          },
          scrollTrigger: {
            trigger: stage,
            pin: true,
            start: "top 58px",
            end: () => `+=${Math.round(window.innerHeight * 2.8)}`,
            scrub: 0.65,
            anticipatePin: 1,
            invalidateOnRefresh: true,
          },
        })
        .to(visuals[0], { scale: 1, duration: 0.85, ease: "none" })
        .to(track, { xPercent: -100, duration: 1, ease: "power2.inOut" })
        .to(visuals[1], { scale: 1, duration: 0.8, ease: "none" }, "<.2")
        .to({}, { duration: 0.7 })
        .to(track, { xPercent: -200, duration: 1, ease: "power2.inOut" })
        .to(visuals[2], { scale: 1, duration: 0.8, ease: "none" }, "<.2")
        .to({}, { duration: 0.85 });
      return () => {
        stage.classList.remove("is-pinned");
        featurePinned.value = false;
        activeFeature.value = 0;
        featureTimeline = undefined;
        introTimeline = undefined;
      };
    },
  );

  motion.add(
    "(max-width: 759px) and (prefers-reduced-motion: no-preference), (max-height: 619px) and (prefers-reduced-motion: no-preference)",
    () => {
      select(".feature-panel").forEach((panel) => {
        gsap.from(panel.querySelector(".feature-copy"), {
          y: 25,
          opacity: 0.2,
          scrollTrigger: {
            trigger: panel,
            start: "top 90%",
            end: "top 55%",
            scrub: 0.6,
          },
        });
        gsap.fromTo(
          panel.querySelector(".feature-visual"),
          { y: 24, scale: 0.96 },
          {
            y: -12,
            scale: 1,
            scrollTrigger: {
              trigger: panel,
              start: "top 85%",
              end: "bottom 35%",
              scrub: 0.6,
            },
          },
        );
      });
    },
  );
  // Pin spacers change section positions after hydration; honor incoming anchors.
  const sectionHash = window.location.hash;
  if (["#features", "#tools", "#cli"].includes(sectionHash)) {
    requestAnimationFrame(() => {
      if (disposed) return;
      const target = root.value?.querySelector(sectionHash);
      if (!target) return;
      const padding = parseFloat(getComputedStyle(target).paddingTop) || 0;
      window.scrollTo(
        0,
        window.scrollY + target.getBoundingClientRect().top + padding - 78,
      );
    });
  }
});
onUnmounted(() => {
  disposed = true;
  motion?.revert();
  sectionObserver?.disconnect();
  featureTimeline = undefined;
  refreshScroll = undefined;
});
</script>

<template>
  <div ref="root" class="devkit-home">
    <header class="landing-header">
      <a class="landing-brand" :href="href('/')"
        ><img
          :src="withBase('/images/devkit-icon.svg')"
          width="26"
          height="26"
          alt=""
        />DevKit</a
      >
      <nav :aria-label="t('首页导航', 'Homepage navigation')">
        <a
          href="#features"
          :aria-current="activeSection === 'features' ? 'location' : undefined"
          >{{ t("功能", "Features") }}</a
        >
        <a
          href="#tools"
          :aria-current="activeSection === 'tools' ? 'location' : undefined"
          >{{ t("工具", "Tools") }}</a
        >
        <a
          href="#cli"
          :aria-current="activeSection === 'cli' ? 'location' : undefined"
          >CLI</a
        >
        <a :href="href('/getting-started.html')">{{ t("文档", "Docs") }}</a>
      </nav>
      <div class="header-actions">
        <a :href="withBase(en ? '/' : '/en/')" :lang="en ? 'zh-CN' : 'en'">{{
          en ? "中文" : "EN"
        }}</a>
        <a class="button-primary button-small" :href="download">{{
          t("下载", "Download")
        }}</a>
      </div>
    </header>

    <section id="playground" class="intro-stage" aria-labelledby="home-title">
      <div class="intro-copy">
        <h1 id="home-title">DevKit</h1>
        <p>
          {{ t("开发者的 Mac 工具箱。", "The Mac toolbox for developers.") }}
        </p>
        <div class="intro-actions">
          <a class="button-primary" :href="download">{{
            t("下载 DevKit", "Download DevKit")
          }}</a>
          <a class="link-action" :href="href('/getting-started.html')"
            >{{ t("查看文档", "Read the docs")
            }}<span aria-hidden="true">›</span></a
          >
        </div>
      </div>
      <div class="intro-workbench">
        <div class="intro-arrival">
          <div class="intro-motion">
            <SoftwareDemo ref="software" dark-initially />
          </div>
        </div>
      </div>
    </section>

    <section
      id="features"
      class="feature-story"
      :aria-label="
        t('三项功能，随滚动探索', 'Explore three features as you scroll')
      "
    >
      <div class="feature-stage">
        <div class="feature-track">
          <article
            v-for="(scene, i) in featureScenes"
            :key="scene.image"
            class="feature-panel"
            :class="scene.class"
            :aria-hidden="
              featurePinned && activeFeature !== i ? 'true' : undefined
            "
            :inert="featurePinned && activeFeature !== i"
          >
            <div class="feature-copy">
              <h2>
                <span>{{ scene.name }}</span
                >{{ scene.title }}
              </h2>
              <p>{{ scene.description }}</p>
              <a class="link-action" :href="href(scene.link)"
                >{{ t("进一步了解", "Learn more")
                }}<span aria-hidden="true">›</span></a
              >
            </div>
            <div class="feature-visual">
              <button
                type="button"
                class="feature-shot"
                :aria-label="t('放大', 'Enlarge ') + scene.name"
                @click="openScreenshot(i)"
              >
                <img
                  :src="withBase(`/images/${scene.image}`)"
                  :alt="scene.name"
                  width="2560"
                  height="1640"
                  loading="lazy"
                  @load="refreshScroll?.()"
                />
                <span class="image-expand" aria-hidden="true">+</span>
              </button>
            </div>
          </article>
        </div>
        <nav
          v-show="featurePinned"
          class="feature-progress"
          :aria-label="t('选择功能场景', 'Choose a feature scene')"
        >
          <button
            v-for="(scene, i) in featureScenes"
            :key="scene.name"
            type="button"
            :aria-label="scene.name"
            :aria-current="activeFeature === i ? 'step' : undefined"
            @click="selectFeature(i)"
          >
            <span aria-hidden="true" />
          </button>
        </nav>
      </div>
      <dialog
        ref="lightbox"
        class="screenshot-dialog"
        :aria-label="featureScenes[selectedShot].name"
        @keydown="galleryKey"
        @click="
          (event) => {
            if (event.target === lightbox) lightbox.close();
          }
        "
      >
        <div class="preview-toolbar">
          <span>{{ featureScenes[selectedShot].name }}</span>
          <div class="preview-navigation">
            <button
              type="button"
              :disabled="selectedShot === 0"
              :aria-label="t('上一张截图', 'Previous screenshot')"
              @click="selectedShot--"
            >
              ‹
            </button>
            <span>{{ selectedShot + 1 }} / {{ featureScenes.length }}</span>
            <button
              type="button"
              :disabled="selectedShot === featureScenes.length - 1"
              :aria-label="t('下一张截图', 'Next screenshot')"
              @click="selectedShot++"
            >
              ›
            </button>
          </div>
          <button
            type="button"
            class="close-preview"
            :aria-label="t('关闭截图', 'Close screenshot')"
            @click="lightbox.close()"
          >
            ×
          </button>
        </div>
        <img
          :src="withBase(`/images/${featureScenes[selectedShot].image}`)"
          :alt="featureScenes[selectedShot].name"
          width="2560"
          height="1640"
        />
      </dialog>
    </section>

    <section id="tools" class="tools-section">
      <div class="section-heading content-width scroll-heading">
        <h2>
          {{ t("更多工具，", "More tools.") }}<br /><span>{{
            t("更少切换。", "Fewer interruptions.")
          }}</span>
        </h2>
        <a class="link-action" :href="href('/tools/')"
          >{{ t("浏览全部 48 个工具", "Explore all 48 tools")
          }}<span aria-hidden="true">›</span></a
        >
      </div>
      <div class="content-width">
        <ToolCollections
          @layout-change="refreshScroll?.()"
          @try-tool="tryTool"
        />
      </div>
    </section>

    <section id="cli" class="cli-section">
      <div class="cli-copy content-width scroll-heading">
        <h2>
          {{ t("终端。", "The terminal.") }}<br /><span>{{
            t("也很拿手。", "Right at home.")
          }}</span>
        </h2>
        <p>
          {{
            t(
              "让同一套工具，进入你的脚本、Codex 和 Claude Code。",
              "Bring the same tools to your scripts, Codex, and Claude Code.",
            )
          }}
        </p>
        <a class="link-action" :href="href('/cli-and-ai.html')"
          >{{ t("配置 CLI 与 AI", "Set up CLI & AI")
          }}<span aria-hidden="true">›</span></a
        >
      </div>
      <div class="terminal-parallax content-width"><TerminalDemo /></div>
    </section>

    <section id="download" class="download-section content-width">
      <div class="download-banner">
        <img
          class="download-icon"
          :src="withBase('/images/devkit-icon.svg')"
          width="88"
          height="88"
          alt=""
        />
        <div class="download-copy">
          <h2>
            {{ t("把 DevKit 带到", "Bring DevKit") }}<br />{{
              t("你的 Mac。", "to your Mac.")
            }}
          </h2>
        </div>
        <div class="download-actions">
          <a class="button-primary" :href="download">{{
            t("下载 DevKit", "Download DevKit")
          }}</a
          ><a class="link-action" :href="href('/getting-started.html')"
            >{{ t("安装指南", "Installation guide")
            }}<span aria-hidden="true">›</span></a
          >
        </div>
      </div>
    </section>
    <footer class="landing-footer content-width">
      <a class="footer-brand" :href="href('/')">DevKit</a>
      <nav :aria-label="t('页尾导航', 'Footer navigation')">
        <a :href="href('/getting-started.html')">{{
          t("文档", "Documentation")
        }}</a
        ><a :href="href('/faq.html')">{{ t("常见问题", "FAQ") }}</a
        ><a href="https://github.com/luolayo/devkit-macos">GitHub</a
        ><a :href="withBase(en ? '/' : '/en/')">{{
          en ? "简体中文" : "English"
        }}</a>
      </nav>
    </footer>
  </div>
</template>
