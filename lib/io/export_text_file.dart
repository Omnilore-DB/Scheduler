typedef SaveAsTextFile = Future<void> Function(
  String content,
  String suggestedName,
);
typedef DownloadTextFile = void Function(String content, String filename);
typedef PickSavePath = Future<String?> Function();
typedef WriteTextFile = void Function(String path, String content);

Future<void> exportTextFile({
  required bool isWeb,
  required String content,
  required String suggestedName,
  required SaveAsTextFile saveAs,
  required DownloadTextFile download,
  required PickSavePath pickSavePath,
  required WriteTextFile writeToPath,
  bool allowCustomNameOnWeb = false,
}) async {
  if (isWeb) {
    if (allowCustomNameOnWeb) {
      await saveAs(content, suggestedName);
    } else {
      download(content, suggestedName);
    }
    return;
  }

  final path = await pickSavePath();
  if (path != null && path.isNotEmpty) {
    writeToPath(path, content);
  }
}
