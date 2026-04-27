class BundledStateContent {
  const BundledStateContent({
    required this.stateContent,
    this.courseData,
    this.peopleData,
  });

  final String stateContent;
  final String? courseData;
  final String? peopleData;

  bool get hasEmbeddedSourceData => courseData != null && peopleData != null;
}

String buildBundledStateContent({
  required String stateContent,
  String? courseData,
  String? peopleData,
}) {
  if (courseData == null || peopleData == null) {
    return stateContent;
  }
  return 'CourseFile:\n${courseData}PeopleFile:\n$peopleData$stateContent';
}

BundledStateContent parseBundledStateContent(String content) {
  if (!content.startsWith('CourseFile:\n')) {
    return BundledStateContent(stateContent: content);
  }

  const peopleMarker = '\nPeopleFile:\n';
  final peopleMarkerIndex = content.indexOf(peopleMarker);
  if (peopleMarkerIndex == -1) {
    throw const FormatException(
        'Saved file is missing the PeopleFile section.');
  }

  const stateMarker = '\nSetting:\n';
  final stateMarkerIndex = content.indexOf(stateMarker, peopleMarkerIndex + 1);
  if (stateMarkerIndex == -1) {
    throw const FormatException('Saved file is missing the state section.');
  }

  return BundledStateContent(
    courseData:
        content.substring('CourseFile:\n'.length, peopleMarkerIndex + 1),
    peopleData: content.substring(
        peopleMarkerIndex + peopleMarker.length, stateMarkerIndex + 1),
    stateContent: content.substring(stateMarkerIndex + 1),
  );
}
