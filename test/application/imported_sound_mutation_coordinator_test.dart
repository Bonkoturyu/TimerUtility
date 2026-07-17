import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/imported_sound_mutation_coordinator.dart';

void main() {
  group('ImportedSoundMutationCoordinator', () {
    test('操作を登録順に1件ずつ実行する', () async {
      final ImportedSoundMutationCoordinator coordinator =
          ImportedSoundMutationCoordinator();
      final Completer<void> firstGate = Completer<void>();
      final List<String> events = <String>[];

      final Future<int> first = coordinator.run(() async {
        events.add('first-start');
        await firstGate.future;
        events.add('first-end');
        return 1;
      });
      final Future<int> second = coordinator.run(() async {
        events.add('second');
        return 2;
      });

      expect(events, <String>['first-start']);
      firstGate.complete();

      expect(await first, 1);
      expect(await second, 2);
      expect(events, <String>['first-start', 'first-end', 'second']);
    });

    test('先行操作が失敗しても後続を解放する', () async {
      final ImportedSoundMutationCoordinator coordinator =
          ImportedSoundMutationCoordinator();
      final List<String> events = <String>[];

      final Future<void> failed = coordinator.run(() async {
        events.add('failed');
        throw StateError('failure');
      });
      final Future<void> next = coordinator.run(() async {
        events.add('next');
      });

      await expectLater(failed, throwsStateError);
      await next;
      expect(events, <String>['failed', 'next']);
    });
  });

  group('ImportedSoundDeletionRegistry', () {
    test('deleting中は参照を保持し、成功後だけdefaultへ正規化する', () {
      final ImportedSoundDeletionRegistry registry =
          ImportedSoundDeletionRegistry();

      registry.markDeleting('imported');
      expect(registry.isUnavailable('imported'), isTrue);
      expect(registry.normalizeDeletedReference('imported'), 'imported');

      registry.markDeleted('imported');
      expect(registry.isDeleting('imported'), isFalse);
      expect(registry.isDeleted('imported'), isTrue);
      expect(registry.normalizeDeletedReference('imported'), 'default');
      expect(registry.normalizeDeletedReference(null), isNull);
    });

    test('失敗時はdeletingだけを解除する', () {
      final ImportedSoundDeletionRegistry registry =
          ImportedSoundDeletionRegistry();

      registry.markDeleting('imported');
      registry.clearDeleting('imported');

      expect(registry.isUnavailable('imported'), isFalse);
      expect(registry.normalizeDeletedReference('imported'), 'imported');
    });
  });
}
