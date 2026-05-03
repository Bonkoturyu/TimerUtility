# Git hooks

リポジトリ同梱の Git hook 群。CI が拒否する種類の問題（フォーマット差分など）を
ローカルでコミット前に止めるための予防策。

## インストール（初回 1 回）

リポジトリのルートで:

```sh
git config core.hooksPath tool/git-hooks
```

`core.hooksPath` は `.git/config` に書かれるので、クローンごとに 1 回だけ実行。
hook スクリプト自体は版管理下にあるので、`git pull` するだけで最新化される。

確認:

```sh
git config --get core.hooksPath
# tool/git-hooks
```

## 一時的にバイパス

緊急時など、フォーマット崩れを承知でコミットしたい場合:

```sh
git commit --no-verify -m "..."
```

ただし CI は同じチェックを通すので、push する前には `dart format .` で揃える前提。

## 同梱 hook

### `pre-commit`

ステージ済み Dart ファイルに対して `dart format --set-exit-if-changed` を実行。
差分が出たらコミットを拒否し、`dart format .` での修正を促す。CI の
`dart format --set-exit-if-changed .` ステップと同じ判定基準。

過去に dart format 漏れで CI が落ちたことがあるので、その予防が目的。

## Windows での動作

Git for Windows に同梱の Git Bash (mingw64) で `#!/bin/sh` シェルスクリプトとして
実行される。PowerShell から `git commit` しても hook は Git Bash 経由で動くので、
Windows / macOS / Linux 共通のスクリプトで OK。
