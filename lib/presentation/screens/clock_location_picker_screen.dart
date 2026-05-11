import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/clock_collection_notifier.dart';
import '../../domain/clock/clock_collection.dart';
import '../../domain/clock/clock_location.dart';
import '../../domain/clock/exceptions.dart';
import '../../domain/clock/timezone_catalog.dart';
import '../../l10n/app_localizations.dart';

/// Phase 10.5 picker screen for the world clock. Reached from the
/// Clock tab's right-bottom FAB (`ClockPage.buildFab`, PR #29 follow-up
/// #2). One screen completes the full lifecycle: list pinned cities,
/// drag to reorder, delete, and add from the curated [TimezoneCatalog].
/// There is intentionally no in-screen FAB — taps on a catalog row are
/// the single add path so the user never has to choose between two
/// equivalent affordances.
///
/// Naming note: the displayed AppBar title is "時計を追加・編集"
/// (Japanese) / "Add or edit clocks" (English) — this app's world clock
/// is a *time-difference* UI, so user-facing copy talks about "clocks"
/// rather than "cities". The class name [ClockLocationPickerScreen],
/// route `/clock/locations`, and ARB keys
/// (`clockLocationPickerAppBarTitle`, `clockMenuEditLocations`, etc.)
/// still carry their original `Location` heritage from Phase 10.5 —
/// renaming them is tracked as a future task in BACKLOG.md (Phase 11)
/// because the blast radius (tests, docs, comments) is large compared
/// to a UX-only patch.
///
/// 6-entry cap is enforced both by the aggregate
/// ([MaxClockLocationCountExceededException]) and by visually disabling
/// catalog rows when [ClockCollection.isFull]. The SnackBar fallback
/// catches the exception in the rare case a stale UI state slips
/// through (multi-tap race), keeping the cap a user-visible event
/// rather than an unhandled throw.
class ClockLocationPickerScreen extends ConsumerWidget {
  const ClockLocationPickerScreen({super.key});

  static const String routeLocation = '/clock/locations';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ClockCollection collection = ref.watch(
      clockCollectionNotifierProvider,
    );
    final List<ClockLocation> pinned = collection.all;
    final bool isFull = collection.isFull;
    // Set lookup keeps the per-frame filter O(catalog) rather than
    // O(catalog * pinned). Catalog (~24) and pinned (≤6) are tiny, but
    // the conversion also makes the intent ("dedupe by timezoneId")
    // obvious.
    final Set<String> registeredTz = pinned
        .map((ClockLocation e) => e.timezoneId)
        .toSet();
    final List<TimezoneCatalogEntry> available = TimezoneCatalog.presets
        .where((TimezoneCatalogEntry e) => !registeredTz.contains(e.timezoneId))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l.clockLocationPickerAppBarTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            key: const Key('clock_picker_pinned_header'),
            text: l.clockLocationPickerSectionPinned(
              pinned.length,
              ClockCollection.maxSize,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: pinned.length,
              onReorder: (int oldIndex, int newIndex) {
                // Translate Flutter's post-removal `newIndex` convention
                // into the destination index that
                // `ClockCollection.reorder` expects.
                if (newIndex > oldIndex) newIndex -= 1;
                if (oldIndex == newIndex) return;
                ref
                    .read(clockCollectionNotifierProvider.notifier)
                    .reorder(oldIndex, newIndex);
              },
              itemBuilder: (BuildContext context, int index) {
                final ClockLocation loc = pinned[index];
                return ListTile(
                  key: Key('clock_picker_pinned_${loc.id}'),
                  title: Text(loc.displayName),
                  subtitle: Text(loc.timezoneId),
                  trailing: IconButton(
                    key: Key('clock_picker_remove_${loc.id}'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ref
                          .read(clockCollectionNotifierProvider.notifier)
                          .remove(loc.id);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(
            key: const Key('clock_picker_available_header'),
            text: l.clockLocationPickerSectionAvailable,
          ),
          if (isFull)
            Container(
              key: const Key('clock_picker_limit_banner'),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l.clockLocationPickerLimitReached(ClockCollection.maxSize),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: available.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.clockLocationPickerCatalogEmpty,
                        key: const Key('clock_picker_catalog_empty'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TimezoneCatalogEntry e = available[index];
                      return ListTile(
                        key: Key('clock_picker_catalog_${e.timezoneId}'),
                        title: Text(e.displayName),
                        subtitle: Text(e.timezoneId),
                        enabled: !isFull,
                        onTap: isFull ? null : () => _onAdd(context, ref, e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _onAdd(BuildContext context, WidgetRef ref, TimezoneCatalogEntry entry) {
    final AppLocalizations l = AppLocalizations.of(context);
    try {
      ref
          .read(clockCollectionNotifierProvider.notifier)
          .addPreset(
            timezoneId: entry.timezoneId,
            displayName: entry.displayName,
          );
    } on MaxClockLocationCountExceededException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.clockLocationPickerLimitReached(e.maxSize))),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
