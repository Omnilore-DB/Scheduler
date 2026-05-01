// Comprehensive tests for Bug 1 (trial-run 2026-04-30):
// parseBundledStateContent must recover gracefully when a legacy autosave
// contains a CourseFile section but no PeopleFile section.  Prior to the fix
// this always threw FormatException, preventing every subsequent app open.

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/io/bundled_state.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Bug 1 core path: CourseFile present, PeopleFile absent, Setting present
  // ═══════════════════════════════════════════════════════════════════════════

  group('parseBundledStateContent — legacy CourseFile-only recovery', () {
    test('extracts courseData and stateContent; peopleData is null', () {
      const input = 'CourseFile:\ncourse line\nSetting:\nstate\n';
      final parsed = parseBundledStateContent(input);
      expect(parsed.courseData, 'course line\n');
      expect(parsed.peopleData, isNull);
      expect(parsed.stateContent, 'Setting:\nstate\n');
    });

    test('hasEmbeddedSourceData is false for legacy recovery', () {
      final parsed = parseBundledStateContent(
          'CourseFile:\ndata\nSetting:\nstate\n');
      expect(parsed.hasEmbeddedSourceData, isFalse);
    });

    test('multi-line course section is fully preserved', () {
      const courseLines = 'ABC\tCourse A\tReading A\n'
          'DEF\tCourse B\tReading B\n'
          'GHI\tCourse C\tReading C\n';
      final parsed = parseBundledStateContent(
          'CourseFile:\n${courseLines}Setting:\nMin: 8\n');
      expect(parsed.courseData, courseLines);
      expect(parsed.stateContent, 'Setting:\nMin: 8\n');
    });

    test('CRLF in course data is preserved verbatim', () {
      const courseData = 'ABC\tCourse A\r\nDEF\tCourse B\r\n';
      final parsed = parseBundledStateContent(
          'CourseFile:\n${courseData}Setting:\nstate\n');
      expect(parsed.courseData, courseData);
    });

    test('courseData contains no Setting: text (boundary is exact)', () {
      final parsed = parseBundledStateContent(
          'CourseFile:\nABC\tCourse\nSetting:\nMin: 8\nMax: 19\n');
      expect(parsed.courseData, isNot(contains('Setting:')));
      expect(parsed.courseData, isNot(contains('Min:')));
      expect(parsed.courseData, isNot(contains('Max:')));
    });

    test('stateContent includes all content from Setting: to end of input', () {
      const state =
          'Setting:\nMin: 8\nMax: 19\n\nCourse size:\n\nDrop:\nABC\n\nSchedule:\n\n';
      final parsed = parseBundledStateContent('CourseFile:\ndata\n$state');
      expect(parsed.stateContent, state);
    });

    test('minimal single-line course recovers correctly', () {
      final parsed = parseBundledStateContent(
          'CourseFile:\nABC\tOnly Course\nSetting:\nstate\n');
      expect(parsed.courseData, 'ABC\tOnly Course\n');
      expect(parsed.stateContent, 'Setting:\nstate\n');
    });

    test('Setting: with empty body still recovers', () {
      final parsed =
          parseBundledStateContent('CourseFile:\ncourse data\nSetting:\n');
      expect(parsed.courseData, 'course data\n');
      expect(parsed.stateContent, 'Setting:\n');
      expect(parsed.hasEmbeddedSourceData, isFalse);
    });

    test('adjacent-marker format (no newline before Setting:) recovers', () {
      // Older saves where source files lacked trailing newlines.
      final parsed =
          parseBundledStateContent('CourseFile:\ncourse dataSetting:\nstate\n');
      expect(parsed.courseData, 'course data');
      expect(parsed.stateContent, 'Setting:\nstate\n');
      expect(parsed.hasEmbeddedSourceData, isFalse);
    });

    test('PeopleFile: text embedded inside a course field does not confuse parser', () {
      // The section-marker search only matches at a newline boundary.
      // A tab-separated "PeopleFile:" inside a course title is NOT a marker.
      const courseData = 'ABC\tPeopleFile: A Strange Title\tReading A\n';
      final parsed = parseBundledStateContent(
          'CourseFile:\n${courseData}Setting:\nstate\n');
      // Should recover gracefully, NOT mistake the embedded PeopleFile: as a
      // section boundary.
      expect(parsed.courseData, courseData);
      expect(parsed.peopleData, isNull);
      expect(parsed.stateContent, 'Setting:\nstate\n');
    });

    test('Setting: text inside a course field does not corrupt the state boundary', () {
      // "Setting:" in a tab field is not a marker.
      const courseData = 'ABC\tCourse with Setting: in title\tReading\n';
      final parsed = parseBundledStateContent(
          'CourseFile:\n${courseData}Setting:\nstate body\n');
      expect(parsed.courseData, courseData);
      expect(parsed.stateContent, 'Setting:\nstate body\n');
    });

    test('large multi-section stateContent is returned completely', () {
      const state = 'Setting:\nMin: 8\nMax: 19\n\n'
          'Course size:\n\n'
          'Drop:\nABC\nDEF\n\n'
          'Limit:\n\n'
          'Split:\n\n'
          'Schedule:\nABC 3\nDEF 7\n\n'
          'Coordinator:\nABC\tSmith J\tJones K\n\n';
      final parsed = parseBundledStateContent('CourseFile:\ncourse\n$state');
      expect(parsed.stateContent, state);
    });

    test('recovery result can be re-bundled with people data and round-trip', () {
      const courseData = 'ABC\tCourse A\nDEF\tCourse B\n';
      const stateContent = 'Setting:\nMin: 8\n';
      final legacyInput = 'CourseFile:\n${courseData}$stateContent';

      // Simulate what the caller does after recovery: supply missing people
      // from autosave / in-memory and re-bundle.
      final recovered = parseBundledStateContent(legacyInput);
      const suppliedPeople = 'Smith\tJohn\t555-1234\n';

      final rebundled = buildBundledStateContent(
        stateContent: recovered.stateContent,
        courseData: recovered.courseData!,
        peopleData: suppliedPeople,
      );
      final reparsed = parseBundledStateContent(rebundled);
      expect(reparsed.courseData, '${courseData.trimRight()}\n');
      expect(reparsed.peopleData, suppliedPeople);
      expect(reparsed.stateContent, stateContent);
      expect(reparsed.hasEmbeddedSourceData, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Unrecoverable cases — must still throw
  // ═══════════════════════════════════════════════════════════════════════════

  group('parseBundledStateContent — unrecoverable cases', () {
    test('CourseFile only with no Setting: throws FormatException', () {
      expect(
        () => parseBundledStateContent('CourseFile:\ndata only'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Saved file is missing the PeopleFile section.',
        )),
      );
    });

    test('CourseFile with whitespace but no Setting: throws FormatException', () {
      expect(
        () => parseBundledStateContent('CourseFile:\n\n\nsome data\n'),
        throwsA(isA<FormatException>()),
      );
    });

    test('CourseFile + PeopleFile with no Setting: throws FormatException', () {
      expect(
        () => parseBundledStateContent(
            'CourseFile:\ncourse\nPeopleFile:\npeople\n'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Saved file is missing the state section.',
        )),
      );
    });

    test('CourseFile + PeopleFile adjacent-marker with no Setting: throws', () {
      expect(
        () => parseBundledStateContent(
            'CourseFile:\ncoursePeopleFile:\npeople only'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Regression: full bundled format must still parse correctly
  // ═══════════════════════════════════════════════════════════════════════════

  group('parseBundledStateContent — full bundled format regression', () {
    test('full bundled parses all three sections', () {
      const course = 'ABC\tCourse A\tReading\n';
      const people = 'Smith\tJohn\t555-0000\n';
      const state = 'Setting:\nMin: 8\nMax: 19\n';
      final bundled = buildBundledStateContent(
        stateContent: state,
        courseData: course,
        peopleData: people,
      );
      final parsed = parseBundledStateContent(bundled);
      expect(parsed.courseData, course);
      expect(parsed.peopleData, people);
      expect(parsed.stateContent, state);
      expect(parsed.hasEmbeddedSourceData, isTrue);
    });

    test('Setting: text inside people tab field does not corrupt boundary', () {
      const course = 'ABC\tCourse\n';
      const people = 'Doe\tJane\t555-0000\tSetting: personal note\n';
      const state = 'Setting:\nstate body\n';
      final bundled = buildBundledStateContent(
          stateContent: state, courseData: course, peopleData: people);
      final parsed = parseBundledStateContent(bundled);
      expect(parsed.peopleData, people);
      expect(parsed.stateContent, state);
    });

    test('plain state (no CourseFile) passes through unchanged', () {
      const input = 'Setting:\nMin: 8\nMax: 19\n\nDrop:\n\n';
      final parsed = parseBundledStateContent(input);
      expect(parsed.stateContent, input);
      expect(parsed.courseData, isNull);
      expect(parsed.peopleData, isNull);
      expect(parsed.hasEmbeddedSourceData, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // buildBundledStateContent edge cases
  // ═══════════════════════════════════════════════════════════════════════════

  group('buildBundledStateContent — edge cases', () {
    test('courseData null returns plain state regardless of peopleData', () {
      const state = 'Setting:\nstate\n';
      expect(
        buildBundledStateContent(stateContent: state, peopleData: 'people\n'),
        state,
      );
    });

    test('peopleData null returns plain state regardless of courseData', () {
      const state = 'Setting:\nstate\n';
      expect(
        buildBundledStateContent(stateContent: state, courseData: 'course\n'),
        state,
      );
    });

    test('both null returns plain state', () {
      const state = 'Setting:\nstate\n';
      expect(buildBundledStateContent(stateContent: state), state);
    });

    test('stateContent without trailing newline is embedded verbatim', () {
      final built = buildBundledStateContent(
        stateContent: 'Setting:\nno trailing newline',
        courseData: 'course\n',
        peopleData: 'people\n',
      );
      expect(built, endsWith('Setting:\nno trailing newline'));
    });

    test('source without trailing newline gets exactly one newline added before next section', () {
      final built = buildBundledStateContent(
        stateContent: 'Setting:\nstate\n',
        courseData: 'course',   // no trailing newline
        peopleData: 'people\n',
      );
      // Exactly one newline inserted between course and PeopleFile:
      expect(built, contains('course\nPeopleFile:'));
      expect(built, isNot(contains('course\n\nPeopleFile:')));
    });

    test('source with trailing newline does not get a double newline', () {
      final built = buildBundledStateContent(
        stateContent: 'Setting:\nstate\n',
        courseData: 'course\n',  // already has newline
        peopleData: 'people\n',
      );
      expect(built, isNot(contains('\n\nPeopleFile:')));
      expect(built, contains('course\nPeopleFile:'));
    });

    test('output starts with CourseFile: header', () {
      final built = buildBundledStateContent(
        stateContent: 'Setting:\nstate\n',
        courseData: 'course\n',
        peopleData: 'people\n',
      );
      expect(built, startsWith('CourseFile:\n'));
    });

    test('output contains PeopleFile: section between CourseFile and Setting', () {
      final built = buildBundledStateContent(
        stateContent: 'Setting:\nstate\n',
        courseData: 'course\n',
        peopleData: 'people\n',
      );
      final cIdx = built.indexOf('CourseFile:');
      final pIdx = built.indexOf('PeopleFile:');
      final sIdx = built.indexOf('Setting:');
      expect(cIdx, lessThan(pIdx));
      expect(pIdx, lessThan(sIdx));
    });
  });
}
