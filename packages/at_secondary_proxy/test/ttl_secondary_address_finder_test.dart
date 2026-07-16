import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:test/test.dart';

import 'package:at_secondary_proxy/src/ttl_secondary_address_finder.dart';

/// Stands in for [SecondaryUrlFinder] so tests don't hit a real socket.
class _FakeSecondaryUrlFinder extends SecondaryUrlFinder {
  _FakeSecondaryUrlFinder(this._responses) : super('root.example', 64);

  final List<String?> _responses;
  final List<String> lookups = <String>[];

  @override
  Future<String?> findSecondaryUrl(String atSign) async {
    lookups.add(atSign);
    return _responses[lookups.length - 1];
  }
}

void main() {
  group('TtlSecondaryAddressFinder', () {
    test('caches a lookup for the configured duration', () async {
      final fake = _FakeSecondaryUrlFinder(['host1:1000', 'host2:2000']);
      final finder = TtlSecondaryAddressFinder('root.example', 64,
          cacheDuration: const Duration(seconds: 30), secondaryFinder: fake);

      final first = await finder.findSecondary('@alice');
      final second = await finder.findSecondary('@alice');

      expect(fake.lookups, ['alice']); // only queried once
      expect(first.host, 'host1');
      expect(first.port, 1000);
      expect(second.host, 'host1');
      expect(second.port, 1000);
    });

    test('re-queries once the cached entry expires', () async {
      final fake = _FakeSecondaryUrlFinder(['host1:1000', 'host2:2000']);
      final finder = TtlSecondaryAddressFinder('root.example', 64,
          cacheDuration: const Duration(milliseconds: 1), secondaryFinder: fake);

      final first = await finder.findSecondary('@alice');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final second = await finder.findSecondary('@alice');

      expect(fake.lookups, ['alice', 'alice']);
      expect(first.host, 'host1');
      expect(second.host, 'host2');
    });

    test('throws SecondaryNotFoundException when the directory has no entry',
        () async {
      final fake = _FakeSecondaryUrlFinder(['data:null']);
      final finder = TtlSecondaryAddressFinder('root.example', 64,
          secondaryFinder: fake);

      expect(
        () => finder.findSecondary('@alice'),
        throwsA(isA<SecondaryNotFoundException>()),
      );
    });

    test('defaults to a 1-minute cache duration', () {
      expect(TtlSecondaryAddressFinder.defaultCacheDuration,
          const Duration(minutes: 1));
    });
  });
}
