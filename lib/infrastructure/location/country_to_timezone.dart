/// ISO 3166-1 alpha-2 国コード → 代表 IANA Time Zone 識別子のマップ
/// (Phase 10.5)。
///
/// `LocationDetectorAdapter` の逆ジオコーディング段階で得られる
/// `Placemark.isoCountryCode` を、世界時計の表示に使う 1 つの IANA TZ
/// に折りたたむための静的辞書。
///
/// 設計上の割り切り:
///   - 1 国 1 TZ。複数 TZ を持つ国 (US / CA / RU / AU / BR / CN) は
///     「最も使用人口の多い首都圏 / 経済圏」を代表に選ぶ。
///     ユーザは初回検出後に手動で都市を切り替えられるので、ここでの
///     代表選択はあくまで初期値の質を保つだけが目的。
///   - `TimezoneCatalog.presets` に含まれる 25 TZ をすべて値域に
///     含める (catalog にあるのに lookup で出てこないと UX が壊れる)。
///   - 値域 ⊂ IANA TZ DB なので、Adapter 側で wrapping せず素通しで
///     `ClockTime` に渡せる。
///
/// `freezed` 等のコード生成は不要 (`TimezoneCatalog` と同じ Pure Dart
/// 定数スタイル)。
library;

class CountryToTimezone {
  const CountryToTimezone._();

  /// 約 40 ヶ国の代表 TZ。`TimezoneCatalog.presets` の全 25 TZ を
  /// 必ず値域に含むこと (`country_to_timezone_test` で検証)。
  static const Map<String, String> _byIsoAlpha2 = <String, String>{
    // East / Southeast Asia
    'JP': 'Asia/Tokyo',
    'KR': 'Asia/Seoul',
    'CN': 'Asia/Shanghai',
    'HK': 'Asia/Hong_Kong',
    'TW': 'Asia/Hong_Kong',
    'SG': 'Asia/Singapore',
    'TH': 'Asia/Bangkok',
    'IN': 'Asia/Kolkata',
    // Middle East
    'AE': 'Asia/Dubai',
    'SA': 'Asia/Dubai',
    'IL': 'Asia/Dubai',
    'TR': 'Europe/Moscow',
    // Europe
    'RU': 'Europe/Moscow',
    'DE': 'Europe/Berlin',
    'FR': 'Europe/Paris',
    'GB': 'Europe/London',
    'IT': 'Europe/Berlin',
    'ES': 'Europe/Paris',
    'NL': 'Europe/Berlin',
    'SE': 'Europe/Berlin',
    'NO': 'Europe/Berlin',
    'FI': 'Europe/Berlin',
    'PL': 'Europe/Berlin',
    'CH': 'Europe/Berlin',
    'AT': 'Europe/Berlin',
    'IE': 'Europe/London',
    'PT': 'Europe/London',
    'GR': 'Europe/Berlin',
    // Africa
    'EG': 'Europe/Berlin',
    'ZA': 'Europe/Berlin',
    'KE': 'Asia/Dubai',
    'NG': 'Europe/Berlin',
    // South America
    'BR': 'America/Sao_Paulo',
    'AR': 'America/Sao_Paulo',
    'CL': 'America/Sao_Paulo',
    // North America (Central/South)
    'MX': 'America/Mexico_City',
    // North America (USA / Canada — 代表は東海岸の主要都市)
    'US': 'America/New_York',
    'CA': 'America/Toronto',
    // Oceania
    'AU': 'Australia/Sydney',
    'NZ': 'Pacific/Auckland',
  };

  /// 国コード → 代表 IANA TZ 解決。未登録は `null` (呼び出し側で次段
  /// fallback、`LocationDetectorAdapter` の場合は `FlutterTimezone`)。
  ///
  /// `Placemark.isoCountryCode` は OS / 端末 / ロケールによって
  /// 大文字 / 小文字混在で返ってくることがあるため、内部で
  /// `toUpperCase()` 正規化してから索引する。
  static String? lookup(String iso) => _byIsoAlpha2[iso.toUpperCase()];
}
