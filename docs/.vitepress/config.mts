import { defineConfig, type DefaultTheme } from 'vitepress'
import catalog from './tool-catalog.json'

function navigation(en: boolean): DefaultTheme.Config {
  const text = (zh: string, english: string) => en ? english : zh
  const link = (path: string) => `${en ? '/en' : ''}${path}`
  return {
    siteTitle: 'DevKit',
    nav: [
      { text: text('指南', 'Guide'), link: link('/getting-started') },
      { text: text('工具目录', 'Tools'), link: link('/tools/') },
      { text: text('CLI 与 AI', 'CLI & AI'), link: link('/cli-and-ai') },
      { text: text('下载', 'Download'), link: 'https://github.com/luolayo/devkit-macos/releases/latest' },
    ],
    sidebar: [
      { text: text('开始使用', 'Get started'), items: [
        { text: text('安装与第一步', 'Installation & first steps'), link: link('/getting-started') },
        { text: text('工作区与多窗口', 'Workspace & windows'), link: link('/workspace') },
        { text: text('文件与导出', 'Files & export'), link: link('/files') },
        { text: text('快捷键、语言与外观', 'Shortcuts, language & appearance'), link: link('/shortcuts') },
      ] },
      { text: text('任务指南', 'Task guides'), items: [
        { text: text('JSON 八种操作', 'Eight JSON operations'), link: link('/guides/json') },
        { text: text('网络调试', 'Network debugging'), link: link('/guides/network') },
        { text: text('图片与网站图标', 'Images & favicons'), link: link('/guides/images') },
        { text: text('CLI 与 AI 技能', 'CLI & AI skills'), link: link('/cli-and-ai') },
        { text: 'Spotlight', link: link('/spotlight') },
      ] },
      { text: text('工具参考 · 48', 'Tool reference · 48'), link: link('/tools/'), items: catalog.map(group => ({
        text: en ? group.nameEn : group.name, collapsed: true,
        items: group.tools.map(tool => ({ text: en ? tool.nameEn : tool.name, link: link(`/tools/${tool.id}`) })),
      })) },
      { text: text('帮助', 'Help'), items: [
        { text: text('数据保存', 'Data & sessions'), link: link('/privacy') },
        { text: text('常见问题', 'FAQ'), link: link('/faq') },
        { text: text('版本说明', 'Release notes'), link: link('/release-notes') },
      ] },
    ],
    outline: { label: text('本页内容', 'On this page'), level: [2, 3] },
    docFooter: { prev: text('上一篇', 'Previous page'), next: text('下一篇', 'Next page') },
    lastUpdated: { text: text('最近更新', 'Last updated'), formatOptions: { dateStyle: 'medium' } },
    editLink: { pattern: 'https://github.com/luolayo/devkit-macos/edit/main/docs/:path', text: text('在 GitHub 上改进此页', 'Edit this page on GitHub') },
    langMenuLabel: text('选择语言', 'Change language'),
    returnToTopLabel: text('返回顶部', 'Back to top'),
    sidebarMenuLabel: text('目录', 'Menu'),
    darkModeSwitchLabel: text('外观', 'Appearance'),
    lightModeSwitchTitle: text('切换浅色', 'Switch to light theme'),
    darkModeSwitchTitle: text('切换深色', 'Switch to dark theme'),
    skipToContentLabel: text('跳转到内容', 'Skip to content'),
    notFound: {
      title: text('页面未找到', 'Page not found'),
      quote: text('可以返回首页，或搜索你需要的工具。', 'Return home or search for the tool you need.'),
      linkLabel: text('返回首页', 'Go to home'), linkText: text('返回首页', 'Take me home'),
    },
  }
}

export default defineConfig({
  title: 'DevKit',
  base: '/devkit-macos/',
  scrollOffset: { selector: ['.landing-header', '.VPNav'], padding: 20 },
  srcExclude: ['README.md', 'en/README.md'],
  lastUpdated: true,
  sitemap: { hostname: 'https://luolayo.github.io/devkit-macos/' },
  locales: {
    root: {
      label: '简体中文', lang: 'zh-CN',
      description: 'DevKit for macOS 使用手册：48 个开发工具、JSON 工作台、CLI 与 AI 技能。',
      themeConfig: navigation(false),
    },
    en: {
      label: 'English', lang: 'en',
      description: 'DevKit for macOS: guides for 48 developer tools, the JSON workspace, CLI, and AI skills.',
      themeConfig: navigation(true),
    },
  },
  head: [
    ['meta', { name: 'theme-color', content: '#f7f9fc' }],
    ['meta', { property: 'og:type', content: 'website' }],
  ],
  transformHead({ pageData }) {
    return [['meta', { property: 'og:locale', content: pageData.relativePath.startsWith('en/') ? 'en_US' : 'zh_CN' }]]
  },
  themeConfig: {
    socialLinks: [{ icon: 'github', link: 'https://github.com/luolayo/devkit-macos' }],
    search: { provider: 'local', options: { locales: { root: { translations: {
      button: { buttonText: '搜索文档', buttonAriaLabel: '搜索使用手册' },
      modal: { noResultsText: '没有找到相关内容', resetButtonTitle: '清空搜索',
        displayDetails: '显示摘要', backButtonTitle: '返回',
        footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' } },
    } } } } },
    footer: { copyright: 'DevKit for macOS · <a href="https://github.com/luolayo/devkit-macos">GitHub</a>' },
  },
})
