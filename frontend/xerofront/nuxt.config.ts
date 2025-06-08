// https://nuxt.com/docs/api/configuration/nuxt-config
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
        {name: 'keywards', content: 'Xero、API、資格情報、保管庫、セキュリティ'},
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
  css: [
    "@/assets/css/main.css",
  ],
  modules: [
    // '@nuxtjs/tailwindcss',
    '@nuxtjs/i18n',
    '@nuxtjs/axios',
    '@nuxtjs/auth-next',
    '@pinia/nuxt',
  ],
  runtimeConfig: {
    public: {
      apiBase: 'http://localhost:8000/api/'
    }
  }
})
