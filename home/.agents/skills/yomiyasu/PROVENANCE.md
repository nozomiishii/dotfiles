# 出典

このフォルダは [nanaism/yomiyasu](https://github.com/nanaism/yomiyasu) の `skills/yomiyasu/` を、コミット `db78b9bc5e868549b517a037df7a4d1c93edac23`（バージョン 3.1.0）から写したものである。

ライセンスは同じフォルダの `LICENSE`（MIT、Copyright (c) 2026 nanaism）と `UNICODE-LICENSE.txt` に従う。

dotfiles には外部スキルを固定する仕組みが無い。`npx skills add` は実行した環境のスキル置き場へ入れるだけで、このリポジトリの `home/` には残らない。そのため、README の「Codex で使うリポジトリに置く」と同じくフォルダを写し、版は上のコミットで固定した。

`home/.claude/skills` は `home/.agents/skills` へのシンボリックリンクなので、この正本だけで両方から読める。
