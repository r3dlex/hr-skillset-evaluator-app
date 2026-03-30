import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'SkillForge',
  description: 'Comprehensive docs for SkillForge',
  base: '/docs/',
  ignoreDeadLinks: true,

  head: [
    ['meta', { name: 'theme-color', content: '#4f46e5' }],
  ],

  themeConfig: {
    logo: '/logo.svg',
    siteTitle: 'SkillForge',

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started/' },
      { text: 'Features', link: '/features/dashboard' },
      { text: 'Guides', link: '/guides/manager-workflow' },
    ],

    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Quick Start', link: '/getting-started/' },
          { text: 'App Tour', link: '/getting-started/tour' },
        ],
      },
      {
        text: 'Features',
        collapsed: false,
        items: [
          { text: 'Dashboard', link: '/features/dashboard' },
          { text: 'Skillsets & Skill Groups', link: '/features/skillsets' },
          { text: 'Evaluations', link: '/features/evaluations' },
          { text: 'Radar Chart', link: '/features/radar-chart' },
          { text: 'Gap Analysis', link: '/features/gap-analysis' },
          { text: 'Assessments', link: '/features/assessments' },
          { text: 'AI Assistant', link: '/features/ai-assistant' },
          { text: 'Import / Export', link: '/features/import-export' },
        ],
      },
      {
        text: 'Guides',
        collapsed: false,
        items: [
          { text: 'Manager Workflow', link: '/guides/manager-workflow' },
          { text: 'User Workflow', link: '/guides/user-workflow' },
          { text: 'Onboarding', link: '/guides/onboarding' },
        ],
      },
      {
        text: 'Reference',
        collapsed: false,
        items: [
          { text: 'Roles & Permissions', link: '/reference/roles' },
          { text: 'Glossary', link: '/reference/glossary' },
        ],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/your-org/hr-skillset-evaluator-app' },
    ],

    search: {
      provider: 'local',
    },

    footer: {
      message: 'SkillForge Documentation',
    },
  },
})
