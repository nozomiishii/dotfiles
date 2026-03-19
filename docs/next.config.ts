import { createMDX } from 'fumadocs-mdx/next';
import type { NextConfig } from 'next';

const isProd = process.env.NODE_ENV === 'production';
const repoName = 'dotfiles';

const config: NextConfig = {
  reactStrictMode: true,
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
  basePath: isProd ? `/${repoName}` : '',
  assetPrefix: isProd ? `https://nozomiishii.github.io/${repoName}/` : '',
};

const withMDX = createMDX();

export default withMDX(config);
