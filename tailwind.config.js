const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    './src/**/*.html',
    './src/**/*.js',
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    theme: {
      colors: {
        transparent: 'transparent',
        current: 'currentColor',
        white: colors.white,
        gray: colors.coolGray,
        indigo: colors.indigo,
        blue: colors.blue,
        red: colors.red,
      },
      fontFamily: {
        sans: ['font-sans'],
        serif: ['font-serif'],
      },
      extend: {
        spacing: {
          '128': '32rem',
          '144': '36rem',
        },
        borderRadius: {
          '4xl': '2rem',
        }
      }
    }  },
  variants: {
    extend: {},
  },
  plugins: [],
}
