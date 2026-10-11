// @see https://oxc.rs/docs/guide/usage/formatter/config
// @see https://github.com/nozomiishii/configs/tree/main/packages/oxfmt-config

import nozomiishii from "@nozomiishii/oxfmt-config";
import { defineConfig } from "oxfmt";

export default defineConfig({
  ...nozomiishii,
  ignorePatterns: [
    ...nozomiishii.ignorePatterns,
    // superwhisper アプリが mode の保存時に独自の形式で書き直すため
    "home/Documents/superwhisper/**",
    // エディタの UI から開くと oxc は jsonc として末尾カンマを付け、CLI は json として外すため
    "home/Library/Application Support/Code/User/settings.json",
    "home/Library/Application Support/Code/User/keybindings.json",
  ],
});
