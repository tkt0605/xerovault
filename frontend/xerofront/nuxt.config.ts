import { SplitVendorChunkCache } from "vite";

export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  // devtools: { enabled: true },
  devtools: { enabled: false },
  // ssr: true,
  ssr: false,
  target: 'static',
  app: {
    head: {
      title: 'iStudio',
      // meta: [
      //   { charset: 'utf-8' },
      //   { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      //   { name: 'description', content: 'Studio DEMO は、Xero API 資格情報用の安全な保管庫です。' },
      //   { name: 'keywords', content: 'Xero、API、資格情報、保管庫、セキュリティ' },
      // ],
      meta: [
        { name: 'robots', content: 'index, follow' },
        { property: 'og:title', content: 'iStudio by DeMO' },
        { property: 'og:description', content: 'Xero API の資格情報管理ツール' },
        { property: 'og:type', content: 'website' },
        // { property: 'og:image', content: 'https://example.com/og-image.png' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css?family=Roboto:wgth@300;400;500;700&display=swap' },
      ],
    },
    baseURL: '/',
  },
  devServer: {
    port: 3000,
    host: '0.0.0.0',
  },
  // css: [
  //   "@/assets/css/main.css",
  // ],
  modules: [
    '@nuxtjs/i18n',
    '@pinia/nuxt',
    '@nuxtjs/color-mode'
  ],
  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8000/api/'
      // apiBase: 'http://localhost:8000/api/'
    }
  },
  i18n: {
    experimental: {
      bundle: {
        optimizeTranslationDirective: false
        // optimizeTranslationDirective: true
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
  colorMode: {
    preference: 'system', // 'dark' または 'light' にもできる
    fallback: 'light',
    classSuffix: '',       // クラス名に `-dark` などのサフィックスをつけない
  },
  nitro: {
    output: {
      dir: 'dist'
    },
    routeRules: {
      '/**': {
        headers: {
          'X-Frame-Options': 'DENY',
          'X-Content-Type-Options': 'nosniff',
          'Referrer-Policy': 'strict-origin-when-cross-origin'
        }
      }
    }
  },
  generate: {
    subFolders: false,
    fallback: true
  },
  vite: {
    optimizeDeps: {
      noDiscovery: true
    },
    build: {
      rollupOptions: {
        output: {
          assetFileNames : (chunkInfo) => {
            const name = chunkInfo.name ?? 'assets';
            return `assets/${name}-[hash][extname]`;
          }
        }
      }
    }
  },

});
