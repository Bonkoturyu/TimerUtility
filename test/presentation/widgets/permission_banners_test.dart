import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/permission_banners.dart';

class _MockPermissionNotifier extends Mock implements PermissionNotifier {}

/// Builds a [PermissionNotifier] subclass override that exposes [state]
/// as the build() return and forwards mutating calls to [delegate] for
/// `mocktail` `verify()` assertions.
PermissionNotifier Function() _notifierBuilder({
  required PermissionState state,
  required PermissionNotifier delegate,
}) {
  return () => _StubPermissionNotifier(initial: state, delegate: delegate);
}

class _StubPermissionNotifier extends PermissionNotifier {
  _StubPermissionNotifier({required this.initial, required this.delegate});

  final PermissionState initial;
  final PermissionNotifier delegate;

  @override
  PermissionState build() => initial;

  @override
  Future<void> refresh() => delegate.refresh();

  @override
  Future<void> requestNotification() => delegate.requestNotification();

  @override
  Future<void> requestScheduleExactAlarm() =>
      delegate.requestScheduleExactAlarm();

  @override
  Future<void> openFullScreenIntentSettings() =>
      delegate.openFullScreenIntentSettings();

  @override
  Future<bool> openSettings() => delegate.openSettings();
}

Widget _harness({
  required PermissionState state,
  required PermissionNotifier delegate,
}) {
  return ProviderScope(
    overrides: <Override>[
      permissionNotifierProvider.overrideWith(
        _notifierBuilder(state: state, delegate: delegate),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: <Locale>[Locale('ja'), Locale('en')],
      home: Scaffold(
        body: Padding(padding: EdgeInsets.all(16), child: PermissionBanners()),
      ),
    ),
  );
}

const _granted = PermissionState(
  postNotifications: DomainPermissionStatus.granted,
  scheduleExactAlarm: DomainPermissionStatus.granted,
  fullScreenIntent: DomainPermissionStatus.granted,
);

void main() {
  setUpAll(() {
    // mocktail fallback for Future-returning methods is not needed here.
  });

  group('PermissionBanners', () {
    testWidgets(
      'post_notifications denied → [重要] ラベル + critical accent (8.0pt)',
      (WidgetTester tester) async {
        final delegate = _MockPermissionNotifier();
        await tester.pumpWidget(
          _harness(
            state: _granted.copyWith(
              postNotifications: DomainPermissionStatus.denied,
            ),
            delegate: delegate,
          ),
        );

        expect(
          find.byKey(const Key('banner_post_notifications')),
          findsOneWidget,
        );
        // Text.rich の TextSpan 内テキストは find.text と直接マッチしない
        // ため、ラベル + タイトル両方を含むことを textContaining で確認。
        expect(find.textContaining('[重要]'), findsOneWidget);
        expect(find.textContaining('通知が無効です'), findsOneWidget);

        final Container accent = tester.widget<Container>(
          find.byKey(const Key('banner_post_notifications_accent')),
        );
        expect(accent.constraints?.maxWidth, 8.0);
      },
    );

    testWidgets(
      'schedule_exact_alarm denied → [推奨] ラベル + recommended accent (5.0pt)',
      (WidgetTester tester) async {
        final delegate = _MockPermissionNotifier();
        await tester.pumpWidget(
          _harness(
            state: _granted.copyWith(
              scheduleExactAlarm: DomainPermissionStatus.denied,
            ),
            delegate: delegate,
          ),
        );

        expect(find.byKey(const Key('banner_exact_alarm')), findsOneWidget);
        expect(find.textContaining('[推奨]'), findsOneWidget);

        final Container accent = tester.widget<Container>(
          find.byKey(const Key('banner_exact_alarm_accent')),
        );
        expect(accent.constraints?.maxWidth, 5.0);
      },
    );

    testWidgets(
      'full_screen_intent denied → [補助] ラベル + supplementary accent (3.0pt)',
      (WidgetTester tester) async {
        final delegate = _MockPermissionNotifier();
        await tester.pumpWidget(
          _harness(
            state: _granted.copyWith(
              fullScreenIntent: DomainPermissionStatus.denied,
            ),
            delegate: delegate,
          ),
        );

        expect(
          find.byKey(const Key('banner_full_screen_intent')),
          findsOneWidget,
        );
        expect(find.textContaining('[補助]'), findsOneWidget);

        final Container accent = tester.widget<Container>(
          find.byKey(const Key('banner_full_screen_intent_accent')),
        );
        expect(accent.constraints?.maxWidth, 3.0);
      },
    );

    testWidgets('全 granted のときは SizedBox.shrink で何も表示しない', (
      WidgetTester tester,
    ) async {
      final delegate = _MockPermissionNotifier();
      await tester.pumpWidget(_harness(state: _granted, delegate: delegate));

      expect(find.byKey(const Key('banner_post_notifications')), findsNothing);
      expect(find.byKey(const Key('banner_exact_alarm')), findsNothing);
      expect(find.byKey(const Key('banner_full_screen_intent')), findsNothing);
    });

    testWidgets(
      'F-10: post_notifications denied 時にバナータップで requestNotification 呼出',
      (WidgetTester tester) async {
        final delegate = _MockPermissionNotifier();
        when(() => delegate.requestNotification()).thenAnswer((_) async {});

        await tester.pumpWidget(
          _harness(
            state: _granted.copyWith(
              postNotifications: DomainPermissionStatus.denied,
            ),
            delegate: delegate,
          ),
        );

        await tester.tap(find.byKey(const Key('banner_post_notifications')));
        await tester.pump();

        verify(() => delegate.requestNotification()).called(1);
        verifyNever(() => delegate.openSettings());
      },
    );

    testWidgets(
      'F-10: post_notifications permanentlyDenied 時にバナータップで openSettings 呼出',
      (WidgetTester tester) async {
        final delegate = _MockPermissionNotifier();
        when(() => delegate.openSettings()).thenAnswer((_) async => true);

        await tester.pumpWidget(
          _harness(
            state: _granted.copyWith(
              postNotifications: DomainPermissionStatus.permanentlyDenied,
            ),
            delegate: delegate,
          ),
        );

        await tester.tap(find.byKey(const Key('banner_post_notifications')));
        await tester.pump();

        verify(() => delegate.openSettings()).called(1);
        verifyNever(() => delegate.requestNotification());
      },
    );

    testWidgets(
      'F-10: post_notifications denied → Semantics に button role + tap action が立つ',
      (WidgetTester tester) async {
        final delegate = _MockPermissionNotifier();
        when(() => delegate.requestNotification()).thenAnswer((_) async {});
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          _harness(
            state: _granted.copyWith(
              postNotifications: DomainPermissionStatus.denied,
            ),
            delegate: delegate,
          ),
        );

        final SemanticsNode semantics = tester.getSemantics(
          find.byKey(const Key('banner_post_notifications')),
        );
        expect(semantics.flagsCollection.isButton, isTrue);
        expect(
          semantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        // TalkBack に「ラベルなし」と読まれる回帰を防ぐため、
        // 親 Semantics の label が severity / title / description /
        // hint をすべて含むこと、かつ descendant の Text 群が独立した
        // 子 Semantics ノードとして残っていないこと (excludeSemantics
        // が効いていること) を検証する。
        expect(semantics.label, contains('[重要]'));
        expect(semantics.label, contains('通知が無効です'));
        expect(semantics.label, contains('タイマーが終了したときに通知が表示されません。'));
        expect(semantics.label, contains('タップで権限を変更できます。'));
        expect(
          semantics.childrenCount,
          0,
          reason:
              'excludeSemantics: true により子 Semantics ノードが残ってはならない '
              '(残っていると TalkBack が「ラベルなし テキスト N」と読み上げる)',
        );

        handle.dispose();
      },
    );

    testWidgets('F-10: denied 時に hint「タップで権限を変更できます。」が表示される', (
      WidgetTester tester,
    ) async {
      final delegate = _MockPermissionNotifier();
      await tester.pumpWidget(
        _harness(
          state: _granted.copyWith(
            postNotifications: DomainPermissionStatus.denied,
          ),
          delegate: delegate,
        ),
      );

      expect(find.textContaining('タップで権限を変更できます'), findsOneWidget);
    });

    testWidgets('F-10: permanentlyDenied 時に hint「タップで設定を開けます。」が表示される', (
      WidgetTester tester,
    ) async {
      final delegate = _MockPermissionNotifier();
      when(() => delegate.openSettings()).thenAnswer((_) async => true);
      await tester.pumpWidget(
        _harness(
          state: _granted.copyWith(
            postNotifications: DomainPermissionStatus.permanentlyDenied,
          ),
          delegate: delegate,
        ),
      );

      expect(find.textContaining('タップで設定を開けます'), findsOneWidget);
    });

    testWidgets('F-10: バナーに TextButton が存在しない (全体タップで代替)', (
      WidgetTester tester,
    ) async {
      final delegate = _MockPermissionNotifier();
      await tester.pumpWidget(
        _harness(
          state: _granted.copyWith(
            postNotifications: DomainPermissionStatus.denied,
          ),
          delegate: delegate,
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('3 種 denied 同時表示で accent 幅が severity 順 (8 / 5 / 3) で差別化される', (
      WidgetTester tester,
    ) async {
      final delegate = _MockPermissionNotifier();
      await tester.pumpWidget(
        _harness(
          state: const PermissionState(
            postNotifications: DomainPermissionStatus.denied,
            scheduleExactAlarm: DomainPermissionStatus.denied,
            fullScreenIntent: DomainPermissionStatus.denied,
          ),
          delegate: delegate,
        ),
      );

      final Container critical = tester.widget<Container>(
        find.byKey(const Key('banner_post_notifications_accent')),
      );
      final Container recommended = tester.widget<Container>(
        find.byKey(const Key('banner_exact_alarm_accent')),
      );
      final Container supplementary = tester.widget<Container>(
        find.byKey(const Key('banner_full_screen_intent_accent')),
      );

      expect(critical.constraints?.maxWidth, 8.0);
      expect(recommended.constraints?.maxWidth, 5.0);
      expect(supplementary.constraints?.maxWidth, 3.0);
      // 形状差: critical > recommended > supplementary
      expect(
        critical.constraints!.maxWidth,
        greaterThan(recommended.constraints!.maxWidth),
      );
      expect(
        recommended.constraints!.maxWidth,
        greaterThan(supplementary.constraints!.maxWidth),
      );
    });
  });
}
