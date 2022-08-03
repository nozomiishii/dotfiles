// https://prettier.io/docs/en/options.html
module.exports = {
  arrowParens: 'always',
  bracketSpacing: true,
  htmlWhitespaceSensitivity: 'css',
  insertPragma: false,
  bracketSameLine: false,
  jsxSingleQuote: false,
  printWidth: 100,
  proseWrap: 'preserve',
  quoteProps: 'as-needed',
  requirePragma: false,
  semi: true,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'all',
  useTabs: false,

  plugins: [require('prettier-plugin-sh')],

  overrides: [
    {
      files: ['*.md'],
      options: {
        parser: 'markdown-nocjsp',
      },
    },
    {
      files: '*.mdx',
      options: {
        parser: 'mdx-nocjsp',
      },
    },
  ],
};
