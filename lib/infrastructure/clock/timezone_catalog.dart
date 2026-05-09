/// Catalog of major-city timezone presets used by the world clock
/// "Add location" picker (Phase 10.5).
///
/// Pure Dart 定数のみ。`freezed` 等のコード生成は意図的に避け、
/// 静的にコンパイル時定数として埋め込むことで起動コストをゼロに
/// する (`location_detector_adapter` と一緒に Infrastructure 層に
/// 配置する点だけが domain との分離理由)。
///
/// IANA timezone identifiers は <https://www.iana.org/time-zones> に
/// 準拠。表示名は英語の都市名 (UI 側で多言語化する場合は別途リソース化)。
///
/// 国コード → 代表 TZ マップは別セッション (`location_detector_adapter`)
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
/// 並び順は「日本に近い順 (アジア → 中東 → 欧州 → 大西洋 → 北米東 →
/// 北米中央 → 北米西 → 太平洋)」。リスト UI でそのまま表示しても
/// ユーザがスクロールしやすい順番。
class TimezoneCatalog {
  const TimezoneCatalog._();

  static const List<TimezoneCatalogEntry> presets = <TimezoneCatalogEntry>[
    // Asia
    TimezoneCatalogEntry(displayName: 'Tokyo', timezoneId: 'Asia/Tokyo'),
    TimezoneCatalogEntry(displayName: 'Seoul', timezoneId: 'Asia/Seoul'),
    TimezoneCatalogEntry(displayName: 'Shanghai', timezoneId: 'Asia/Shanghai'),
    TimezoneCatalogEntry(
      displayName: 'Hong Kong',
      timezoneId: 'Asia/Hong_Kong',
    ),
    TimezoneCatalogEntry(
      displayName: 'Singapore',
      timezoneId: 'Asia/Singapore',
    ),
    TimezoneCatalogEntry(displayName: 'Bangkok', timezoneId: 'Asia/Bangkok'),
    TimezoneCatalogEntry(displayName: 'Kolkata', timezoneId: 'Asia/Kolkata'),
    // Middle East
    TimezoneCatalogEntry(displayName: 'Dubai', timezoneId: 'Asia/Dubai'),
    // Europe / Russia
    TimezoneCatalogEntry(displayName: 'Moscow', timezoneId: 'Europe/Moscow'),
    TimezoneCatalogEntry(displayName: 'Berlin', timezoneId: 'Europe/Berlin'),
    TimezoneCatalogEntry(displayName: 'Paris', timezoneId: 'Europe/Paris'),
    TimezoneCatalogEntry(displayName: 'London', timezoneId: 'Europe/London'),
    // South America
    TimezoneCatalogEntry(
      displayName: 'Sao Paulo',
      timezoneId: 'America/Sao_Paulo',
    ),
    // North America East
    TimezoneCatalogEntry(
      displayName: 'New York',
      timezoneId: 'America/New_York',
    ),
    TimezoneCatalogEntry(displayName: 'Toronto', timezoneId: 'America/Toronto'),
    // North America Central
    TimezoneCatalogEntry(
      displayName: 'Mexico City',
      timezoneId: 'America/Mexico_City',
    ),
    TimezoneCatalogEntry(displayName: 'Chicago', timezoneId: 'America/Chicago'),
    // North America Mountain
    TimezoneCatalogEntry(displayName: 'Denver', timezoneId: 'America/Denver'),
    // North America West
    TimezoneCatalogEntry(
      displayName: 'Los Angeles',
      timezoneId: 'America/Los_Angeles',
    ),
    TimezoneCatalogEntry(
      displayName: 'Vancouver',
      timezoneId: 'America/Vancouver',
    ),
    // Pacific
    TimezoneCatalogEntry(
      displayName: 'Anchorage',
      timezoneId: 'America/Anchorage',
    ),
    TimezoneCatalogEntry(
      displayName: 'Honolulu',
      timezoneId: 'Pacific/Honolulu',
    ),
    // Oceania
    TimezoneCatalogEntry(displayName: 'Sydney', timezoneId: 'Australia/Sydney'),
    TimezoneCatalogEntry(
      displayName: 'Auckland',
      timezoneId: 'Pacific/Auckland',
    ),
  ];
}
