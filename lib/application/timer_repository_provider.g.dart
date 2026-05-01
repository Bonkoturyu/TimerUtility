// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerRepositoryHash() => r'f6c9103ab7495d3c2b609df4081370d059d59a6d';

/// Provider for the [TimerRepository] used by
/// [TimerCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
///
/// Copied from [timerRepository].
@ProviderFor(timerRepository)
final timerRepositoryProvider = Provider<TimerRepository>.internal(
  timerRepository,
  name: r'timerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimerRepositoryRef = ProviderRef<TimerRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
