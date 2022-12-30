/* MudClub - Simple Rails app to manage a team sports club.
   Copyright (C) 2023  Iván González Angullo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.

  contact email - iangullo@gmail.com.
*/
const colors = require('tailwindcss/colors')
//const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  darkMode: 'media', // or 'media' or 'class'
  content: [
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{erb,haml,html,slim}',
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
