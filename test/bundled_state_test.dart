import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/io/bundled_state.dart';

void main() {
  group('buildBundledStateContent', () {
    test('returns plain state when no source data provided', () {
      final result = buildBundledStateContent(
        stateContent: 'Setting:\nsome state',
      );
      expect(result, 'Setting:\nsome state');
    });

    test('returns plain state when only courseData provided', () {
      final result = buildBundledStateContent(
        stateContent: 'Setting:\nsome state',
        courseData: 'course data',
      );
      expect(result, 'Setting:\nsome state');
    });

    test('returns plain state when only peopleData provided', () {
      final result = buildBundledStateContent(
        stateContent: 'Setting:\nsome state',
        peopleData: 'people data',
      );
      expect(result, 'Setting:\nsome state');
    });

    test('builds bundled content with embedded course and people data', () {
      final result = buildBundledStateContent(
        stateContent: 'Setting:\nsome state',
        courseData: 'course line 1\ncourse line 2\n',
        peopleData: 'person1\nperson2\n',
      );
      expect(result,
          'CourseFile:\ncourse line 1\ncourse line 2\nPeopleFile:\nperson1\nperson2\nSetting:\nsome state');
    });

    test('adds section delimiters when source data has no trailing newline', () {
      final result = buildBundledStateContent(
        stateContent: 'Setting:\nsome state',
        courseData: 'course line 1\ncourse line 2',
        peopleData: 'person1\nperson2',
      );

      expect(result,
          'CourseFile:\ncourse line 1\ncourse line 2\nPeopleFile:\nperson1\nperson2\nSetting:\nsome state');
    });
  });

  group('parseBundledStateContent', () {
    test('returns plain state unchanged when no CourseFile header', () {
      const input = 'Setting:\nsome state\n';
      final parsed = parseBundledStateContent(input);
      expect(parsed.stateContent, input);
      expect(parsed.courseData, isNull);
      expect(parsed.peopleData, isNull);
      expect(parsed.hasEmbeddedSourceData, isFalse);
    });

    test('parses bundled content into course, people, and state sections', () {
      const courseData = 'course line 1\ncourse line 2\n';
      const peopleData = 'person1\nperson2\n';
      const stateContent = 'Setting:\nsome state\n';
      const bundled = 'CourseFile:\n${courseData}PeopleFile:\n$peopleData$stateContent';

      final parsed = parseBundledStateContent(bundled);

      expect(parsed.courseData, courseData);
      expect(parsed.peopleData, peopleData);
      expect(parsed.stateContent, stateContent);
      expect(parsed.hasEmbeddedSourceData, isTrue);
    });

    test('parses older adjacent section markers without trailing newlines', () {
      const bundled =
          'CourseFile:\ncourse line 1\ncourse line 2PeopleFile:\nperson1\nperson2Setting:\nsome state\n';

      final parsed = parseBundledStateContent(bundled);

      expect(parsed.courseData, 'course line 1\ncourse line 2');
      expect(parsed.peopleData, 'person1\nperson2');
      expect(parsed.stateContent, 'Setting:\nsome state\n');
      expect(parsed.hasEmbeddedSourceData, isTrue);
    });

    test('round-trips through build then parse', () {
      const stateContent = 'Setting:\nfoo\nbar\n';
      const courseData = 'COURSE A\nCOURSE B\n';
      const peopleData = 'Alice Smith\nBob Jones\n';

      final bundled = buildBundledStateContent(
        stateContent: stateContent,
        courseData: courseData,
        peopleData: peopleData,
      );
      final parsed = parseBundledStateContent(bundled);

      expect(parsed.courseData, courseData);
      expect(parsed.peopleData, peopleData);
      expect(parsed.stateContent, stateContent);
    });

    test('throws FormatException when PeopleFile section is missing', () {
      const badInput = 'CourseFile:\nsome course data\nSetting:\nstate';
      expect(
        () => parseBundledStateContent(badInput),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when state section is missing', () {
      const badInput = 'CourseFile:\ncourse data\nPeopleFile:\npeople data\n';
      expect(
        () => parseBundledStateContent(badInput),
        throwsA(isA<FormatException>()),
      );
    });

    test('hasEmbeddedSourceData is true only when both sections present', () {
      final withBoth = parseBundledStateContent(
          'CourseFile:\ncourse\nPeopleFile:\npeople\nSetting:\nstate\n');
      expect(withBoth.hasEmbeddedSourceData, isTrue);

      final withoutBoth = parseBundledStateContent('Setting:\nstate\n');
      expect(withoutBoth.hasEmbeddedSourceData, isFalse);
    });
  });
}
