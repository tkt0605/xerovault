export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  devtools: { enabled: true },
  ssr: true,
  app: {
    head: {
      title: 'XeroVault',
      meta: [
        {charset: 'utf-8'},
        {name: 'viewport', content:'width=device-width, initial-scale=1'},
        {name: 'description', content: 'Xerovault は、Xero API 資格情報用の安全な保管庫です。'},
        {name: 'keywords', content: 'Xero、API、資格情報、保管庫、セキュリティ'},
      ],
      link: [
        {rel: 'icon', type: 'image/x-icon', href: '/favicon.ico'},
        {rel: 'stylesheet', href: 'https://fonts.googleapis.com/css?family=Roboto:wgth@300;400;500;700&display=swap'},
      ],
    },
    baseURL: '/',
  },
  devServer: {
    port:3000,
    host: '0.0.0.0',
  },
  // css: [
  //   "@/assets/css/main.css",
  // ],
  modules: [
    '@nuxtjs/i18n',
    '@pinia/nuxt',
  ],
  runtimeConfig: {
    public: {
      apiBase: 'http://localhost:8000/api/'
    }
  },
  i18n: {
    experimental: {
      bundle: {
        optimizeTranslationDirective: false // または true（使いたい場合）
      }
    }
  },
  css: ['@/assets/css/tailwind.css'],
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },
})
