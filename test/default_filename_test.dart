import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/io/default_filename.dart';

void main() {
  test('formats with zero-padded date and HHMM time', () {
    final result = defaultExportFilename(
      'scheduling_state',
      now: DateTime(2026, 4, 8, 9, 5),
    );
    expect(result, 'scheduling_state_2026-04-08_0905.txt');
  });

  test('respects custom extension', () {
    final result = defaultExportFilename(
      'roster',
      extension: 'csv',
      now: DateTime(2026, 12, 31, 23, 59),
    );
    expect(result, 'roster_2026-12-31_2359.csv');
  });

  test('uses DateTime.now when not injected', () {
    final result = defaultExportFilename('foo');
    expect(result, matches(r'^foo_\d{4}-\d{2}-\d{2}_\d{4}\.txt$'));
  });
}
