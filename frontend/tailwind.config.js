/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,ts}'],
  darkMode: 'media',
  theme: {
    extend: {
      colors: {
        ink: 'var(--ink)',
        'ink-soft': 'var(--ink-soft)',
        'ink-faint': 'var(--ink-faint)',
        paper: 'var(--paper)',
        'paper-raised': 'var(--paper-raised)',
        'paper-sunken': 'var(--paper-sunken)',
        line: 'var(--line)',
        'line-soft': 'var(--line-soft)',
        accent: {
          DEFAULT: 'var(--accent)',
          strong: 'var(--accent-strong)',
          soft: 'var(--accent-soft)',
        },
        good: {
          DEFAULT: 'var(--good)',
          soft: 'var(--good-soft)',
        },
        bad: {
          DEFAULT: 'var(--bad)',
          soft: 'var(--bad-soft)',
        },
      },
      borderRadius: {
        control: '10px',
        surface: '18px',
      },
      fontFamily: {
        serif: [
          'ui-serif',
          '"Iowan Old Style"',
          '"Palatino Linotype"',
          '"Hiragino Mincho ProN"',
          '"Noto Serif JP"',
          'serif',
        ],
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          '"Hiragino Kaku Gothic ProN"',
          '"Yu Gothic"',
          '"Noto Sans JP"',
          'sans-serif',
        ],
      },
    },
  },
  plugins: [],
}
