import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/microphone_permission_manager.dart';
import '../infrastructure/permission/permission_handler_microphone_permission_manager.dart';

part 'microphone_permission_provider.g.dart';

@Riverpod(keepAlive: true)
MicrophonePermissionManager microphonePermissionManager(Ref ref) =>
    PermissionHandlerMicrophonePermissionManager();
