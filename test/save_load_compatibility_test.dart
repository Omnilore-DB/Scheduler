import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/io/bundled_state.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';

Future<List<String>> _driveToOutput(Scheduling scheduling) async {
  final goCourses = await _driveToCoordinator(scheduling);

  for (var course in goCourses) {
    final resultingClass =
        scheduling.overviewData.getPeopleForResultingClass(course);
    expect(resultingClass, isNotEmpty,
        reason: 'Course $course should have at least one participant.');
    scheduling.courseControl.setMainCoCoordinator(course, resultingClass.first);
  }

  expect(scheduling.getStateOfProcessing(), StateOfProcessing.output);
  return goCourses;
}

Future<List<String>> _driveToCoordinator(Scheduling scheduling) async {
  scheduling.courseControl
      .setGlobalMinMaxClassSize(0, scheduling.getNumPeople());

  final goCourses = scheduling.courseControl.getGo().toList(growable: false)
    ..sort((a, b) => a.compareTo(b));

  const totalTimeSlots = 20;
  for (var i = 0; i < goCourses.length; i++) {
    scheduling.scheduleControl.schedule(goCourses[i], i % totalTimeSlots);
  }

  expect(scheduling.getStateOfProcessing(), StateOfProcessing.coordinator);
  return goCourses;
}

Future<List<String>> _driveToOutputWithEqualCoordinatorCourse(
    Scheduling scheduling) async {
  final goCourses = await _driveToOutput(scheduling);

  final targetCourse = goCourses.first;
  final targetPeople = scheduling.overviewData
      .getPeopleForResultingClass(targetCourse)
      .take(2)
      .toList();
  expect(targetPeople.length, 2,
      reason:
          'Expected $targetCourse to have at least two people for equal coordinator coverage.');

  scheduling.courseControl.clearCoordinators(targetCourse);
  scheduling.courseControl.setEqualCoCoordinator(targetCourse, targetPeople[0]);
  scheduling.courseControl.setEqualCoCoordinator(targetCourse, targetPeople[1]);

  expect(scheduling.getStateOfProcessing(), StateOfProcessing.output);
  return goCourses;
}

String _normalize(String content) {
  return content.endsWith('\n') ? content : '$content\n';
}

String _toCrLf(String content) {
  return _normalize(content).replaceAll('\n', '\r\n');
}

Future<Scheduling> _restoreBundledContent(
  String content, {
  String? fallbackCourseData,
  String? fallbackPeopleData,
}) async {
  final parsed = parseBundledStateContent(content);
  final courseData = parsed.courseData ?? fallbackCourseData;
  final peopleData = parsed.peopleData ?? fallbackPeopleData;

  expect(courseData, isNotNull,
      reason: 'Restore needs embedded or fallback course source data.');
  expect(peopleData, isNotNull,
      reason: 'Restore needs embedded or fallback people source data.');

  final restored = Scheduling();
  await restored.loadCoursesFromBytes(utf8.encode(courseData!));
  await restored.loadPeopleFromBytes(utf8.encode(peopleData!));
  restored.loadStateFromBytes(utf8.encode(parsed.stateContent));
  return restored;
}

void _expectOutputStateAndExportsMatch(Scheduling source, Scheduling restored) {
  expect(restored.getNumPeople(), source.getNumPeople());
  expect(restored.getCourseCodes().length, source.getCourseCodes().length);
  expect(restored.getStateOfProcessing(), StateOfProcessing.output);
  expect(restored.outputRosterCCToString(), source.outputRosterCCToString());
  expect(
      restored.outputRosterPhoneToString(), source.outputRosterPhoneToString());
  expect(restored.outputMMToString(), source.outputMMToString());
}

void main() {
  test('Bundled save payload round-trips from a fresh Scheduling instance',
      () async {
    final courseText =
        _normalize(File('test/resources/course_split.txt').readAsStringSync());
    final peopleText = _normalize(
        File('test/resources/people_schedule.txt').readAsStringSync());

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    final goCourses = await _driveToOutput(source);

    final stateContent = source.exportStateToString();
    final bundled =
        'CourseFile:\n${courseText}PeopleFile:\n$peopleText$stateContent';

    final restored = Scheduling();
    await restored.loadCoursesFromBytes(utf8.encode(courseText));
    await restored.loadPeopleFromBytes(utf8.encode(peopleText));
    restored.loadStateFromBytes(utf8.encode(bundled));

    expect(restored.getNumPeople(), source.getNumPeople());
    expect(restored.getCourseCodes().length, source.getCourseCodes().length);
    expect(restored.getStateOfProcessing(), source.getStateOfProcessing());

    for (var course in goCourses) {
      expect(restored.scheduleControl.scheduledTimeFor(course),
          source.scheduleControl.scheduledTimeFor(course));
    }
  });

  test('Legacy state-only payload remains loadable with imported base data',
      () async {
    final courseText =
        _normalize(File('test/resources/course_split.txt').readAsStringSync());
    final peopleText = _normalize(
        File('test/resources/people_schedule.txt').readAsStringSync());

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    final goCourses = await _driveToOutput(source);

    final legacyStateOnly = source.exportStateToString();

    final restored = await _restoreBundledContent(
      legacyStateOnly,
      fallbackCourseData: courseText,
      fallbackPeopleData: peopleText,
    );

    expect(restored.getStateOfProcessing(), StateOfProcessing.output);
    expect(restored.outputRosterCCToString(), isNotEmpty);
    expect(restored.outputRosterPhoneToString(), isNotEmpty);
    expect(restored.outputMMToString(), isNotEmpty);
    for (var course in goCourses) {
      expect(restored.scheduleControl.scheduledTimeFor(course),
          source.scheduleControl.scheduledTimeFor(course));
    }
  });

  test('Path-based source text can be bundled and restored cross-instance',
      () async {
    final source = Scheduling();
    final courseText = source.readText('test/resources/course_split.txt');
    final peopleText = source.readText('test/resources/people_schedule.txt');

    expect(courseText, contains('\t'));
    expect(peopleText, contains('\t'));
    expect(courseText.endsWith('\n'), isTrue);
    expect(peopleText.endsWith('\n'), isTrue);

    await source.loadCourses('test/resources/course_split.txt');
    await source.loadPeople('test/resources/people_schedule.txt');
    await _driveToOutput(source);

    final bundled =
        'CourseFile:\n${courseText}PeopleFile:\n$peopleText${source.exportStateToString()}';

    final restored = await _restoreBundledContent(bundled);

    _expectOutputStateAndExportsMatch(source, restored);
  });

  test('Bundled save without source trailing newlines restores', () async {
    final courseText =
        File('test/resources/course_split.txt').readAsStringSync().trimRight();
    final peopleText = File('test/resources/people_schedule.txt')
        .readAsStringSync()
        .trimRight();

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    await _driveToOutput(source);

    final bundled = buildBundledStateContent(
      stateContent: source.exportStateToString(),
      courseData: courseText,
      peopleData: peopleText,
    );
    final restored = await _restoreBundledContent(bundled);

    _expectOutputStateAndExportsMatch(source, restored);
  });

  test('Older adjacent-marker bundled saves restore and export', () async {
    final courseText =
        File('test/resources/course_split.txt').readAsStringSync().trimRight();
    final peopleText = File('test/resources/people_schedule.txt')
        .readAsStringSync()
        .trimRight();

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    await _driveToOutput(source);

    final legacyBundled =
        'CourseFile:\n${courseText}PeopleFile:\n$peopleText${source.exportStateToString()}';

    final restored = await _restoreBundledContent(legacyBundled);

    _expectOutputStateAndExportsMatch(source, restored);
  });

  test('CRLF source text bundled saves restore and export', () async {
    final courseText =
        _toCrLf(File('test/resources/course_split.txt').readAsStringSync());
    final peopleText =
        _toCrLf(File('test/resources/people_schedule.txt').readAsStringSync());

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    await _driveToOutput(source);

    final bundled = buildBundledStateContent(
      stateContent: source.exportStateToString(),
      courseData: courseText,
      peopleData: peopleText,
    );

    final restored = await _restoreBundledContent(bundled);

    _expectOutputStateAndExportsMatch(source, restored);
  });

  test('Bundled coordinator-state restore can continue to final exports',
      () async {
    final courseText =
        _normalize(File('test/resources/course_split.txt').readAsStringSync());
    final peopleText = _normalize(
        File('test/resources/people_schedule.txt').readAsStringSync());

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    final goCourses = await _driveToCoordinator(source);

    final bundled = buildBundledStateContent(
      stateContent: source.exportStateToString(),
      courseData: courseText,
      peopleData: peopleText,
    );

    final restored = await _restoreBundledContent(bundled);

    expect(restored.getStateOfProcessing(), StateOfProcessing.coordinator);
    expect(restored.outputRosterPhoneToString(), isNotEmpty);
    expect(restored.outputRosterCCToString(), isEmpty);
    expect(restored.outputMMToString(), isEmpty);

    for (var course in goCourses) {
      final resultingClass =
          restored.overviewData.getPeopleForResultingClass(course);
      expect(resultingClass, isNotEmpty,
          reason:
              'Course $course should still have participants after restore.');
      restored.courseControl.setMainCoCoordinator(course, resultingClass.first);
    }

    expect(restored.getStateOfProcessing(), StateOfProcessing.output);
    expect(restored.outputRosterCCToString(), isNotEmpty);
    expect(restored.outputRosterPhoneToString(), isNotEmpty);
    expect(restored.outputMMToString(), isNotEmpty);
  });

  test('Coordinator mode and names survive save/load round-trip', () async {
    final courseText =
        _normalize(File('test/resources/course_split.txt').readAsStringSync());
    final peopleText = _normalize(
        File('test/resources/people_schedule.txt').readAsStringSync());

    final source = Scheduling();
    await source.loadCoursesFromBytes(utf8.encode(courseText));
    await source.loadPeopleFromBytes(utf8.encode(peopleText));
    final goCourses = await _driveToOutputWithEqualCoordinatorCourse(source);
    final targetCourse = goCourses.first;
    final sourceCoordinators =
        source.courseControl.getCoordinators(targetCourse)!;

    final legacyStateOnly = source.exportStateToString();

    final restored = Scheduling();
    await restored.loadCoursesFromBytes(utf8.encode(courseText));
    await restored.loadPeopleFromBytes(utf8.encode(peopleText));
    restored.loadStateFromBytes(utf8.encode(legacyStateOnly));

    final restoredCoordinators =
        restored.courseControl.getCoordinators(targetCourse)!;
    expect(restored.getStateOfProcessing(), StateOfProcessing.output);
    expect(restoredCoordinators.equal, isTrue);
    expect(restoredCoordinators.coordinators, sourceCoordinators.coordinators);
  });
}
