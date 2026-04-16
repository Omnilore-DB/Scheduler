import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/widgets/table/schedule_row.dart';

class _ScheduleToggleHarness extends StatefulWidget {
  const _ScheduleToggleHarness({required this.schedule, required this.course});

  final Scheduling schedule;
  final String course;

  @override
  State<_ScheduleToggleHarness> createState() => _ScheduleToggleHarnessState();
}

class _ScheduleToggleHarnessState extends State<_ScheduleToggleHarness> {
  late final List<String> _courses = [widget.course];
  late final List<int> _scheduleRowData = [999];
  late final List<bool> _droppedList = [false];
  late final List<int> _scheduleData = [-1];

  String? _currentClass;

  void _refreshScheduleData() {
    _scheduleData[0] =
        widget.schedule.scheduleControl.scheduledTimeFor(widget.course);
  }

  void _onSchedule(String course, int timeIndex) {
    var deselected = false;
    setState(() {
      _currentClass = course;
      widget.schedule.splitControl.resetState();
      final currentTime = widget.schedule.scheduleControl.scheduledTimeFor(course);
      if (currentTime == timeIndex) {
        widget.schedule.scheduleControl.unschedule(course, timeIndex);
        deselected = true;
      } else {
        widget.schedule.scheduleControl.schedule(_currentClass!, timeIndex);
      }
      _refreshScheduleData();
    });
    if (deselected) {
      widget.schedule.compute(Change.schedule);
      setState(_refreshScheduleData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Table(
          children: [
            ScheduleRow(
              0,
              _courses,
              _scheduleRowData,
              _scheduleData,
              StateOfProcessing.schedule,
              _droppedList,
              _onSchedule,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('tapping the same scheduled slot again deselects it',
      (WidgetTester tester) async {
    final scheduling = Scheduling();
    await tester.runAsync(() async {
      await scheduling.loadCourses('test/resources/course.txt');
      await scheduling.loadPeople('test/resources/people.txt');
    });
    final course = scheduling.getCourseCodes().first;

    await tester.pumpWidget(
      _ScheduleToggleHarness(schedule: scheduling, course: course),
    );

    final targetCell = find.widgetWithText(TextButton, '999');
    expect(targetCell, findsOneWidget);
    expect(scheduling.scheduleControl.scheduledTimeFor(course), -1);

    await tester.tap(targetCell);
    await tester.pump();

    expect(scheduling.scheduleControl.scheduledTimeFor(course), 0);
    final scheduledButton = tester.widget<TextButton>(targetCell);
    expect(scheduledButton.style?.backgroundColor?.resolve({}), Colors.red);

    await tester.tap(targetCell);
    await tester.pump();

    expect(scheduling.scheduleControl.scheduledTimeFor(course), -1);
    final deselectedButton = tester.widget<TextButton>(targetCell);
    expect(
      deselectedButton.style?.backgroundColor?.resolve({}),
      Colors.transparent,
    );
  });
}
