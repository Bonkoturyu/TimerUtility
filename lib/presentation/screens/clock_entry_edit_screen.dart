import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/clock_entry_collection_notifier.dart';
import '../../domain/clock/clock_entry.dart';
import '../../domain/clock/clock_entry_collection.dart';
import '../../domain/clock/exceptions.dart';
import '../../domain/clock/timezone_catalog.dart';
import '../../l10n/app_localizations.dart';

/// World clock entry edit screen. Reached from the Clock tab's
/// right-bottom FAB ([ClockEntryEditScreen.routeLocation]). One screen
/// completes the full lifecycle: list pinned cities, drag to reorder,
/// delete, and add from the curated [TimezoneCatalog]. There is
/// intentionally no in-screen FAB — taps on a catalog row are the
/// single add path so the user never has to choose between two
/// equivalent affordances.
///
/// Naming note: the displayed AppBar title is "時計を追加・編集"
/// (Japanese) / "Add or edit clocks" (English) — this app's world clock
/// is a *time-difference* UI, so user-facing copy talks about "clocks"
/// rather than "cities". The original Phase 10.5 implementation used
/// `Location` based identifiers (`ClockLocationPickerScreen`,
/// `/clock/locations`, `clockLocationPicker*` ARB keys); Phase 11
/// renamed presentation to `ClockEntryEdit*` (PR #30) and the underlying
/// domain to `ClockEntry` / `ClockEntryCollection` (this commit) to keep
/// internal identifiers aligned with the displayed copy.
///
/// 6-entry cap is enforced both by the aggregate
/// ([MaxClockEntryCountExceededException]) and by visually disabling
/// catalog rows when [ClockEntryCollection.isFull]. The SnackBar fallback
/// catches the exception in the rare case a stale UI state slips
/// through (multi-tap race), keeping the cap a user-visible event
/// rather than an unhandled throw.
class ClockEntryEditScreen extends ConsumerWidget {
  const ClockEntryEditScreen({super.key});

  static const String routeLocation = '/clock/entries';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ClockEntryCollection collection = ref.watch(
      clockEntryCollectionNotifierProvider,
    );
    final List<ClockEntry> pinned = collection.all;
    final bool isFull = collection.isFull;
    // Set lookup keeps the per-frame filter O(catalog) rather than
    // O(catalog * pinned). Catalog (~24) and pinned (≤6) are tiny, but
    // the conversion also makes the intent ("dedupe by timezoneId")
    // obvious.
    final Set<String> registeredTz = pinned
        .map((ClockEntry e) => e.timezoneId)
        .toSet();
    final List<TimezoneCatalogEntry> available = TimezoneCatalog.presets
        .where((TimezoneCatalogEntry e) => !registeredTz.contains(e.timezoneId))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l.clockEntryEditAppBarTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            key: const Key('clock_entry_edit_pinned_header'),
            text: l.clockEntryEditSectionPinned(
              pinned.length,
              ClockEntryCollection.maxSize,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: pinned.length,
              onReorder: (int oldIndex, int newIndex) {
                // Translate Flutter's post-removal `newIndex` convention
                // into the destination index that
                // `ClockEntryCollection.reorder` expects.
                if (newIndex > oldIndex) newIndex -= 1;
                if (oldIndex == newIndex) return;
                ref
                    .read(clockEntryCollectionNotifierProvider.notifier)
                    .reorder(oldIndex, newIndex);
              },
              itemBuilder: (BuildContext context, int index) {
                final ClockEntry entry = pinned[index];
                return ListTile(
                  key: Key('clock_entry_edit_pinned_${entry.id}'),
                  title: Text(entry.displayName),
                  subtitle: Text(entry.timezoneId),
                  trailing: IconButton(
                    key: Key('clock_entry_edit_remove_${entry.id}'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ref
                          .read(clockEntryCollectionNotifierProvider.notifier)
                          .remove(entry.id);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(
            key: const Key('clock_entry_edit_available_header'),
            text: l.clockEntryEditSectionAvailable,
          ),
          if (isFull)
            Container(
              key: const Key('clock_entry_edit_limit_banner'),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l.clockEntryEditLimitReached(ClockEntryCollection.maxSize),
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
                        l.clockEntryEditCatalogEmpty,
                        key: const Key('clock_entry_edit_catalog_empty'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TimezoneCatalogEntry e = available[index];
                      return ListTile(
                        key: Key('clock_entry_edit_catalog_${e.timezoneId}'),
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
          .read(clockEntryCollectionNotifierProvider.notifier)
          .addPreset(
            timezoneId: entry.timezoneId,
            displayName: entry.displayName,
          );
    } on MaxClockEntryCountExceededException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.clockEntryEditLimitReached(e.maxSize))),
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
