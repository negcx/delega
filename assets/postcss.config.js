const purgecss = require("@fullhuman/postcss-purgecss")({
  content: ["../lib/delega_web/templates/**/*.html.eex"],
  defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || []
});

module.exports = {
  plugins: [
    require("tailwindcss"),
    require("autoprefixer"),
    ...(process.env.NODE_ENV === "production" ? purgecss : [])
  ]
};
