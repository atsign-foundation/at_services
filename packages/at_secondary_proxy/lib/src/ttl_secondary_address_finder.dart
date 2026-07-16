import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';

/// A [SecondaryAddressFinder] with a configurable cache TTL.
///
/// at_lookup's [CacheableSecondaryAddressFinder] hardcodes a 1-hour TTL with
/// no way to override it, so the proxy can serve a stale secondary address
/// for up to an hour after an atSign is reset. This reuses the same
/// [SecondaryUrlFinder] lookup logic behind a shorter, configurable TTL.
class TtlSecondaryAddressFinder implements SecondaryAddressFinder {
  static const Duration defaultCacheDuration = Duration(minutes: 1);

  final Duration cacheDuration;
  final SecondaryUrlFinder _secondaryFinder;
  final Map<String, _CacheEntry> _cache = {};

  TtlSecondaryAddressFinder(String rootDomain, int rootPort,
      {this.cacheDuration = defaultCacheDuration,
      SecondaryUrlFinder? secondaryFinder})
      : _secondaryFinder =
            secondaryFinder ?? SecondaryUrlFinder(rootDomain, rootPort);

  @override
  Future<SecondaryAddress> findSecondary(String atSign) async {
    atSign = atSign.startsWith('@') ? atSign.substring(1) : atSign;

    final cached = _cache[atSign];
    if (cached != null &&
        cached.expiresAt > DateTime.now().millisecondsSinceEpoch) {
      return cached.address;
    }

    final secondaryUrl = await _secondaryFinder.findSecondaryUrl(atSign);
    if (secondaryUrl == null ||
        secondaryUrl.isEmpty ||
        secondaryUrl == 'data:null') {
      throw SecondaryNotFoundException('No entry in atDirectory for $atSign');
    }

    final parts = secondaryUrl.split(':');
    final address = SecondaryAddress(parts[0], int.parse(parts[1]));
    _cache[atSign] = _CacheEntry(
        address, DateTime.now().add(cacheDuration).millisecondsSinceEpoch);
    return address;
  }
}

class _CacheEntry {
  final SecondaryAddress address;

  /// milliseconds since epoch
  final int expiresAt;

  _CacheEntry(this.address, this.expiresAt);
}
