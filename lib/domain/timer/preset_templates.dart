/// A template entry used as the source for seed / replace operations.
///
/// Plain Pure Dart class so the catalog of profiles can be expressed as
/// `const` data without dragging freezed code generation into a place
/// that doesn't actually need copyWith / equality. Identity is by
/// (label, duration, soundId) tuple, but we don't override `==` because
/// instances flow one-way: catalog → seed insert.
class PresetTemplate {
  const PresetTemplate({
    required this.label,
    required this.duration,
    required this.soundId,
  });

  /// Optional display label. Empty string means "show duration only";
  /// the presentation layer formats `duration` via
  /// `formatPresetLabel` for the chip / list label.
  final String label;
  final Duration duration;

  /// Default sound for timers created from this preset. `null` falls
  /// back to `AlarmSoundCatalog.defaultSound.id`.
  final String? soundId;
}

/// One named bundle of [PresetTemplate]s. The "Replace from template"
/// menu lets the user pick a profile and either overwrite or append
/// the contained templates.
class PresetProfile {
  const PresetProfile({required this.id, required this.templates});

  /// Stable identifier used for ARB resolution
  /// (`presetTemplateReplaceProfile{Id}`) and analytics. Not displayed
  /// directly to the user.
  final String id;
  final List<PresetTemplate> templates;
}

/// Phase 9 seed / template profiles. Pure Dart, no I/O.
///
/// Profiles cover three common timer use cases:
///   - `general`: everyday / household timing (default)
///   - `cooking`: kitchen-friendly minute-scale steps
///   - `pomodoro`: developer focus / break cycle
///
/// `PresetTemplates.defaultProfile` is the one seeded into the DB on
/// first launch. The user can later switch via
/// `PresetCollectionNotifier.replaceFromTemplate`.
class PresetTemplates {
  const PresetTemplates._();

  static const PresetProfile general = PresetProfile(
    id: 'general',
    templates: <PresetTemplate>[
      PresetTemplate(
        label: '',
        duration: Duration(seconds: 30),
        soundId: 'default',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 1),
        soundId: 'default',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 3),
        soundId: 'default',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 5),
        soundId: 'default',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 10),
        soundId: 'default',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 30),
        soundId: 'default',
      ),
    ],
  );

  static const PresetProfile cooking = PresetProfile(
    id: 'cooking',
    templates: <PresetTemplate>[
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 1),
        soundId: 'gentle',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 3),
        soundId: 'gentle',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 5),
        soundId: 'gentle',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 10),
        soundId: 'gentle',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 15),
        soundId: 'gentle',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 30),
        soundId: 'gentle',
      ),
    ],
  );

  static const PresetProfile pomodoro = PresetProfile(
    id: 'pomodoro',
    templates: <PresetTemplate>[
      PresetTemplate(
        label: '',
        duration: Duration(seconds: 5),
        soundId: 'urgent',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(seconds: 30),
        soundId: 'urgent',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 1),
        soundId: 'urgent',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 5),
        soundId: 'urgent',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 10),
        soundId: 'urgent',
      ),
      PresetTemplate(
        label: '',
        duration: Duration(minutes: 25),
        soundId: 'urgent',
      ),
    ],
  );

  /// All profiles in display order (matches the "Replace from
  /// template" picker).
  static const List<PresetProfile> all = <PresetProfile>[
    general,
    cooking,
    pomodoro,
  ];

  /// Initial seed profile invoked from Drift `onUpgrade(1 → 2)`.
  static const PresetProfile defaultProfile = general;

  /// Lookup helper for the picker. Returns `null` for unknown ids
  /// rather than throwing — callers route through ARB-mapped UI that
  /// only ever produces valid ids.
  static PresetProfile? findById(String id) {
    for (final PresetProfile p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
