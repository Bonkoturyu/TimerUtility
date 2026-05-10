import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_collection_notifier.dart';
import 'package:timer_utility/application/clock_location_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/domain/clock/clock_collection.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/domain/ports/clock_location_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/clock_location_picker_screen.dart';

class _MockClockLocationRepository extends Mock
    implements ClockLocationRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockLocationFake extends Fake implements ClockLocation {}

/// Pre-seeded variant of the production notifier. Bypasses the
/// async restore + first-launch detection in `build()` so the widget
/// renders the desired collection on the very first frame, while the
/// inherited mutation methods (`addPreset` / `remove` / `reorder`)
/// run their real bodies — that is the seam under test in scenarios
/// 2, 4, and 5 (we observe the resulting `ClockCollection` state via
/// `ProviderContainer.read`).
class _SeededClockCollectionNotifier extends ClockCollectionNotifier {
  _SeededClockCollectionNotifier(this._initial);
  final ClockCollection _initial;

  @override
  ClockCollection build() => _initial;
}

ClockLocation _loc(
  int order,
  String displayName, {
  required String tz,
  bool current = false,
}) => ClockLocation(
  id: 'id-$order',
  displayName: displayName,
  timezoneId: tz,
  isCurrentLocation: current,
  displayOrder: order,
  createdAt: DateTime.utc(2026, 1, 1),
);

Widget _harness({required List<ClockLocation> seeded}) {
  final ClockCollection collection = seeded.isEmpty
      ? ClockCollection.empty()
      : ClockCollection.fromList(seeded);
  final repo = _MockClockLocationRepository();
  final detector = _MockLocationDetector();
  // Mutations on the notifier (`addPreset` / `remove` / `reorder`) fire
  // unawaited persistence calls; stubbing keeps them benign no-ops.
  when(() => repo.findAll()).thenAnswer((_) async => seeded);
  when(() => repo.upsert(any())).thenAnswer((_) async {});
  when(() => repo.delete(any())).thenAnswer((_) async {});
  when(() => repo.replaceAll(any())).thenAnswer((_) async {});
  when(() => detector.detectTimezoneId()).thenAnswer((_) async => 'Etc/UTC');

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(
        Clock.fixed(DateTime.utc(2026, 5, 10, 9)),
      ),
      clockCollectionNotifierProvider.overrideWith(
        () => _SeededClockCollectionNotifier(collection),
      ),
      clockLocationRepositoryProvider.overrideWithValue(repo),
      locationDetectorProvider.overrideWithValue(detector),
    ],
    child: const MaterialApp(
      home: ClockLocationPickerScreen(),
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

ProviderContainer _containerOf(WidgetTester tester) {
  final BuildContext ctx = tester.element(
    find.byType(ClockLocationPickerScreen),
  );
  return ProviderScope.containerOf(ctx);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_ClockLocationFake());
    registerFallbackValue(<ClockLocation>[]);
  });

  group('ClockLocationPickerScreen', () {
    // 全シナリオでサーフェスを縦長に取る理由: catalog 側 (最大 24 件) が
    // ListView.builder で遅延構築されるため、デフォルトサイズでは下方
    // のエントリ (Europe/* / America/*) が viewport 外で `find.byKey`
    // が見つからない。3000dp 確保すれば pinned 6 + catalog 18 件まで
    // 全件 layout される。
    Future<void> setLargeSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    testWidgets('初期表示: pinned 側に Tokyo 1 件、catalog 側から Tokyo は除外される', (
      WidgetTester tester,
    ) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(
        _harness(
          seeded: <ClockLocation>[
            _loc(0, 'Tokyo', tz: 'Asia/Tokyo', current: true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // pinned section
      expect(find.byKey(const Key('clock_picker_pinned_id-0')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('clock_picker_pinned_id-0')),
          matching: find.text('Tokyo'),
        ),
        findsOneWidget,
      );
      // section header に "登録済み (1/6)" が出る
      expect(find.text('登録済み (1/6)'), findsOneWidget);

      // catalog 側に Tokyo はもう出ない (重複除外)
      expect(
        find.byKey(const Key('clock_picker_catalog_Asia/Tokyo')),
        findsNothing,
      );
      // 別 catalog 都市 (Seoul) は出る
      expect(
        find.byKey(const Key('clock_picker_catalog_Asia/Seoul')),
        findsOneWidget,
      );

      // 上限未達なので banner は出ない
      expect(find.byKey(const Key('clock_picker_limit_banner')), findsNothing);
    });

    testWidgets(
      'catalog の Seoul を tap すると notifier.addPreset が走り state.size が 2 に増える',
      (WidgetTester tester) async {
        await setLargeSurface(tester);
        await tester.pumpWidget(
          _harness(
            seeded: <ClockLocation>[
              _loc(0, 'Tokyo', tz: 'Asia/Tokyo', current: true),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final container = _containerOf(tester);
        expect(container.read(clockCollectionNotifierProvider).size, 1);

        await tester.tap(
          find.byKey(const Key('clock_picker_catalog_Asia/Seoul')),
        );
        await tester.pumpAndSettle();

        final ClockCollection next = container.read(
          clockCollectionNotifierProvider,
        );
        expect(next.size, 2);
        // 末尾に Seoul が積まれていること (displayOrder = 1)
        final ClockLocation added = next.all.last;
        expect(added.timezoneId, 'Asia/Seoul');
        expect(added.displayName, 'Seoul');
      },
    );

    testWidgets('上限 6 件: catalog 全行が disabled で limit banner が出る', (
      WidgetTester tester,
    ) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(
        _harness(
          seeded: <ClockLocation>[
            _loc(0, 'Tokyo', tz: 'Asia/Tokyo', current: true),
            _loc(1, 'Seoul', tz: 'Asia/Seoul'),
            _loc(2, 'Shanghai', tz: 'Asia/Shanghai'),
            _loc(3, 'Hong Kong', tz: 'Asia/Hong_Kong'),
            _loc(4, 'Singapore', tz: 'Asia/Singapore'),
            _loc(5, 'Bangkok', tz: 'Asia/Bangkok'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // banner 表示
      expect(
        find.byKey(const Key('clock_picker_limit_banner')),
        findsOneWidget,
      );
      // pinned section header は (6/6)
      expect(find.text('登録済み (6/6)'), findsOneWidget);

      // catalog 側の任意の都市 (Paris) が disabled になっていること
      final ListTile parisTile = tester.widget<ListTile>(
        find.byKey(const Key('clock_picker_catalog_Europe/Paris')),
      );
      expect(parisTile.enabled, isFalse);
      expect(parisTile.onTap, isNull);
    });

    testWidgets(
      'ReorderableListView.onReorder を呼ぶと notifier.reorder で順序が swap される',
      (WidgetTester tester) async {
        await setLargeSurface(tester);
        await tester.pumpWidget(
          _harness(
            seeded: <ClockLocation>[
              _loc(0, 'Tokyo', tz: 'Asia/Tokyo', current: true),
              _loc(1, 'Seoul', tz: 'Asia/Seoul'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final container = _containerOf(tester);
        // 初期順序: Tokyo(0), Seoul(1)
        expect(
          container.read(clockCollectionNotifierProvider).all.map((e) => e.id),
          equals(<String>['id-0', 'id-1']),
        );

        // ReorderableListView の物理 drag は long-press + offset の組み合わせで
        // flaky になりやすいため、widget の onReorder callback を直接呼ぶ。
        // Flutter の post-removal 規約で oldIndex=0 → newIndex=2 を渡すと、
        // screen 側で newIndex -= 1 補正が走り notifier.reorder(0, 1) になる。
        final ReorderableListView reorderable = tester
            .widget<ReorderableListView>(find.byType(ReorderableListView));
        reorderable.onReorder(0, 2);
        await tester.pumpAndSettle();

        expect(
          container.read(clockCollectionNotifierProvider).all.map((e) => e.id),
          equals(<String>['id-1', 'id-0']),
        );
      },
    );

    testWidgets(
      'pinned の delete IconButton を tap すると notifier.remove で 0 件になる',
      (WidgetTester tester) async {
        await setLargeSurface(tester);
        await tester.pumpWidget(
          _harness(
            seeded: <ClockLocation>[
              _loc(0, 'Tokyo', tz: 'Asia/Tokyo', current: true),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final container = _containerOf(tester);
        expect(container.read(clockCollectionNotifierProvider).size, 1);

        await tester.tap(find.byKey(const Key('clock_picker_remove_id-0')));
        await tester.pumpAndSettle();

        expect(container.read(clockCollectionNotifierProvider).size, 0);
        // 削除後は catalog 側に Tokyo が再度現れる
        expect(
          find.byKey(const Key('clock_picker_catalog_Asia/Tokyo')),
          findsOneWidget,
        );
      },
    );
  });
}
