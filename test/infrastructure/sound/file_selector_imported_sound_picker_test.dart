import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/ports/imported_sound_picker.dart';
import 'package:timer_utility/infrastructure/sound/file_selector_imported_sound_picker.dart';

void main() {
  group('FileSelectorImportedSoundPicker', () {
    test('キャンセル時はnullを返す', () async {
      final FileSelectorImportedSoundPicker picker =
          FileSelectorImportedSoundPicker(
            openFile: ({required List<XTypeGroup> acceptedTypeGroups}) async {
              expect(acceptedTypeGroups, isNotEmpty);
              return null;
            },
          );

      expect(await picker.pickOne(), isNull);
    });

    test('XFileのpathやURIを含まない選択結果へ変換する', () async {
      final XFile source = XFile(
        'alarm.mp3',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        mimeType: 'audio/mpeg',
      );
      final FileSelectorImportedSoundPicker picker =
          FileSelectorImportedSoundPicker(
            openFile: ({required List<XTypeGroup> acceptedTypeGroups}) async =>
                source,
            readLength: (_) async => 4,
            openRead: (_) => Stream<List<int>>.value(<int>[1, 2, 3, 4]),
          );

      final SelectedImportedSoundFile? selected = await picker.pickOne();

      expect(selected?.name, 'alarm.mp3');
      expect(selected?.mimeType, 'audio/mpeg');
      expect(selected?.byteLength, 4);
      expect(
        await selected!.openRead().expand((List<int> value) => value).toList(),
        <int>[1, 2, 3, 4],
      );
    });
  });
}
