import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/io/export_text_file.dart';

void main() {
  test('web export with custom name uses save as flow', () async {
    var saveAsCalls = <String>[];
    var downloadCalls = <String>[];

    await exportTextFile(
      isWeb: true,
      content: 'roster-content',
      suggestedName: 'final_roster.txt',
      allowCustomNameOnWeb: true,
      saveAs: (content, suggestedName) async {
        saveAsCalls.add('$suggestedName::$content');
      },
      download: (content, filename) {
        downloadCalls.add('$filename::$content');
      },
      pickSavePath: () async => 'ignored.txt',
      writeToPath: (_, __) {},
    );

    expect(saveAsCalls, ['final_roster.txt::roster-content']);
    expect(downloadCalls, isEmpty);
  });

  test('web export without custom naming uses browser download', () async {
    var saveAsCalls = 0;
    var downloadCalls = <String>[];

    await exportTextFile(
      isWeb: true,
      content: 'mail-merge',
      suggestedName: 'mail_merge.txt',
      saveAs: (_, __) async {
        saveAsCalls++;
      },
      download: (content, filename) {
        downloadCalls.add('$filename::$content');
      },
      pickSavePath: () async => 'ignored.txt',
      writeToPath: (_, __) {},
    );

    expect(saveAsCalls, 0);
    expect(downloadCalls, ['mail_merge.txt::mail-merge']);
  });

  test('desktop export writes selected path', () async {
    String? writtenPath;
    String? writtenContent;

    await exportTextFile(
      isWeb: false,
      content: 'early-roster',
      suggestedName: 'early_roster.txt',
      saveAs: (_, __) async {},
      download: (_, __) {},
      pickSavePath: () async => '/tmp/roster.txt',
      writeToPath: (path, content) {
        writtenPath = path;
        writtenContent = content;
      },
    );

    expect(writtenPath, '/tmp/roster.txt');
    expect(writtenContent, 'early-roster');
  });

  test('desktop export skips write when picker is canceled', () async {
    var writeCalls = 0;

    await exportTextFile(
      isWeb: false,
      content: 'final-roster',
      suggestedName: 'final_roster.txt',
      saveAs: (_, __) async {},
      download: (_, __) {},
      pickSavePath: () async => null,
      writeToPath: (_, __) {
        writeCalls++;
      },
    );

    expect(writeCalls, 0);
  });

  test('desktop export skips write when picker returns empty path', () async {
    var writeCalls = 0;

    await exportTextFile(
      isWeb: false,
      content: 'final-roster',
      suggestedName: 'final_roster.txt',
      saveAs: (_, __) async {},
      download: (_, __) {},
      pickSavePath: () async => '',
      writeToPath: (_, __) {
        writeCalls++;
      },
    );

    expect(writeCalls, 0);
  });
}
