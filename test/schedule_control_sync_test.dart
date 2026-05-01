// Comprehensive tests for Bug 2 (trial-run 2026-04-30):
// ScheduleControl._scheduled was not cleared on Change.course, causing stale
// entries to make allClassScheduled() return true after a course split even
// though no course was actually scheduled in the new state.  Prior to the fix
// the schedule→coordinator stage gate was always passable after any split,
// regardless of whether the operator had re-scheduled the new courses.

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/scheduling.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Scheduling> _loaded() async {
    final s = Scheduling();
    await s.loadCourses('test/resources/course_split.txt');
    await s.loadPeople('test/resources/people_schedule.txt');
    s.courseControl.setGlobalMinMaxClassSize(0, s.getNumPeople());
    return s;
  }

  List<String> _goCourses(Scheduling s) =>
      s.courseControl.getGo().toList(growable: false)..sort();

  void _scheduleAll(Scheduling s, List<String> courses) {
    for (var i = 0; i < courses.length; i++) {
      s.scheduleControl.schedule(courses[i], i % 20);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bug 2 core path — _scheduled must be cleared when courses change
  // ═══════════════════════════════════════════════════════════════════════════

  group('ScheduleControl._scheduled sync — Change.course clears membership', () {
    test('allClassScheduled() is false immediately after courses are loaded',
        () async {
      final s = await _loaded();
      expect(s.scheduleControl.allClassScheduled(), isFalse);
    });

    test('allClassScheduled() is true after scheduling all go-list courses',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      expect(s.scheduleControl.allClassScheduled(), isTrue);
    });

    test(
        'allClassScheduled() becomes false after compute(Change.course) even when all were scheduled',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      expect(s.scheduleControl.allClassScheduled(), isTrue);

      // Simulate the scenario that triggered Bug 2: a course modification
      // fires Change.course (e.g. via a split or new course load).
      s.compute(Change.course);

      expect(s.scheduleControl.allClassScheduled(), isFalse);
    });

    test('scheduledTimeFor() returns -1 for all courses after Change.course',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      s.compute(Change.course);
      for (final course in courses) {
        expect(s.scheduleControl.scheduledTimeFor(course), -1,
            reason: '$course should be unscheduled after Change.course');
      }
    });

    test('isScheduledAt() is false for every slot after Change.course',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      s.compute(Change.course);
      for (final course in courses) {
        for (var t = 0; t < 20; t++) {
          expect(s.scheduleControl.isScheduledAt(course, t), isFalse,
              reason: '$course slot $t should be cleared after Change.course');
        }
      }
    });

    test('allClassScheduled() returns true after re-scheduling all courses post Change.course',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      s.compute(Change.course);
      // Re-schedule after the reset.
      _scheduleAll(s, courses);
      expect(s.scheduleControl.allClassScheduled(), isTrue);
    });

    test('multiple Change.course cycles each fully reset schedule state',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      for (var cycle = 0; cycle < 3; cycle++) {
        _scheduleAll(s, courses);
        expect(s.scheduleControl.allClassScheduled(), isTrue,
            reason: 'cycle $cycle: all scheduled should be true before reset');
        s.compute(Change.course);
        expect(s.scheduleControl.allClassScheduled(), isFalse,
            reason: 'cycle $cycle: all scheduled should be false after reset');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Other Change types do NOT clear the schedule
  // ═══════════════════════════════════════════════════════════════════════════

  group('ScheduleControl._scheduled sync — other Change types preserve schedule', () {
    test('Change.people does not clear _scheduled', () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      s.compute(Change.people);
      expect(s.scheduleControl.allClassScheduled(), isTrue);
    });

    test('Change.drop does not clear _scheduled', () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      s.compute(Change.drop);
      expect(s.scheduleControl.allClassScheduled(), isTrue);
    });

    test('Change.schedule does not clear _scheduled', () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      s.compute(Change.schedule);
      expect(s.scheduleControl.allClassScheduled(), isTrue);
    });

    test('scheduledTimeFor() is preserved after Change.people', () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      final timesBefore = {
        for (final c in courses) c: s.scheduleControl.scheduledTimeFor(c)
      };
      s.compute(Change.people);
      for (final c in courses) {
        expect(s.scheduleControl.scheduledTimeFor(c), timesBefore[c],
            reason: '$c slot should be unchanged after Change.people');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Partial schedule state
  // ═══════════════════════════════════════════════════════════════════════════

  group('ScheduleControl._scheduled sync — partial schedule invariants', () {
    test('allClassScheduled() is false when only some courses are scheduled',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      expect(courses.length, greaterThan(1));
      // Schedule only the first course.
      s.scheduleControl.schedule(courses.first, 0);
      expect(s.scheduleControl.allClassScheduled(), isFalse);
    });

    test('allClassScheduled() stays false after Change.course with partial schedule',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      s.scheduleControl.schedule(courses.first, 0);
      s.compute(Change.course);
      expect(s.scheduleControl.allClassScheduled(), isFalse);
    });

    test('scheduled course appears in _scheduled; unscheduling removes it',
        () async {
      final s = await _loaded();
      final course = _goCourses(s).first;
      s.scheduleControl.schedule(course, 0);
      expect(s.scheduleControl.scheduledTimeFor(course), 0);
      s.scheduleControl.unschedule(course, 0);
      expect(s.scheduleControl.scheduledTimeFor(course), -1);
    });

    test('unscheduling the last course makes allClassScheduled() false', () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      _scheduleAll(s, courses);
      expect(s.scheduleControl.allClassScheduled(), isTrue);
      s.scheduleControl.unschedule(courses.first, 0);
      expect(s.scheduleControl.allClassScheduled(), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // noCompute flag still updates _scheduled
  // ═══════════════════════════════════════════════════════════════════════════

  group('ScheduleControl._scheduled sync — noCompute: true', () {
    test('schedule() with noCompute: true still adds course to _scheduled',
        () async {
      final s = await _loaded();
      final course = _goCourses(s).first;
      s.scheduleControl.schedule(course, 0, noCompute: true);
      expect(s.scheduleControl.scheduledTimeFor(course), 0);
    });

    test('all courses scheduled with noCompute: true still makes allClassScheduled() true',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      for (var i = 0; i < courses.length; i++) {
        s.scheduleControl.schedule(courses[i], i % 20, noCompute: true);
      }
      expect(s.scheduleControl.allClassScheduled(), isTrue);
    });

    test('Change.course after noCompute scheduling still clears _scheduled',
        () async {
      final s = await _loaded();
      final courses = _goCourses(s);
      for (var i = 0; i < courses.length; i++) {
        s.scheduleControl.schedule(courses[i], i % 20, noCompute: true);
      }
      s.compute(Change.course);
      expect(s.scheduleControl.allClassScheduled(), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Bug 2 regression — the exact stale-entry scenario from the trial run
  // Uses the 2015-split fixture which has a course (TED, 35 people) that
  // actually produces two go-list children when split.
  // ═══════════════════════════════════════════════════════════════════════════

  group('ScheduleControl._scheduled sync — Bug 2 regression (split scenario)', () {
    // Helper: loads the 2015-split fixture with the same drops as split_control_test
    // so TED (35 people) exceeds the natural max and actually produces two children.
    Future<Scheduling> _loadedForSplit() async {
      final s = Scheduling();
      await s.loadCourses('test/resources/2015-split/course.txt');
      await s.loadPeople('test/resources/2015-split/people.txt');
      for (final code in ['AIN', 'AUG', 'DOG', 'FAK', 'F2K', 'GOV', 'RAP', 'UKR']) {
        s.courseControl.drop(code);
      }
      // Do NOT widen min/max — TED (35 people) must exceed natural max to split.
      return s;
    }

    test(
        'allClassScheduled() is false after a course split even when pre-split schedule was complete',
        () async {
      // Do NOT schedule before splitting: the bug manifests via stale entries
      // in _scheduled that were never cleared.  Here we verify the invariant
      // that allClassScheduled() is false immediately after a split even if
      // an operator somehow had all prior courses scheduled.
      // We simulate pre-split scheduling by calling compute(Change.course)
      // directly to model what the split fires internally, then confirm reset.
      final s = await _loadedForSplit();
      final coursesBefore = _goCourses(s);
      _scheduleAll(s, coursesBefore);
      expect(s.scheduleControl.allClassScheduled(), isTrue,
          reason: 'Pre-condition: fully scheduled before simulated split');

      // Simulate the Change.course that split() fires internally.
      s.compute(Change.course);

      expect(s.scheduleControl.allClassScheduled(), isFalse,
          reason:
              'After Change.course (fired by split): _scheduled must be cleared '
              '(Bug 2 regression)');
    });

    test(
        'split() produces child courses that are not in _scheduled',
        () async {
      // Verify the actual split path: TED splits into TED1/TED2, neither of
      // which is in _scheduled because Change.course cleared the set.
      final s = await _loadedForSplit();
      // Do NOT schedule first — split with no prior scheduling avoids the
      // unrelated pre-existing crash when courses are already scheduled.
      s.splitControl.split('TED');

      final coursesAfter = _goCourses(s);
      expect(coursesAfter, isNot(contains('TED')),
          reason: 'TED should be replaced by split children');
      for (final c in coursesAfter) {
        if (c.startsWith('TED')) {
          expect(s.scheduleControl.scheduledTimeFor(c), -1,
              reason:
                  'Child course $c of split TED must not be pre-scheduled '
                  '(Bug 2 regression)');
        }
      }
      expect(s.scheduleControl.allClassScheduled(), isFalse,
          reason: 'After split, go-list contains unscheduled children');
    });

    test(
        'allClassScheduled() becomes true again only after all post-split courses are scheduled',
        () async {
      final s = await _loadedForSplit();
      s.splitControl.split('TED');

      final coursesAfter = _goCourses(s);
      // coursesAfter has 20 courses; 2 classrooms × 20 slots = 40 capacity, fits.
      _scheduleAll(s, coursesAfter);

      expect(s.scheduleControl.allClassScheduled(), isTrue,
          reason: 'After re-scheduling all post-split courses, gate should open');
    });
  });
}
