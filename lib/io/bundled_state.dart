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
  return 'CourseFile:\n${_ensureTrailingNewline(courseData)}'
      'PeopleFile:\n${_ensureTrailingNewline(peopleData)}'
      '$stateContent';
}

BundledStateContent parseBundledStateContent(String content) {
  const courseMarker = 'CourseFile:\n';
  const peopleMarker = 'PeopleFile:\n';
  const stateMarker = 'Setting:\n';

  if (!content.startsWith(courseMarker)) {
    return BundledStateContent(stateContent: content);
  }

  final peopleMarkerIndex =
      _findSectionMarker(content, peopleMarker, courseMarker.length);
  if (peopleMarkerIndex == -1) {
    throw const FormatException(
        'Saved file is missing the PeopleFile section.');
  }

  final stateMarkerIndex = _findSectionMarker(
      content, stateMarker, peopleMarkerIndex + peopleMarker.length);
  if (stateMarkerIndex == -1) {
    throw const FormatException('Saved file is missing the state section.');
  }

  return BundledStateContent(
    courseData: content.substring(courseMarker.length, peopleMarkerIndex),
    peopleData: content.substring(
        peopleMarkerIndex + peopleMarker.length, stateMarkerIndex),
    stateContent: content.substring(stateMarkerIndex),
  );
}

String _ensureTrailingNewline(String content) {
  return content.endsWith('\n') ? content : '$content\n';
}

int _findSectionMarker(String content, String marker, int start) {
  final lineMarkerIndex = content.indexOf('\n$marker', start);
  if (lineMarkerIndex != -1) return lineMarkerIndex + 1;

  // Saves created before delimiters were normalized may have adjacent section
  // markers when the imported source file did not end with a newline.
  return content.indexOf(marker, start);
}
