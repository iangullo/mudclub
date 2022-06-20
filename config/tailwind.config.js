const colors = require('tailwindcss/colors')
//const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  darkMode: 'media', // or 'media' or 'class'
  content: [
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/*.{erb,haml,html,slim}',
    './node_modules/flowbite/**/*.js'
  ],
  theme: {
    colors: {
      'blue': '#1A56DB',
      'orange': '#ff7849',
      'green': '#046C4E',
      'indigo': '#362F78',
    },
    extend: {
      fontFamily: {
        sans: ['font-sans'],
        serif: ['font-serif']
//        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('flowbite/plugin'),
  ]
}
