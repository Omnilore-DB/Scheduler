import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

Future<Scheduling> _buildSchedulingWithUnmetWants() async {
  var scheduling = Scheduling();
  await scheduling.loadCourses('test/resources/course_split.txt');
  await scheduling.loadPeople('test/resources/people_schedule.txt');

  scheduling.courseControl
      .setGlobalMinMaxClassSize(0, scheduling.getNumPeople());

  var goCourses = scheduling.courseControl.getGo().toList(growable: false)
    ..sort((a, b) => a.compareTo(b));
  scheduling.scheduleControl.setNbrClassrooms(goCourses.length);
  for (var course in goCourses) {
    scheduling.scheduleControl.schedule(course, 0);
  }

  return scheduling;
}

/// This file tests functionalities regarding loading courses.
void main() {
  test('Export: empty', () {
    var scheduling = Scheduling();
    scheduling.exportState('state.txt');
    var actual = File('state.txt').readAsStringSync();
    var expected =
        File('test/resources/gold/empty_state.txt').readAsStringSync();
    expect(actual, expected);
    File('state.txt').deleteSync();
  });

  test('exportStateToString: empty', () {
    var scheduling = Scheduling();
    var actual = scheduling.exportStateToString();
    var expected =
        File('test/resources/gold/empty_state.txt').readAsStringSync();
    expect(actual, expected);
  });

  test('exportStateToString: round-trip with state.txt', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    var stateBytes = File('test/resources/state.txt').readAsBytesSync();
    scheduling.loadStateFromBytes(stateBytes);

    var exported = scheduling.exportStateToString();

    var scheduling2 = Scheduling();
    await scheduling2.loadCourses('test/resources/course.txt');
    await scheduling2.loadPeople('test/resources/people.txt');
    scheduling2.loadStateFromBytes(exported.codeUnits);

    // Verify the state matches by checking each component
    // rather than exact string (drop order is non-deterministic)
    expect(scheduling2.courseControl.getGlobalMinClassSize(),
        scheduling.courseControl.getGlobalMinClassSize());
    expect(scheduling2.courseControl.getGlobalMaxClassSize(),
        scheduling.courseControl.getGlobalMaxClassSize());
    expect(scheduling2.courseControl.getDropped().toSet(),
        scheduling.courseControl.getDropped().toSet());
    expect(scheduling2.courseControl.getGo().toSet(),
        scheduling.courseControl.getGo().toSet());
  });

  test('exportState still writes to file (desktop compat)', () {
    var scheduling = Scheduling();
    scheduling.exportState('test_output_state.txt');
    var actual = File('test_output_state.txt').readAsStringSync();
    var expected =
        File('test/resources/gold/empty_state.txt').readAsStringSync();
    expect(actual, expected);
    File('test_output_state.txt').deleteSync();
  });

  test('outputUnmetWantsToString exports current unmet wants summary',
      () async {
    var scheduling = await _buildSchedulingWithUnmetWants();

    final summaries = scheduling.overviewData.getUnmetWantSummaries();
    expect(summaries, isNotEmpty);

    final firstSummary = summaries.first;
    final assignedCourses = firstSummary.assignedCourses.isEmpty
        ? 'none'
        : firstSummary.assignedCourses.join(', ');
    final actual = scheduling.outputUnmetWantsToString();

    expect(actual, contains('Unmet Wants'));
    expect(actual,
        contains('Total unmet wants: ${scheduling.overviewData.getNbrUnmetWants()}'));
    expect(actual, contains('People with unmet wants: ${summaries.length}'));
    expect(actual, contains(firstSummary.person.getReversedName()));
    expect(actual, contains('Wanted: ${firstSummary.wantedCount}'));
    expect(actual, contains('Given: ${firstSummary.givenCount}'));
    expect(actual, contains('Unmet: ${firstSummary.unmetCount}'));
    expect(actual, contains('Assigned: $assignedCourses'));
  });

  test('outputUnmetWants writes text file using export format', () async {
    var scheduling = await _buildSchedulingWithUnmetWants();

    scheduling.outputUnmetWants('test_output_unmet_wants.txt');
    var actual = File('test_output_unmet_wants.txt').readAsStringSync();

    expect(actual, scheduling.outputUnmetWantsToString());
    expect(actual, contains('Unmet Wants'));
    File('test_output_unmet_wants.txt').deleteSync();
  });
}
