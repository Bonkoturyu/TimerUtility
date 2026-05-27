# Security Policy

セキュリティ脆弱性を発見された場合の報告方法と、本プロジェクトのサポート方針を
記述する。

## 対象バージョン (Supported Versions)

本プロジェクトはまだ正式リリースしていない (現在 `1.0.0+1`、Phase 11.10 で
Play Store 提出予定)。当面、**最新の `main` ブランチ** のみがセキュリティ修正の
対象となる。Play Store リリース後は最新版のみサポート対象とし、過去版にバック
ポートは行わない方針。

| Version | Supported |
| --- | --- |
| `main` (latest) | :white_check_mark: |
| その他 | :x: |

## 脆弱性の報告 (Reporting a Vulnerability)

セキュリティ脆弱性は **公開 Issue を作成せず** に下記いずれかの非公開チャネル
で報告してください。

### 推奨: GitHub Private Vulnerability Reporting

本リポジトリの [Security タブ](https://github.com/Bonkoturyu/TimerUtility/security)
から `Report a vulnerability` を選択し、フォームに沿って非公開で報告できます。
GitHub の暗号化された通知経路でメンテナーに届きます。

### 代替: GitHub プロフィール経由

メンテナー [@Bonkoturyu](https://github.com/Bonkoturyu) の GitHub プロフィール
contact から連絡してください。

> 公開 Issue / Pull Request / Discussions では報告しないでください。修正前に
> 脆弱性詳細が公開されると、悪用される前に修正できなくなります。

## 報告に含めると助かる情報

- 脆弱性の概要 (1〜2 行)
- 再現手順 (具体的なステップ / 環境)
- 影響範囲 (どのコンポーネント / どのバージョンに影響するか)
- 推定される影響度 (情報漏洩 / 任意コード実行 / DoS など)
- 可能であれば PoC コード、ただし攻撃に直接転用できる詳細は控える
- 報告者の連絡先 (謝辞掲載希望の場合は名前 / GitHub アカウントも)

英語または日本語のどちらでも受け付けます。

## 対応プロセス

1. **受領確認**: 報告受領後、可能な限り早く (目安 7 日以内) に受領確認の返信
2. **影響評価**: 報告内容を確認し、影響範囲と修正方針を決定
3. **修正実装**: 非公開 branch で修正を実装、テスト
4. **公開**: 修正版を `main` にマージし、GitHub Release で公開
5. **謝辞**: 報告者の希望に応じて Release notes / CHANGELOG で謝辞を掲載

本プロジェクトは個人運営のため、対応時間は商用 OSS と比較してベストエフォート
となる旨ご了承ください。

## スコープ

### スコープ内 (In scope)

- 本リポジトリのコード ([lib/](lib/) / [android/app/src/main/kotlin/](android/app/src/main/kotlin/))
- ビルド成果物の Android アプリ動作
- 同梱アセット ([assets/sounds/](assets/sounds/))

### スコープ外 (Out of scope)

- 第三者依存パッケージ ([THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 記載) の
  脆弱性 — 各 upstream プロジェクトに直接報告してください
- Flutter / Dart SDK / Android OS / Google Play 等のプラットフォーム側の脆弱性
- ドキュメント / コメント内の typo や記述不備 (通常 Issue で受付)

## 参考

- 行動規範: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- 一般的な貢献ガイド: [CONTRIBUTING.md](CONTRIBUTING.md)
- プライバシーポリシー: [docs/privacy-policy.md](docs/privacy-policy.md)
