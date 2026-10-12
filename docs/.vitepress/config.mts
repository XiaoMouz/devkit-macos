import { defineConfig } from 'vitepress'
import catalog from './tool-catalog.json'

export default defineConfig({
  lang: 'zh-CN',
  title: 'DevKit',
  description: 'DevKit for macOS 使用手册：48 个开发工具、JSON 工作台、CLI 与 AI Skill。',
  base: '/devkit-macos/',
  srcExclude: ['README.md'],
  lastUpdated: true,
  sitemap: { hostname: 'https://luolayo.github.io/devkit-macos/' },
  head: [
    ['meta', { name: 'theme-color', content: '#f5f7fb' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'zh_CN' }],
  ],
  themeConfig: {
    siteTitle: 'DevKit 使用手册',
    nav: [
      { text: '开始使用', link: '/getting-started' },
      { text: '工具目录', link: '/tools/' },
      { text: 'CLI 与 AI', link: '/cli-and-ai' },
      { text: 'v0.1.0', link: 'https://github.com/luolayo/devkit-macos/releases/tag/v0.1.0' },
    ],
    sidebar: [
      { text: '开始使用', items: [
        { text: '安装与第一步', link: '/getting-started' },
        { text: '工作区与多窗口', link: '/workspace' },
        { text: '文件与导出', link: '/files' },
        { text: '快捷键与外观', link: '/shortcuts' },
      ] },
      { text: '任务指南', items: [
        { text: 'JSON 八种操作', link: '/guides/json' },
        { text: '网络调试', link: '/guides/network' },
        { text: '图片与网站图标', link: '/guides/images' },
        { text: 'CLI 与 AI Skill', link: '/cli-and-ai' },
        { text: 'Spotlight', link: '/spotlight' },
      ] },
      { text: '工具参考 · 48', link: '/tools/', items: catalog.map(group => ({
        text: group.name, collapsed: true,
        items: group.tools.map(tool => ({text: tool.name, link: `/tools/${tool.id}`})),
      })) },
      { text: '帮助', items: [
        { text: '隐私与数据边界', link: '/privacy' },
        { text: '常见问题', link: '/faq' },
        { text: '版本说明', link: '/release-notes' },
      ] },
    ],
    socialLinks: [{ icon: 'github', link: 'https://github.com/luolayo/devkit-macos' }],
    search: { provider: 'local', options: { locales: { root: { translations: {
      button: { buttonText: '搜索手册', buttonAriaLabel: '搜索使用手册' },
      modal: { noResultsText: '没有找到相关内容', resetButtonTitle: '清空搜索',
        displayDetails: '显示摘要', backButtonTitle: '返回',
        footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' } },
    } } } } },
    outline: { label: '本页内容', level: [2, 3] },
    docFooter: { prev: '上一篇', next: '下一篇' },
    lastUpdated: { text: '最近更新', formatOptions: { dateStyle: 'medium' } },
    editLink: { pattern: 'https://github.com/luolayo/devkit-macos/edit/main/docs/:path', text: '在 GitHub 上改进此页' },
    returnToTopLabel: '返回顶部', sidebarMenuLabel: '目录', darkModeSwitchLabel: '外观',
    lightModeSwitchTitle: '切换浅色', darkModeSwitchTitle: '切换深色',
    footer: { message: '在 Mac 上处理开发中的小事。', copyright: 'DevKit for macOS · v0.1.0 使用手册' },
  },
})
