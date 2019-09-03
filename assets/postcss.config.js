const purgecss = require("@fullhuman/postcss-purgecss")({
  content: ["../lib/delega_web/templates/**/*.html.eex"],
  defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || []
});

module.exports = {
  plugins: [
    require("tailwindcss"),
    require("autoprefixer"),
    ...(process.env.MIX_ENV === "prod" ? [purgecss] : [])
  ]
};
