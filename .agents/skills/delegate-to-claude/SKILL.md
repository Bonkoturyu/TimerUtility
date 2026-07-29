---
name: delegate-to-claude
description: Codex SolからClaude Opus 5へ、境界の明確な専門タスクを委譲して構造化結果を返す。ユーザーがOpus 5との協業、別視点レビュー、深い設計検討を求めた場合、または難しいデバッグ、アーキテクチャ、セキュリティ、UI/UXの独立レビューが成果や安全性を実質的に改善する場合に使用する。Claude Code探索、読み取り専用既定、モデル検証、TokenResetTime通知、タイムアウトを扱う。
---

# Claude Opus 5へ委譲

Claude Opus 5を外部の専門エージェントとして呼び出し、要求統合と最終判断はSolが保持する。

## ワークフロー

1. 委譲が成果または安全性を実質的に改善するか判断する。定型作業や委譲説明の方が長くなる作業はSolが行う。
2. 委譲前に、Opus 5へ渡す作業範囲をユーザーへ短く通知する。
3. 次を含む自己完結した依頼文を作る。
   - 目的
   - 対象ファイルまたは調査範囲
   - 変更禁止範囲
   - `AGENTS.md`上の制約
   - 受入条件
   - 必要な検証
4. 初回または実行経路が変わった場合は先に疎通確認する。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  .agents/skills/delegate-to-claude/scripts/invoke-claude.ps1 `
  -CheckOnly
```

5. 調査、設計、レビューは既定の読み取り専用モードで呼び出す。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  .agents/skills/delegate-to-claude/scripts/invoke-claude.ps1 `
  -PromptFile "<UTF-8の依頼ファイル>" `
  -Effort high `
  -MaxTurns 20
```

6. リポジトリ調査が不要で依頼文だけで回答できる場合は`-NoTools`を付ける。
7. 短い依頼は`-Prompt`、大きな差分や仕様は`-PromptFile`または`-PromptFromStdin`を使う。
8. 実装を明示的に委譲するときだけ`-AllowEdits`を付ける。ユーザー確認必須ファイルを含む場合は、先にその編集承認を得る。同一ファイルをSolや別Agentが同時編集してはならない。
9. JSON出力の`status`と`model_verified`を確認する。
   - `success`: `claude.result`を一次資料、コード、diff、自動テストと照合してから採用する。
   - `token_limit`: `token_reset_time`と`token_reset_time_jst`を通知する。時刻がなければ推測しない。同じ依頼を自動再試行しない。
   - `timeout`: timeoutとして報告し、TokenLimitと混同しない。
   - `error` / `not_found`: 診断内容を報告し、別Claudeモデルへ自動切替しない。
10. UI/UX・画像・ビジュアル作業でOpus 5を利用できない場合は、別手段へ自動切替せずユーザー判断を仰ぐ。それ以外はSolが完遂可能なら引き継ぐ。

## 委譲境界

- branch、commit、push、merge、rebase、reset、clean、tag、PR操作をClaudeへ委譲しない。
- Claudeによる追加のSubAgent起動を禁止する。
- 認証情報、APIキー、トークン、keystore秘密情報を依頼文へ含めない。
- Claudeの出力を未検証のまま完成扱いにしない。
- 最終的な要求解釈、統合、Git判断、ユーザー報告はSolが行う。

## ランチャー

`scripts/invoke-claude.ps1`は次の順序でClaude Codeを探索する。

1. `CLAUDE_CODE_EXECUTABLE`
2. `PATH`上の`claude`
3. VS Code / VS Code InsidersのClaude Code拡張機能に同梱された`claude.exe`

ランチャーは`--model opus`を指定し、応答メタデータで正規モデル名`claude-opus-5`を検証する。別モデルへ解決された場合、またはモデル名を検証できない場合は成功扱いにしない。
