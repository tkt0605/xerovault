export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',

  // サーバーサイドレンダリングの無効化（Staticサイト生成のため）
  ssr: false,

  // Nuxt Devtools の有効化（開発時のみ有効にするのが理想）
  devtools: { enabled: true },

  app: {
    head: {
      title: 'iStudio',
      meta: [
        { name: 'robots', content: 'index, follow' },
        { property: 'og:title', content: 'iStudio by DeMO' },
        { property: 'og:description', content: 'Xero API の資格情報管理ツール' },
        { property: 'og:type', content: 'website' },
        // { property: 'og:image', content: 'https://example.com/og-image.png' }, // 画像URL追加時は有効に
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css?family=Roboto:wgth@300;400;500;700&display=swap' },
      ],
    },
    baseURL: '/', // 必要に応じて修正（サブディレクトリ配信時など）
  },

  // 開発サーバー設定
  devServer: {
    port: 3000,
    host: '0.0.0.0',
  },

  // 使用モジュール
  modules: [
    '@nuxtjs/i18n',
    '@pinia/nuxt',
    '@nuxtjs/color-mode'
  ],

  // 環境変数の公開設定
  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'https://xerovault-api-v2.azurewebsites.net/api/',
    },
  },

  // i18n 設定
  i18n: {
    experimental: {
      bundle: {
        optimizeTranslationDirective: false // v10 以降で削除予定の警告対策
      }
    }
  },

  // グローバルCSS
  css: ['@/assets/css/tailwind.css'],

  // PostCSS 設定（Tailwind対応）
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },

  // ダークモード設定
  colorMode: {
    preference: 'system',
    fallback: 'light',
    classSuffix: '',
  },

  // Nitro / generate 用出力先 & ヘッダー制御
  nitro: {
    output: {
      dir: 'dist'
    },
    prerender: {
      failOnError: false,
      crawlLinks: true,
      routes: ['/']
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

  // 静的サイト生成の挙動
  generate: {
    subFolders: false,
    fallback: true
  },

  // Vite設定（Rollup設定は削除済み）
  vite: {
    // ビルド時に必要な設定があればここで追加（現時点で不要なら空でOK）
  }
});
