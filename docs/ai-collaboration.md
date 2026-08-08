# AI 協働・SubAgent 運用仕様

## 1. 目的と正典

本書は、TimerUtility におけるメインエージェント、Codex SubAgent、
Claude Opus 5 の役割分担と委譲境界を定義する。

- 絶対制約と Git / PR 権限の正典: `CLAUDE.md`（`AGENTS.md` はミラー）
- AI 協働の詳細仕様: 本書
- 短期の作業状態: `tasklist.md`
- Phase 計画と DoD: `BACKLOG.md`

委譲は権限を拡張しない。子エージェントや外部モデルにも、正典の確認必須ファイル、
Git / PR 制約、エスカレーション条件をそのまま適用する。

## 2. 役割

| 役割 | 主な責務 | 禁止・返却条件 |
| --- | --- | --- |
| メインエージェント | 要件解釈、Plan、設計判断、統合、最終検証、ユーザー報告 | 判断責任を委譲先へ丸投げしない |
| `impl-helper` (Terra / high) | 判断を多少含む、仕様確定済みのコード・テスト・機械的編集 | 再委譲、横断設計、割当外ファイルの編集 |
| `luna-helper` (Luna / max) | 大量の機械的編集、文書同期、境界付き調査、独立検証 | 再委譲、曖昧な設計判断、割当外ファイルの編集 |
| Claude Opus 5 | 境界付きの調査、設計批評、レビュー、検証 | SubAgent 起動、Git 操作、無断編集、最終意思決定 |

原則として Sol がメインの所有者となり、Opus 5 の出力は AI レビュアーの仮説として扱う。
外部仕様の主張やレビュー指摘は、`CLAUDE.md` の「ソース信用原則」に従って裏取りする。

## 3. 難タスクの進め方

次のいずれかに該当する場合は `.agents/skills/hard-task-protocol/SKILL.md` を使う。

- 独立した手順が 3 つ以上ある
- 複数ファイルまたは複数レイヤーを横断する
- 仕様、実装、検証のいずれかに未知や高リスク項目がある

着手時に完了条件、未知、検証手段、変更対象を `tasklist.md` へ記録する。
調査と設計、実装、検証を分け、メインエージェントが差分全体を統合して完了判定する。

## 4. Codex SubAgent

### 4.1 実行境界

- メイン以外の同時実行は 1 Agent まで
- SubAgent から別の SubAgent への再帰委譲は禁止
- メインと SubAgent が同じファイルを同時編集しない
- 編集を依頼する場合は、所有ファイルまたは責任範囲を明示する
- 調査だけなら読み取り専用とし、変更を行わせない
- `git commit`、`git push`、PR 作成、マージは委譲しない

`.codex/config.toml` は未指定 SubAgent の既定を Terra / high とし、
`impl-helper` と `luna-helper` を登録する。`luna-helper` は Luna / max を役割別設定で
上書きする。同時実行上限は1体を維持する。上限は並列数だけを制御するため、
再帰禁止や編集境界は本書と各 Agent 指示で補完する。

### 4.2 使い分け

| 条件 | 担当 |
| --- | --- |
| 単一の短い作業、要件解釈、設計判断、統合、最終検証 | メインエージェント |
| 仕様確定済みで、実装上の局所判断を含むコード・テスト | `impl-helper` (Terra / high) |
| 大量の機械的編集、翻訳・文書同期、検索条件が明確な調査、独立検証 | `luna-helper` (Luna / max) |

SubAgent はコスト削減だけを目的に起動せず、メイン会話のコンテキストを分離しながら
独立した成果物または検証結果を返せる場合に積極利用する。推論レベルを上げても、
タスクの境界、停止条件、検証方法は省略しない。

### 4.3 委譲パケット

最低限、次を明記する。

1. 目的と期待成果物
2. 対象ファイルまたは責任範囲
3. 読み取り専用か編集可か
4. 遵守する制約
5. 実行すべき検証
6. 完了時の報告形式

## 5. Claude Opus 5 への委譲

### 5.1 用途

Opus 5 は、設計批評、独立レビュー、原因仮説、選択肢比較など、
メインとは異なる視点が有効な境界付きタスクへ使う。
通常の実装担当や無制限なリポジトリ探索には使わない。

### 5.2 事前確認

最初にランチャーの自己診断を実行する。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .agents/skills/delegate-to-claude/scripts/invoke-claude.ps1 `
  -CheckOnly
```

自己診断では Claude Code の発見、`opus` が `claude-opus-5` を指すこと、
構造化出力とセッション上限解析、プロセス終了処理を確認する。

### 5.3 実行例

既定は読み取り専用の Plan モードとする。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .agents/skills/delegate-to-claude/scripts/invoke-claude.ps1 `
  -PromptFile .tmp/opus-review-prompt.md `
  -Effort high `
  -MaxTurns 20 `
  -TimeoutSeconds 240
```

- 純粋な思考タスクは `-NoTools` を指定する
- `-AllowEdits` は、ユーザーが編集を明示的に許可し、対象ファイルを限定した場合だけ使う
- スクリーンショットや GUI の目視確認はランチャー対象外。必要ならユーザーへ添付を依頼する
- プロンプトやログへ秘密情報、個人プロファイル、認証情報を含めない

### 5.4 結果の扱い

ランチャーは次の `status` を返す。

| status | 対応 |
| --- | --- |
| `success` | 出力を仮説として検証し、採否をメインが決める |
| `token_limit` | `TokenLimit` と `TokenResetTime` を報告し、同じ呼び出しを再試行しない |
| `timeout` | タスクを小さく分割し直す。自動再試行しない |
| `error` | `ErrorOutput` と終了コードを確認し、原因を切り分ける |
| `not_found` | Claude Code CLI または VS Code 拡張の配置を確認する |

モデルを勝手に変更して成功扱いにしない。`RequestedModel=opus` と
`ModelVerified=true` が確認できない場合は、Opus 5 のレビューとして扱わない。

## 6. 完了条件

- 指定された成果物とテストが揃っている
- `git diff --check` に問題がない
- 変更対象に応じた validator、静的解析、テストが成功している
- 実機でのみ確認できる項目を「検証済み」と表現していない
- `tasklist.md` と最終報告が実際の状態に一致している
- 委譲結果の採用箇所は、メインエージェントが直接確認している

## 7. 参考にした仕組み

| 参照元 | 採用した要素 | 採用しなかった要素 |
| --- | --- | --- |
| Avatar-Platform-Doctor | 難タスクの完了条件、未知管理、段階的検証 | 旧 Codex 設定名や本プロジェクトと異なる検証コマンド |
| Pocket-Dragon-Dungeon | Opus ランチャー、構造化 status、リセット時刻の抽出 | Unity 固有の指示と検証 |
| VRChat-World_Luxury_Cruise_Ship_PRETTY_MUCH | メイン所有、境界付き Opus 委譲 | 固定の引き継ぎファイル。既存の `tasklist.md` / `BACKLOG.md` を使用する |

Codex 設定と Skill 配置は現行の公式仕様を優先する。

- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference#configtoml)
- [Codex Skills](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills)
- [Avatar-Platform-Doctor](https://github.com/Bonkoturyu/Avatar-Platform-Doctor)
- [Pocket-Dragon-Dungeon](https://github.com/Bonkoturyu/Pocket-Dragon-Dungeon)
- [VRChat-World_Luxury_Cruise_Ship_PRETTY_MUCH](https://github.com/Bonkoturyu/VRChat-World_Luxury_Cruise_Ship_PRETTY_MUCH)
