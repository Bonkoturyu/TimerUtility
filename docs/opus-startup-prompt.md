# Claude Opus スタートアッププロンプト（廃止）

この文書は、Claude Opus 4.7 の直接セッションへ長い初期プロンプトを貼り付ける
旧運用との互換用エントリである。現行運用では使用しない。

現在の正典は次のとおり。

- 絶対制約と Git / PR 権限: `CLAUDE.md`
- AI 協働、SubAgent、Opus 5 委譲: `docs/ai-collaboration.md`
- Opus 5 委譲 Skill: `.agents/skills/delegate-to-claude/SKILL.md`
- 委譲ランチャー:
  `.agents/skills/delegate-to-claude/scripts/invoke-claude.ps1`

Claude Code の直接セッションでも `CLAUDE.md` を読み、同じ権限制約と
エスカレーション条件に従う。個人プロファイル、認証情報、秘密情報を
リポジトリ内のスタートアッププロンプトへ記録しない。

移行理由は、モデル名の固定、責務の重複、個人環境への依存をなくし、
委譲目的・対象・禁止事項・検証方法をタスク単位で明示するためである。
