<script setup>
import { withBase } from 'vitepress'
const routes = [
  { title: 'JSON 工作台', detail: '格式化、路径查询、结构对比与 Schema 校验。', link: '/guides/json.html' },
  { title: '网络调试', detail: '检查 URL、请求头、响应正文与连接消息。', link: '/guides/network.html' },
  { title: 'CLI 与 AI', detail: '命令行调用、结构化请求与 Skill 安装。', link: '/cli-and-ai.html' },
  { title: '图片与网站图标', detail: '调整尺寸、转换格式、压缩与导出网站图标。', link: '/guides/images.html' },
]
</script>

<template>
  <div class="devkit-home">
    <section class="home-intro" aria-labelledby="home-title">
      <p class="home-label">DevKit for macOS</p>
      <h1 id="home-title">使用手册</h1>
      <p class="home-lead">编码转换、JSON、文本、日期、网络与图片工具的使用指南。</p>
      <div class="home-actions">
        <a class="primary-action" :href="withBase('/getting-started.html')">开始使用 <span aria-hidden="true">↗</span></a>
        <a class="secondary-action" :href="withBase('/tools/')">浏览全部工具 <span aria-hidden="true">→</span></a>
      </div>
      <p class="home-requirements">macOS 26 及以上</p>
    </section>
    <figure class="workspace-figure">
      <img :src="withBase('/images/json-workspace.png')" alt="DevKit 的 JSON 工作台：左侧为工具目录，右侧并排显示输入与格式化后的 JSON" width="2560" height="1640" fetchpriority="high">
      <figcaption>JSON 工作台</figcaption>
    </figure>
    <section class="home-paths" aria-labelledby="paths-title">
      <div class="section-heading"><h2 id="paths-title">使用指南</h2></div>
      <div class="path-grid">
        <a v-for="route in routes" :key="route.link" :href="withBase(route.link)" class="path-card">
          <h3>{{ route.title }} <span aria-hidden="true">↗</span></h3><p>{{ route.detail }}</p>
        </a>
      </div>
    </section>
    <section class="home-terminal" aria-labelledby="terminal-title">
      <div><h2 id="terminal-title">命令行</h2><p>在「设置 → CLI 与 AI」安装 devkit 后，即可从终端调用工具。</p><a :href="withBase('/cli-and-ai.html')">配置 CLI 与 AI Skill →</a></div>
      <div class="terminal-example" aria-label="CLI 示例"><span>$ devkit describe base64</span><span>$ printf '%s' 'hello' | devkit run base64 --format text</span><strong>aGVsbG8=</strong></div>
    </section>
    <p class="home-note"><a href="https://github.com/luolayo/devkit-macos/releases/latest">下载 DevKit</a></p>
  </div>
</template>
