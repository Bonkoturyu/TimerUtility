/// Catalog of major-city timezone presets used by the world clock
/// "Add location" picker (Phase 10.5).
///
/// Pure Dart 定数のみ。`freezed` 等のコード生成は意図的に避け、
/// 静的にコンパイル時定数として埋め込むことで起動コストをゼロに
/// する。
///
/// 配置レイヤ: Domain。当初は Infrastructure 層に置いていたが、
/// PR #24 レビューで Presentation → Infrastructure 直接 import が
/// CLAUDE.md の依存方向 (`Presentation → Application → Domain ←
/// Infrastructure`) に違反すると指摘されたため、Pure Dart 定数で
/// データレイヤ依存もないことから Domain へ移動した。Application /
/// Infrastructure / Presentation のいずれの層からも import 可能。
///
/// IANA timezone identifiers は <https://www.iana.org/time-zones> に
/// 準拠。表示名は英語の都市名 (UI 側で多言語化する場合は別途リソース化)。
///
/// 国コード → 代表 TZ マップは `infrastructure/location/country_to_timezone.dart`
/// で実装する。本カタログは「ユーザが手動で都市を選ぶ際の選択肢」のみを
/// 担う。
library;

/// 1 件の都市プリセット。`displayName` は UI に出す英語都市名、
/// `timezoneId` は IANA Time Zone Database 識別子。
class TimezoneCatalogEntry {
  const TimezoneCatalogEntry({
    required this.displayName,
    required this.timezoneId,
  });

  final String displayName;
  final String timezoneId;
}

/// 主要都市プリセット (約 25 件)。地理的に偏らないよう、各大陸の
/// 主要 TZ を最低 1 件以上カバーする方針で選定。
///
/// 並び順は `displayName` の昇順 (case-insensitive A-Z)。実機検証
/// フィードバックで「目的の都市が探しにくい」と指摘されたため、
/// 大陸 grouping (旧: アジア → 中東 → 欧州 → 北米 → 太平洋) から
/// 単純なアルファベット順に変更した。
class TimezoneCatalog {
  const TimezoneCatalog._();

  static const List<TimezoneCatalogEntry> presets = <TimezoneCatalogEntry>[
    TimezoneCatalogEntry(
      displayName: 'Anchorage',
      timezoneId: 'America/Anchorage',
    ),
    TimezoneCatalogEntry(
      displayName: 'Auckland',
      timezoneId: 'Pacific/Auckland',
    ),
    TimezoneCatalogEntry(displayName: 'Bangkok', timezoneId: 'Asia/Bangkok'),
    TimezoneCatalogEntry(displayName: 'Berlin', timezoneId: 'Europe/Berlin'),
    TimezoneCatalogEntry(displayName: 'Chicago', timezoneId: 'America/Chicago'),
    TimezoneCatalogEntry(displayName: 'Denver', timezoneId: 'America/Denver'),
    TimezoneCatalogEntry(displayName: 'Dubai', timezoneId: 'Asia/Dubai'),
    TimezoneCatalogEntry(
      displayName: 'Hong Kong',
      timezoneId: 'Asia/Hong_Kong',
    ),
    TimezoneCatalogEntry(
      displayName: 'Honolulu',
      timezoneId: 'Pacific/Honolulu',
    ),
    TimezoneCatalogEntry(displayName: 'Kolkata', timezoneId: 'Asia/Kolkata'),
    TimezoneCatalogEntry(displayName: 'London', timezoneId: 'Europe/London'),
    TimezoneCatalogEntry(
      displayName: 'Los Angeles',
      timezoneId: 'America/Los_Angeles',
    ),
    TimezoneCatalogEntry(
      displayName: 'Mexico City',
      timezoneId: 'America/Mexico_City',
    ),
    TimezoneCatalogEntry(displayName: 'Moscow', timezoneId: 'Europe/Moscow'),
    TimezoneCatalogEntry(
      displayName: 'New York',
      timezoneId: 'America/New_York',
    ),
    TimezoneCatalogEntry(displayName: 'Paris', timezoneId: 'Europe/Paris'),
    TimezoneCatalogEntry(
      displayName: 'Sao Paulo',
      timezoneId: 'America/Sao_Paulo',
    ),
    TimezoneCatalogEntry(displayName: 'Seoul', timezoneId: 'Asia/Seoul'),
    TimezoneCatalogEntry(displayName: 'Shanghai', timezoneId: 'Asia/Shanghai'),
    TimezoneCatalogEntry(
      displayName: 'Singapore',
      timezoneId: 'Asia/Singapore',
    ),
    TimezoneCatalogEntry(displayName: 'Sydney', timezoneId: 'Australia/Sydney'),
    TimezoneCatalogEntry(displayName: 'Tokyo', timezoneId: 'Asia/Tokyo'),
    TimezoneCatalogEntry(displayName: 'Toronto', timezoneId: 'America/Toronto'),
    TimezoneCatalogEntry(
      displayName: 'Vancouver',
      timezoneId: 'America/Vancouver',
    ),
  ];
}
