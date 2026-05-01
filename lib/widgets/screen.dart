import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:omnilore_scheduler/model/change.dart';

import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/class_name_display.dart';
import 'package:omnilore_scheduler/widgets/class_size_control.dart';
import 'package:omnilore_scheduler/widgets/names_display_mode.dart';
import 'package:omnilore_scheduler/widgets/table/main_table.dart';
import 'package:omnilore_scheduler/widgets/overview_data.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
import 'package:omnilore_scheduler/widgets/table/schedule_row.dart';
import 'package:omnilore_scheduler/widgets/utils.dart';

import 'package:omnilore_scheduler/io/web_download_factory.dart' as web_dl;
import 'package:omnilore_scheduler/io/autosave_store_factory.dart' as autosave;
import 'package:omnilore_scheduler/io/bundled_state.dart';
import 'package:omnilore_scheduler/io/default_filename.dart';
import 'package:omnilore_scheduler/io/export_text_file.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

const stateDescriptions = <String>[
  'Need Courses',
  'Need People',
  'Inconsistent',
  'Drop and Split',
  'Drop and Split',
  'Schedule',
  'Coordinator',
  'Output'
];

class Screen extends StatefulWidget {
  const Screen({Key? key}) : super(key: key);

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  /// this is the main scheduling data structure that holds back end computation
  Scheduling schedule = Scheduling();

  final GlobalKey<ClassNameDisplayState> _classNameDisplayKey = GlobalKey();

  int? numCourses;
  int? numPeople;
  List<String> curClassRoster = [];
  List<List<String>> curClusters = [];
  List<bool> droppedList = List<bool>.filled(14, false, growable: true);
  List<int> scheduleData = List<int>.filled(14, -1, growable: false);

  // Coordinator selection mode: 'none', 'main', or 'equal'
  String coordinatorMode = 'none';

  // Autosave state
  Timer? _autosaveTimer;
  String _lastAutoSavedContent = '';
  bool _autosaveCheckDone = false;
  String? _courseSourceData;
  String? _peopleSourceData;

  // Split preview state
  bool isShowingSplitPreview = false;
  String? splitCourseInProgress;
  Map<int, Set<String>> tempSplitResult = {}; // indexed by split number
  int? currentSplitGroupSelected; // which split group to display

  Color masterBackgroundColor = themeColors['WhiteBlue'];
  Color detailBackgroundColor = Colors.blueGrey[300] as Color;

  late int courseTakers = schedule.overviewData.getNbrCourseTakers();
  late int goCourses = schedule.overviewData.getNbrGoCourses();
  late int placesAsked = schedule.overviewData.getNbrPlacesAsked();
  late int placesGiven = schedule.overviewData.getNbrPlacesGiven();
  late int unmetWants = schedule.overviewData.getNbrUnmetWants();
  late int onLeave = schedule.overviewData.getNbrOnLeave();

  List<String> courses = [];
  late var overviewMatrix = List<List<int>>.generate(overviewRows.length,
      (i) => List<int>.filled(numCourses ?? 14, 0, growable: false),
      growable: false);
  late var scheduleMatrix = List<List<int>>.generate(scheduleRows.length,
      (i) => List<int>.filled(numCourses ?? 14, 0, growable: false),
      growable: false);

  String? currentClass;
  RowType currentRow = RowType.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForSavedState());
  }

  void compute(Change change) {
    setState(() {
      if (change == Change.course) {
        _updateCourses();
      }
      _updateOverviewData();
      _updateOverviewMatrix();
      _updateScheduleMatrix();
      if (change == Change.course || change == Change.schedule) {
        _updateScheduleData();
      }
    });
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), _performAutosave);
  }

  void _performAutosave() {
    var state = schedule.getStateOfProcessing();
    if (state == StateOfProcessing.needCourses ||
        state == StateOfProcessing.needPeople) {
      return;
    }
    var content = schedule.exportStateToString();
    if (content == _lastAutoSavedContent) return;
    _lastAutoSavedContent = content;
    autosave.saveAutosave(_buildBundledSaveContent());
  }

  /// Show split preview for the current class
  void _showSplitPreview() {
    if (currentClass == null || currentRow != RowType.resultingClass) return;

    var splitResult = schedule.splitControl.getSplitResult(currentClass!);
    if (splitResult.isEmpty) return;

    setState(() {
      tempSplitResult = {};
      for (int i = 0; i < splitResult.length; i++) {
        tempSplitResult[i] = Set.from(splitResult[i]);
      }
      isShowingSplitPreview = true;
      splitCourseInProgress = currentClass;
      currentRow = RowType.splitPreview;
      currentSplitGroupSelected = 0;
      _updateSplitPreviewRoster();
    });
  }

  /// Update curClassRoster to show the selected split group during preview
  void _updateSplitPreviewRoster() {
    if (currentSplitGroupSelected != null &&
        tempSplitResult.containsKey(currentSplitGroupSelected)) {
      curClassRoster = tempSplitResult[currentSplitGroupSelected]!.toList();
      curClassRoster.sort();
    } else {
      curClassRoster = [];
    }
  }

  /// Move a person between split groups
  void _movePersonBetweenSplits(String person, int fromGroup, int toGroup) {
    setState(() {
      if (tempSplitResult.containsKey(fromGroup)) {
        tempSplitResult[fromGroup]!.remove(person);
      }
      if (!tempSplitResult.containsKey(toGroup)) {
        tempSplitResult[toGroup] = <String>{};
      }
      tempSplitResult[toGroup]!.add(person);
      _updateSplitPreviewRoster();
    });
  }

  /// Implement the split with the current tempSplitResult
  void _implementSplit() {
    if (splitCourseInProgress == null) return;

    int minSize =
        schedule.courseControl.getMinClassSize(splitCourseInProgress!);
    int maxSize =
        schedule.courseControl.getMaxClassSize(splitCourseInProgress!);
    for (var group in tempSplitResult.values) {
      if (group.length < minSize || group.length > maxSize) {
        Utils.showPopUp(context, 'Invalid split',
            'All split groups must have between $minSize and $maxSize people.');
        return;
      }
    }

    try {
      // Apply the modified split
      schedule.splitControl.applySplit(splitCourseInProgress!, tempSplitResult);

      var newCourses = schedule.getCourseCodes();
      droppedList.insertAll(courses.indexOf(splitCourseInProgress!),
          List<bool>.filled(newCourses.length - courses.length, false));

      // Reset split preview state
      isShowingSplitPreview = false;
      tempSplitResult.clear();
      splitCourseInProgress = null;
      currentSplitGroupSelected = null;
      currentClass = null;
      currentRow = RowType.none;
      curClassRoster = [];

      compute(Change.course);
    } catch (e) {
      if (mounted) {
        Utils.showPopUp(context, 'Error implementing split', e.toString());
      }
    }
  }

  /// Cancel split preview and go back
  void _cancelSplitPreview() {
    setState(() {
      isShowingSplitPreview = false;
      tempSplitResult.clear();
      splitCourseInProgress = null;
      currentSplitGroupSelected = null;
      currentClass = null;
      currentRow = RowType.none;
      curClassRoster = [];
    });
  }

  /// Check for saved state and show restore dialog if applicable
  void _checkForSavedState() {
    if (_autosaveCheckDone) return;
    _autosaveCheckDone = true;

    var savedAutosave = autosave.loadAutosave();
    var savedHardSave = autosave.loadHardSave();

    if (savedAutosave == null && savedHardSave == null) return;

    if (savedAutosave != null &&
        savedHardSave != null &&
        savedAutosave != savedHardSave) {
      _showTwoOptionRestoreDialog(savedAutosave, savedHardSave);
    } else {
      var content = savedAutosave ?? savedHardSave!;
      var label = savedAutosave != null ? 'autosave' : 'last save';
      _showSingleOptionRestoreDialog(content, label);
    }
  }

  void _showSingleOptionRestoreDialog(String content, String label) {
    var timestamp = label == 'autosave'
        ? autosave.getAutosaveTimestamp()
        : autosave.getHardSaveTimestamp();
    var timeDisplay =
        timestamp != null ? ' from ${_formatTimestamp(timestamp)}' : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Previous Session Found'),
        content:
            Text('Found $label$timeDisplay. Would you like to restore it?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              autosave.clearAutosave();
              autosave.clearHardSave();
              autosave.clearCourseData();
              autosave.clearPeopleData();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreState(content);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showTwoOptionRestoreDialog(
      String autosaveContent, String hardSaveContent) {
    var autoTime = autosave.getAutosaveTimestamp();
    var hardTime = autosave.getHardSaveTimestamp();
    var autoDisplay =
        autoTime != null ? ' (${_formatTimestamp(autoTime)})' : '';
    var hardDisplay =
        hardTime != null ? ' (${_formatTimestamp(hardTime)})' : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Previous Session Found'),
        content: Text(
            'Found both an autosave$autoDisplay and a hard save$hardDisplay. '
            'Which would you like to restore?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              autosave.clearAutosave();
              autosave.clearHardSave();
              autosave.clearCourseData();
              autosave.clearPeopleData();
            },
            child: const Text('Start Fresh'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreState(hardSaveContent);
            },
            child: Text('Last Hard Save$hardDisplay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreState(autosaveContent);
            },
            child: Text('Continue from Autosave$autoDisplay'),
          ),
        ],
      ),
    );
  }

  /// Shows a loading dialog with [message] while [work] executes, then
  /// dismisses it. The dialog is non-dismissible so the user can't tap away.
  Future<void> _withLoadingDialog(String message, Future<void> Function() work,
      {bool showSpinner = true}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: showSpinner
              ? Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Expanded(child: Text(message)),
                  ],
                )
              : Text(message),
        ),
      ),
    );
    // Yield so Flutter can paint the dialog before heavy sync work begins.
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      await work();
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _restoreState(String content) async {
    String? cannotRestoreMessage;
    Object? restoreError;

    await _withLoadingDialog('Restoring session...', () async {
      try {
        final parsed = parseBundledStateContent(content);
        var courseData =
            parsed.courseData ?? _courseSourceData ?? autosave.loadCourseData();
        var peopleData =
            parsed.peopleData ?? _peopleSourceData ?? autosave.loadPeopleData();

        if (courseData == null || peopleData == null) {
          cannotRestoreMessage =
              'Saved course or people data not found. Please import courses and people manually.';
          return;
        }

        setState(() {
          schedule = Scheduling();
        });
        await schedule.loadCoursesFromBytes(utf8.encode(courseData));
        _courseSourceData = courseData;
        autosave.saveCourseData(courseData);
        numCourses = schedule.getCourseCodes().length;
        droppedList = List<bool>.filled(numCourses!, false, growable: true);
        await Future.delayed(Duration.zero); // yield for UI
        await schedule.loadPeopleFromBytes(utf8.encode(peopleData));
        _peopleSourceData = peopleData;
        autosave.savePeopleData(peopleData);
        numPeople = schedule.getNumPeople();
        await Future.delayed(Duration.zero); // yield for UI
        if (!mounted) return;

        schedule.loadStateFromBytes(utf8.encode(parsed.stateContent));
        // Rebuild droppedList from actual state after loadStateFromBytes
        final restoredCourses = schedule.getCourseCodes().toList();
        final dropped = schedule.courseControl.getDropped();
        numCourses = restoredCourses.length;
        droppedList = List<bool>.generate(
            numCourses!, (i) => dropped.contains(restoredCourses[i]));
        _lastAutoSavedContent = schedule.exportStateToString();
        compute(Change.course);
      } catch (e) {
        restoreError = e;
      }
    });

    if (!mounted) return;
    if (cannotRestoreMessage != null) {
      Utils.showPopUp(context, 'Cannot Restore', cannotRestoreMessage!);
    } else {
      final error = restoreError;
      if (error == null) return;
      Utils.showPopUp(
          context, 'Error restoring state', Utils.getErrorMessage(error));
    }
  }

  String _formatTimestamp(String isoTimestamp) {
    try {
      var dt = DateTime.parse(isoTimestamp);
      var month = dt.month.toString().padLeft(2, '0');
      var day = dt.day.toString().padLeft(2, '0');
      var hour = dt.hour.toString().padLeft(2, '0');
      var minute = dt.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    } catch (_) {
      return isoTimestamp;
    }
  }

  String _buildBundledSaveContent() {
    final state = schedule.exportStateToString();
    final courseData = _courseSourceData ?? autosave.loadCourseData();
    final peopleData = _peopleSourceData ?? autosave.loadPeopleData();
    return buildBundledStateContent(
        stateContent: state, courseData: courseData, peopleData: peopleData);
  }

  Future<void> _loadBundledState(List<int> bytes) async {
    final text = utf8.decode(bytes);
    final parsed = parseBundledStateContent(text);

    // Resolve course and people source text: prefer embedded, then fall back to
    // what is already in memory or the autosave store (handles legacy saves that
    // embedded only the course section but not the people section).
    final resolvedCourseText =
        parsed.courseData ?? _courseSourceData ?? autosave.loadCourseData();
    final resolvedPeopleText =
        parsed.peopleData ?? _peopleSourceData ?? autosave.loadPeopleData();

    if (resolvedCourseText != null && resolvedPeopleText != null) {
      setState(() {
        schedule = Scheduling();
      });
      await schedule.loadCoursesFromBytes(utf8.encode(resolvedCourseText));
      _courseSourceData = resolvedCourseText;
      autosave.saveCourseData(resolvedCourseText);
      await Future.delayed(Duration.zero);
      await schedule.loadPeopleFromBytes(utf8.encode(resolvedPeopleText));
      _peopleSourceData = resolvedPeopleText;
      autosave.savePeopleData(resolvedPeopleText);
      await Future.delayed(Duration.zero);
    } else if (!parsed.hasEmbeddedSourceData) {
      // Legacy state-only file: apply state on top of the already-loaded data.
    } else {
      throw StateError(
          'Cannot restore: course or people data is missing. '
          'Please import courses and people manually.');
    }

    schedule.loadStateFromBytes(utf8.encode(parsed.stateContent));
    final loadedCourses = schedule.getCourseCodes().toList();
    final loadedNumCourses = loadedCourses.length;
    final dropped = schedule.courseControl.getDropped();
    final loadedDropped = List<bool>.generate(
        loadedNumCourses, (i) => dropped.contains(loadedCourses[i]));
    final loadedContent = _buildBundledSaveContent();
    autosave.saveHardSave(loadedContent);
    autosave.clearAutosave();
    setState(() {
      numCourses = loadedNumCourses;
      numPeople = schedule.getNumPeople();
      droppedList = loadedDropped;
      _lastAutoSavedContent = schedule.exportStateToString();
    });
    compute(Change.course);
  }

  /// Helper function to update courses
  void _updateCourses() {
    courses = schedule.getCourseCodes().toList();
  }

  /// Helper function to update all of overviewData
  void _updateOverviewData() {
    courseTakers = schedule.overviewData.getNbrCourseTakers();
    goCourses = schedule.overviewData.getNbrGoCourses();
    placesAsked = schedule.overviewData.getNbrPlacesAsked();
    placesGiven = schedule.overviewData.getNbrPlacesGiven();
    unmetWants = schedule.overviewData.getNbrUnmetWants();
    onLeave = schedule.overviewData.getNbrOnLeave();
  }

  /// Helper function to update the overview table data
  void _updateOverviewMatrix() {
    if (courses.length != overviewMatrix[0].length) {
      for (int i = 0; i < overviewMatrix.length; i++) {
        overviewMatrix[i] = List<int>.filled(courses.length, 0);
      }
    }
    for (int i = 0; i < overviewMatrix[0].length; i++) {
      var course = courses[i];
      for (int rank = 0; rank < 4; rank++) {
        overviewMatrix[rank][i] =
            schedule.overviewData.getNbrForClassRank(course, rank).size;
      }
      overviewMatrix[4][i] = schedule.overviewData.getNbrAddFromBackup(course);
      overviewMatrix[5][i] = schedule.overviewData.getNbrDropTime(course);
      overviewMatrix[6][i] = schedule.overviewData.getNbrDropDup(course);
      overviewMatrix[7][i] = schedule.overviewData.getNbrDropFull(course);
      overviewMatrix[8][i] =
          schedule.overviewData.getResultingClassSize(course).size;
    }
  }

  /// Helper function to update schedule data
  void _updateScheduleMatrix() {
    if (courses.length != scheduleMatrix[0].length) {
      for (int i = 0; i < scheduleMatrix.length; i++) {
        scheduleMatrix[i] = List<int>.filled(courses.length, 0);
      }
    }
    for (int i = 0; i < scheduleMatrix[0].length; i++) {
      var course = courses[i];
      for (int time = 0; time < 20; time++) {
        scheduleMatrix[time][i] =
            schedule.scheduleControl.getNbrUnavailable(course, time);
      }
    }
  }

  /// Helper function to update course schedule data
  void _updateScheduleData() {
    if (courses.length != scheduleData.length) {
      scheduleData = List<int>.filled(courses.length, -1, growable: false);
    }
    for (int i = 0; i < courses.length; i++) {
      scheduleData[i] = schedule.scheduleControl.scheduledTimeFor(courses[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreen(
        masterPaneFixedWidth: true,
        detailPaneFlex: 0,
        menuList: [
          MenuItem(title: 'File', menuListItems: [
            MenuListItem(
              icon: Icons.open_in_new,
              title: 'Import Course',
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['txt'],
                    withData: true);

                if (result != null) {
                  try {
                    late int? newNumCourses;
                    // Prefer bytes on all platforms so we can persist exact
                    // raw input for bundled saves/autosave restore.
                    if (result.files.single.bytes != null) {
                      final bytes = result.files.single.bytes!;
                      newNumCourses =
                          await schedule.loadCoursesFromBytes(bytes);
                      _courseSourceData = utf8.decode(bytes);
                      autosave.saveCourseData(_courseSourceData!);
                    } else {
                      String path = result.files.single.path ?? '';
                      if (path != '') {
                        newNumCourses = await schedule.loadCourses(path);
                        _courseSourceData = schedule.readText(path);
                        autosave.saveCourseData(_courseSourceData!);
                      }
                    }
                    if (newNumCourses != null) {
                      numCourses = newNumCourses;
                      droppedList =
                          List<bool>.filled(numCourses!, false, growable: true);
                      compute(Change.course);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Utils.showPopUp(context, 'Error loading courses',
                          Utils.getErrorMessage(e));
                    }
                  }
                }
              },
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyO, ctrl: true),
            ),
            MenuListItem(
              title: 'Import People',
              icon: Icons.open_in_new,
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['txt'],
                    withData: true);

                if (result != null) {
                  try {
                    int? newNumPeople;
                    // On web, use bytes; on native platforms, use path
                    if (result.files.single.bytes != null) {
                      final bytes = result.files.single.bytes!;
                      newNumPeople = await schedule.loadPeopleFromBytes(bytes);
                      _peopleSourceData = utf8.decode(bytes);
                      autosave.savePeopleData(_peopleSourceData!);
                    } else {
                      String path = result.files.single.path ?? '';
                      if (path != '') {
                        newNumPeople = await schedule.loadPeople(path);
                        _peopleSourceData = schedule.readText(path);
                        autosave.savePeopleData(_peopleSourceData!);
                      }
                    }
                    if (newNumPeople != null) {
                      numPeople = newNumPeople;
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Utils.showPopUp(context, 'Error loading people',
                          Utils.getErrorMessage(e));
                    }
                  }
                } else {
                  // User canceled the picker
                }
                compute(Change.people);
                _checkForSavedState();
              },
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyP, ctrl: true),
            ),
            MenuListItem(
              title: 'Save',
              onPressed: () async {
                try {
                  final stateContent = schedule.exportStateToString();
                  final bundledContent = _buildBundledSaveContent();
                  final filename = defaultExportFilename('scheduling_state');
                  if (kIsWeb) {
                    await _withLoadingDialog('Saving...', () async {
                      web_dl.triggerDownload(bundledContent, filename);
                    });
                  } else {
                    String? path = await FilePicker.platform.saveFile(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        fileName: filename);
                    if (path != null && path != '') {
                      schedule.exportText(path, bundledContent);
                    }
                  }
                  autosave.saveHardSave(bundledContent);
                  autosave.clearAutosave();
                  _lastAutoSavedContent = stateContent;
                } catch (e) {
                  if (context.mounted) {
                    Utils.showPopUp(context, 'Error saving state',
                        Utils.getErrorMessage(e));
                  }
                }
              },
            ),
            MenuListItem(
              title: 'Save As',
              onPressed: () async {
                try {
                  final stateContent = schedule.exportStateToString();
                  final content = _buildBundledSaveContent();
                  final filename = defaultExportFilename('scheduling_state');
                  if (kIsWeb) {
                    await _withLoadingDialog('Saving...', () async {
                      await web_dl.triggerSaveAs(content, filename);
                    });
                  } else {
                    String? path = await FilePicker.platform.saveFile(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        fileName: filename);
                    if (path != null && path != '') {
                      schedule.exportText(path, content);
                    }
                  }
                  autosave.saveHardSave(content);
                  autosave.clearAutosave();
                  _lastAutoSavedContent = stateContent;
                } catch (e) {
                  if (context.mounted) {
                    Utils.showPopUp(context, 'Error saving state',
                        Utils.getErrorMessage(e));
                  }
                }
              },
            ),
            MenuListItem(
              title: 'Load',
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyD, ctrl: true),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['txt'],
                    withData: true);

                if (result != null) {
                  try {
                    await _withLoadingDialog('Loading...', () async {
                      if (result.files.single.bytes != null) {
                        await _loadBundledState(result.files.single.bytes!);
                      } else {
                        throw StateError(
                            'File bytes are unavailable; please enable file data in picker.');
                      }
                    }, showSpinner: false);
                  } catch (e) {
                    if (context.mounted) {
                      Utils.showPopUp(context, 'Error loading state',
                          Utils.getErrorMessage(e));
                    }
                  }
                }
              },
            ),
            MenuListItem(
                title: 'Export Early Roster',
                onPressed: () async {
                  try {
                    final content = schedule.outputRosterPhoneToString();
                    final filename = defaultExportFilename('early_roster');
                    await exportTextFile(
                      isWeb: kIsWeb,
                      content: content,
                      suggestedName: filename,
                      allowCustomNameOnWeb: true,
                      saveAs: web_dl.triggerSaveAs,
                      download: web_dl.triggerDownload,
                      pickSavePath: () => FilePicker.platform.saveFile(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        fileName: filename,
                      ),
                      writeToPath: schedule.exportText,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      Utils.showPopUp(context, 'Error exporting early roster',
                          Utils.getErrorMessage(e));
                    }
                  }
                }),
            MenuListItem(
                title: 'Export Final Roster',
                onPressed: () async {
                  try {
                    final content = schedule.outputRosterCCToString();
                    final filename = defaultExportFilename('final_roster');
                    await exportTextFile(
                      isWeb: kIsWeb,
                      content: content,
                      suggestedName: filename,
                      allowCustomNameOnWeb: true,
                      saveAs: web_dl.triggerSaveAs,
                      download: web_dl.triggerDownload,
                      pickSavePath: () => FilePicker.platform.saveFile(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        fileName: filename,
                      ),
                      writeToPath: schedule.exportText,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      Utils.showPopUp(context, 'Error exporting roster with CC',
                          Utils.getErrorMessage(e));
                    }
                  }
                }),
            MenuListItem(
              title: 'Export MailMerge',
              onPressed: () async {
                try {
                  final content = schedule.outputMMToString();
                  final filename = defaultExportFilename('mail_merge');
                  await exportTextFile(
                    isWeb: kIsWeb,
                    content: content,
                    suggestedName: filename,
                    allowCustomNameOnWeb: true,
                    saveAs: web_dl.triggerSaveAs,
                    download: web_dl.triggerDownload,
                    pickSavePath: () => FilePicker.platform.saveFile(
                      type: FileType.custom,
                      allowedExtensions: ['txt'],
                      fileName: filename,
                    ),
                    writeToPath: schedule.exportText,
                  );
                } catch (e) {
                  if (context.mounted) {
                    Utils.showPopUp(context, 'Error exporting MailMerge',
                        Utils.getErrorMessage(e));
                  }
                }
              },
            ),
            MenuListItem(
              title: 'Export Unmet Wants',
              onPressed: () async {
                try {
                  final content = schedule.outputUnmetWantsToString();
                  final filename = defaultExportFilename('unmet_wants');
                  await exportTextFile(
                    isWeb: kIsWeb,
                    content: content,
                    suggestedName: filename,
                    allowCustomNameOnWeb: true,
                    saveAs: web_dl.triggerSaveAs,
                    download: web_dl.triggerDownload,
                    pickSavePath: () => FilePicker.platform.saveFile(
                      type: FileType.custom,
                      allowedExtensions: ['txt'],
                      fileName: filename,
                    ),
                    writeToPath: schedule.exportText,
                  );
                } catch (e) {
                  if (context.mounted) {
                    Utils.showPopUp(context, 'Error exporting unmet wants',
                        Utils.getErrorMessage(e));
                  }
                }
              },
            ),
          ]),
        ],
        masterPane: _masterPane(),
        detailPaneMinWidth: 0,
      ),
    );
  }

  /// This function builds the entire user interface which is split into the main
  /// datatable and screen1
  Builder _masterPane() {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          color: masterBackgroundColor,
          child: SingleChildScrollView(
              child: Column(
            children: [
              _screen1(),
              MainTable(
                  state: schedule.getStateOfProcessing(),
                  courses: numCourses == null
                      ? List<String>.filled(14, '')
                      : courses,
                  overviewMatrix: overviewMatrix,
                  scheduleMatrix: scheduleMatrix,
                  droppedList: droppedList,
                  scheduleData: scheduleData,
                  onCellPressed: (String course, RowType row) {
                    setState(() {
                      switch (row) {
                        case RowType.className:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course)
                              .toList();
                          // Reset coordinator selection mode when switching courses
                          coordinatorMode = 'none';
                          _classNameDisplayKey.currentState
                              ?.clearCoordinatorSelections();
                          break;
                        case RowType.firstChoice:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 0)
                              .toList();
                          break;
                        case RowType.firstBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 1)
                              .toList();
                          break;
                        case RowType.secondBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 2)
                              .toList();
                          break;
                        case RowType.thirdBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 3)
                              .toList();
                          break;
                        case RowType.addFromBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleAddFromBackup(course)
                              .toList();
                          break;
                        case RowType.dropBadTime:
                          curClassRoster = schedule.overviewData
                              .getPeopleDropTime(course)
                              .toList();
                          break;
                        case RowType.dropDup:
                          curClassRoster = schedule.overviewData
                              .getPeopleDropDup(course)
                              .toList();
                          break;
                        case RowType.dropFull:
                          curClassRoster = schedule.overviewData
                              .getPeopleDropFull(course)
                              .toList();
                          break;
                        case RowType.resultingClass:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course)
                              .toList();
                          schedule.splitControl.resetState();
                          break;
                        default:
                          break;
                      }

                      currentClass = course;
                      schedule.splitControl.resetState();
                      currentRow = row;
                      List<String> tempList = curClassRoster.toList();
                      tempList.sort(
                          (a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                      curClassRoster = tempList;
                    });
                  },
                  onDroppedChanged: (int i) {
                    setState(() {
                      droppedList[i] = !droppedList[i];
                      if (droppedList[i] == true) {
                        schedule.courseControl
                            .drop(schedule.getCourseCodes().toList()[i]);
                      } else {
                        schedule.courseControl
                            .undrop(schedule.getCourseCodes().toList()[i]);
                      }
                    });
                    compute(Change.drop);
                  },
                  onSchedule: (String course, int timeIndex) {
                    var deselected = false;
                    setState(() {
                      currentClass = course;
                      schedule.splitControl.resetState();
                      var currentTime =
                          schedule.scheduleControl.scheduledTimeFor(course);
                      if (currentTime == timeIndex) {
                        schedule.scheduleControl.unschedule(course, timeIndex);
                        deselected = true;
                      } else {
                        schedule.scheduleControl
                            .schedule(currentClass!, timeIndex);
                      }

                      List<String> tempList = curClassRoster.toList();
                      tempList.sort(
                          (a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                      curClassRoster = tempList;
                    });
                    if (deselected) {
                      // schedule() recomputes backend state internally, but
                      // unschedule() does not. Recompute here for deselection.
                      schedule.compute(Change.schedule);
                    }
                    compute(Change.schedule);
                  })
            ],
          )),
        );
      },
    );
  }

  /// This is the base widget that holds everything in the UI that is not the datatable
  Widget _screen1() {
    return SizedBox(
      height: 400,
      child: Row(
        children: [
          // State of processing widget and class name display widget
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: themeColors['MediumBlue'],
                  child: Text(
                      'State of Processing: ${stateDescriptions[schedule.getStateOfProcessing().index]}',
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ClassNameDisplay(
                      key: _classNameDisplayKey,
                      currentClass: currentClass,
                      currentRow: currentRow,
                      people: curClassRoster,
                      schedule: schedule,
                      isShowingSplitPreview: isShowingSplitPreview,
                      tempSplitResult: tempSplitResult,
                      currentSplitGroupSelected: currentSplitGroupSelected,
                      onMovePerson: _movePersonBetweenSplits,
                      onSelectSplitGroup: (groupNum) {
                        setState(() {
                          currentSplitGroupSelected = groupNum;
                          _updateSplitPreviewRoster();
                        });
                      },
                      onCancelSplitPreview: _cancelSplitPreview,
                      onCoordinatorAssignmentsChanged: () {
                        setState(() {});
                        _scheduleAutosave();
                      },
                      coordinatorMode: coordinatorMode),
                )
              ],
            ),
          ),

          //Class size control widget and Names display mode
          SizedBox(
            width: MediaQuery.of(context).size.width / 4,
            child: Column(
              children: [
                ClassSizeControl(
                    schedule: schedule, courses: courses, onChange: compute),
                Expanded(
                  child: NamesDisplayMode(
                    onShowSplits: currentRow == RowType.resultingClass &&
                            currentClass != null
                        ? _showSplitPreview
                        : null,
                    onImplSplit: (isShowingSplitPreview &&
                            currentRow == RowType.splitPreview &&
                            splitCourseInProgress != null)
                        ? _implementSplit
                        : (currentRow == RowType.resultingClass &&
                                currentClass != null
                            ? () {
                                setState(() {
                                  schedule.splitControl.split(currentClass!);
                                  var newCourses = schedule.getCourseCodes();
                                  droppedList.insertAll(
                                      courses.indexOf(currentClass!),
                                      List<bool>.filled(
                                          newCourses.length - courses.length,
                                          false));
                                  currentClass = null;
                                  currentRow = RowType.none;
                                  curClassRoster = [];
                                });
                                compute(Change.course);
                              }
                            : null),
                    onShowCoords: currentRow == RowType.className &&
                            coordinatorMode == 'none' &&
                            (schedule.getStateOfProcessing() ==
                                    StateOfProcessing.coordinator ||
                                schedule.getStateOfProcessing() ==
                                    StateOfProcessing.output)
                        ? () {
                            ClassNameDisplayState state =
                                _classNameDisplayKey.currentState!;
                            state.showCoordinators();
                          }
                        : null,
                    onSetC: currentRow == RowType.className &&
                            schedule.getStateOfProcessing() ==
                                StateOfProcessing.coordinator
                        ? () {
                            ClassNameDisplayState state =
                                _classNameDisplayKey.currentState!;
                            if (coordinatorMode == 'none') {
                              // Start main coordinator selection mode
                              // clear any existing selections so the user can
                              // pick both C and CC from scratch when re-entering
                              // this mode. Without this the previous main
                              // coordinator would remain highlighted and only
                              // the co-coordinator could be changed.
                              state.clearCoordinatorSelections();
                              setState(() {
                                coordinatorMode = 'main';
                              });
                            } else if (coordinatorMode == 'main') {
                              // Confirm and apply selections
                              state.setMainCoordinator();
                              setState(() {
                                coordinatorMode = 'none';
                              });
                            }
                          }
                        : null,
                    onSetCC: currentRow == RowType.className &&
                            schedule.getStateOfProcessing() ==
                                StateOfProcessing.coordinator
                        ? () {
                            ClassNameDisplayState state =
                                _classNameDisplayKey.currentState!;
                            if (coordinatorMode == 'none') {
                              // Start equal coordinator selection mode
                              // clear previous selections so both CC1 and CC2 can
                              // be chosen anew when re-entering this mode.
                              state.clearCoordinatorSelections();
                              setState(() {
                                coordinatorMode = 'equal';
                              });
                            } else if (coordinatorMode == 'equal') {
                              // Confirm and apply selections
                              state.setCoCoordinator();
                              setState(() {
                                coordinatorMode = 'none';
                              });
                            }
                          }
                        : null,
                    coordinatorMode: coordinatorMode,
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 4 - 5,
            child: OverviewData(
                placesAsked: placesAsked,
                placesGiven: placesGiven,
                goCourses: goCourses,
                unmetWants: unmetWants,
                onLeave: onLeave,
                courseTakers: courseTakers,
                onUnmetWantsClicked: () {
                  setState(() {
                    curClassRoster = schedule.overviewData
                        .getPeopleUnmetWants()
                        .toList();
                    currentRow = RowType.unmetWants;
                  });
                }),
          )
        ],
      ),
    );
  }
}
