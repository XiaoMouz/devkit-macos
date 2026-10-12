<script setup>
import { withBase } from 'vitepress'
const routes = [
  { title: '整理一份 JSON', detail: '从格式化到路径查询、对比与 Schema 校验。', link: '/guides/json.html', label: 'JSON 工作台' },
  { title: '调试一次请求', detail: '检查 URL、请求头、响应正文与连接消息。', link: '/guides/network.html', label: 'HTTP / WebSocket / DNS' },
  { title: '把工具接入终端', detail: '用管道、结构化请求和 AI Skill 执行同一套工具。', link: '/cli-and-ai.html', label: 'CLI 与 AI' },
  { title: '准备前端图片', detail: '调整尺寸、转换格式、压缩与导出网站图标。', link: '/guides/images.html', label: '图片与资源' },
]
</script>

<template>
  <div class="devkit-home">
    <section class="home-intro" aria-labelledby="home-title">
      <p class="home-label">DevKit for macOS / 使用手册</p>
      <h1 id="home-title">开发中的小事，<br>在 Mac 上顺手完成。</h1>
      <p class="home-lead">编码、JSON、文本、日期、网络与图片。48 个工具，一套原生工作区；也能从终端和 AI 中调用。</p>
      <div class="home-actions">
        <a class="primary-action" :href="withBase('/getting-started.html')">开始使用 <span aria-hidden="true">↗</span></a>
        <a class="secondary-action" :href="withBase('/tools/')">浏览全部工具 <span aria-hidden="true">→</span></a>
      </div>
      <p class="home-requirements">v0.1.0 预览版 · macOS 26 及以上 · 本机处理</p>
    </section>
    <figure class="workspace-figure">
      <img :src="withBase('/images/json-workspace.png')" alt="DevKit 的 JSON 工作台：左侧为工具目录，右侧并排显示输入与格式化后的 JSON" width="2560" height="1640" fetchpriority="high">
      <figcaption>真实应用界面 · JSON 工作台</figcaption>
    </figure>
    <section class="home-paths" aria-labelledby="paths-title">
      <div class="section-heading"><h2 id="paths-title">从眼前的任务开始</h2><span>操作步骤、示例与边界，都在这里。</span></div>
      <div class="path-grid">
        <a v-for="route in routes" :key="route.link" :href="withBase(route.link)" class="path-card">
          <p class="path-label">{{ route.label }}</p><h3>{{ route.title }} <span aria-hidden="true">↗</span></h3><p>{{ route.detail }}</p>
        </a>
      </div>
    </section>
    <section class="home-terminal" aria-labelledby="terminal-title">
      <div><p class="path-label">同一套工具，另一种入口</p><h2 id="terminal-title">窗口之外，也能直接用。</h2><p>在设置中安装 devkit，工具发现与执行都只需一条命令。</p><a :href="withBase('/cli-and-ai.html')">配置 CLI 与 AI Skill →</a></div>
      <div class="terminal-example" aria-label="CLI 示例"><span>$ devkit describe base64</span><span>$ printf '%s' 'hello' | devkit run base64 --format text</span><strong>aGVsbG8=</strong></div>
    </section>
    <p class="home-note">已签名并通过 Apple 公证 · Apple Silicon / Intel 通用包 · <a href="https://github.com/luolayo/devkit-macos/releases/download/v0.1.0/DevKit-v0.1.0-macOS-universal.zip">下载 v0.1.0</a></p>
  </div>
</template>
