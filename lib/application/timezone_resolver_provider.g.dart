// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timezone_resolver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timezoneResolverHash() => r'd936f7d88a8e6c6f81c00c18351b57923f9d04dc';

/// Provider for the [TimezoneResolver] used by the world-clock
/// presentation widgets to render a wall-clock [DateTime] for a given
/// IANA timezone id. Tests override this with a fake (fixed-offset
/// implementation); production binding is wired in `main()` with
/// [TzDatabaseTimezoneResolver].
///
/// Copied from [timezoneResolver].
@ProviderFor(timezoneResolver)
final timezoneResolverProvider = Provider<TimezoneResolver>.internal(
  timezoneResolver,
  name: r'timezoneResolverProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timezoneResolverHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimezoneResolverRef = ProviderRef<TimezoneResolver>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
