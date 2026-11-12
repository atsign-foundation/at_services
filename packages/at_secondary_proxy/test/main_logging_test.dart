import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('bin/main.dart logs to stderr at info, and nothing finer', () async {
    final Process proxy = await Process.start(Platform.resolvedExecutable, [
      'bin/main.dart',
      '--proxy-url',
      'localhost:9449',
      '--root-url',
      '127.0.0.1:64',
      '--bind-port',
      '0',
      '--cert-dir',
      'certs',
    ]);
    final stdoutLines = <String>[];
    final stderrLines = <String>[];
    final listening = Completer<String>();

    void watch(Stream<List<int>> stream, String name, List<String> lines) {
      stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        lines.add(line);
        if (line.contains('Secure Socket listening') &&
            !listening.isCompleted) {
          listening.complete(name);
        }
      });
    }

    watch(proxy.stdout, 'stdout', stdoutLines);
    watch(proxy.stderr, 'stderr', stderrLines);
    unawaited(proxy.exitCode.then((code) {
      if (!listening.isCompleted) {
        listening.completeError(StateError('bin/main.dart exited with $code'
            ' before logging; stdout: $stdoutLines; stderr: $stderrLines'));
      }
    }));

    try {
      final String stream = await listening.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => fail('no "Secure Socket listening" line within 60s;'
            ' stdout: $stdoutLines; stderr: $stderrLines'),
      );
      expect(stream, 'stderr',
          reason: 'the startup line went to $stream; stdout: $stdoutLines');
      expect(
        stderrLines.firstWhere((l) => l.contains('Secure Socket listening')),
        matches(RegExp(
            r'^INFO\|[^|]+\|AtSecondaryProxy\|Secure Socket listening on port \d+$')),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(
          stderrLines
              .where((l) => RegExp(r'^(FINE|FINER|FINEST)\|').hasMatch(l)),
          isEmpty,
          reason: 'the proxy logs at info, not finer');
      expect(stdoutLines, isEmpty, reason: 'the proxy logs to stderr only');
    } finally {
      proxy.kill();
      await proxy.exitCode;
    }
  }, timeout: const Timeout(Duration(seconds: 90)));
}
