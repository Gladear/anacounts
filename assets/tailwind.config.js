// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "assets/js/**/*.js",
    "lib/*_web.ex",
    "lib/*_web/**/*.*ex",
  ],
  theme: {
    borderRadius: {
      component: "0.375rem",
      container: "1rem",
      full: "9999px",
    },
    extend: {
      colors: {
        // Theme colors
        theme: {
          50: "#fff0ee",
          100: "#ffcab9",
          200: "#ffa78b",
          300: "#ff845d",
          400: "#ff602e",
          500: "#ff3d00",
          600: "#d13200",
          700: "#a22700",
          800: "#741c00",
          900: "#461100",
          950: "#170600",
        },
      },
      spacing: {
        xs: "1.5rem",
        sm: "2rem",
        md: "2.5rem",
      },
      width: {
        prose: "65ch",
      },
      fontFamily: {
        sans: ["Lato", ...defaultTheme.fontFamily.sans],
      },
      animation: {
        "fade-in": "fade-in 150ms ease-in forwards",
        "backdrop-fade-in": "backdrop-fade-in 150ms ease-in forwards",
        "slide-in": "slide-in 150ms ease forwards",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
        "backdrop-fade-in": {
          from: { "backgroud-color": "transparent" },
          to: { "background-color": "rgba(0, 0, 0, 0.6)" },
        },
        "slide-in": {
          from: { translate: "0 1rem" },
          to: { translate: "0 0" },
        },
      },
    },
  },
  plugins: [
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
  ],

  corePlugins: {
    container: false,
  },
};
