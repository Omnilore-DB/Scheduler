@TestOn('browser')

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/io/autosave_store_factory.dart' as autosave;

void main() {
  setUp(() {
    autosave.clearAutosave();
    autosave.clearHardSave();
    autosave.clearCourseData();
    autosave.clearPeopleData();
  });

  tearDown(() {
    autosave.clearAutosave();
    autosave.clearHardSave();
    autosave.clearCourseData();
    autosave.clearPeopleData();
  });

  test('web autosave store persists and clears all save surfaces', () {
    autosave.saveAutosave('autosave-content');
    autosave.saveHardSave('hard-save-content');
    autosave.saveCourseData('course-data');
    autosave.savePeopleData('people-data');

    expect(autosave.loadAutosave(), 'autosave-content');
    expect(autosave.loadHardSave(), 'hard-save-content');
    expect(autosave.loadCourseData(), 'course-data');
    expect(autosave.loadPeopleData(), 'people-data');
    expect(autosave.getAutosaveTimestamp(), isNotNull);
    expect(autosave.getHardSaveTimestamp(), isNotNull);

    autosave.clearAutosave();
    autosave.clearHardSave();
    autosave.clearCourseData();
    autosave.clearPeopleData();

    expect(autosave.loadAutosave(), isNull);
    expect(autosave.loadHardSave(), isNull);
    expect(autosave.loadCourseData(), isNull);
    expect(autosave.loadPeopleData(), isNull);
    expect(autosave.getAutosaveTimestamp(), isNull);
    expect(autosave.getHardSaveTimestamp(), isNull);
  });
}
