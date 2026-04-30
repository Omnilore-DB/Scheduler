# Omnilore Scheduler

A course scheduler for Omnilore.

## Documentation

Developer documentation is available [here](https://andyliuhaowen.github.io/omnilore_documentation/).

## Deliverable 7 Handoff

The current web-migration handoff package lives in
[`Project_Docs_D7/README_QuickStart.md`](Project_Docs_D7/README_QuickStart.md).
It includes the setup/deploy guide, operations runbook, API and data reference,
testing summary, security notes, backlog, changelog, handoff checklist, and
stakeholder cover note.

## User Notes

- **Restarting the app:** on web, refresh the browser tab or close and reopen it; on desktop, close and reopen the app window.
- **Save** on web uses the browser's normal download behavior, so the file usually lands in the browser's default downloads folder.
- **Save As** on web uses the browser's save-file dialog when the browser supports it; otherwise it falls back to a normal download. Both Save and Save As produce a bundled file that includes your imported course data, people data, and scheduling state — so you can restore everything from that single file.
- **Load** accepts a bundled scheduler save file and restores the imported course file, people file, and scheduling state together. Use a file previously saved with Save or Save As.
- **Autosave** data is kept in the browser's local storage on web builds. It is not written out as a separate visible file unless you explicitly use Save or Save As. When you reopen or refresh the app, a dialog will offer to restore the last autosaved or manually saved session.

## Dev Environment Setup

You need to install Flutter to further develop this program. Flutter installation guide is available [here](https://docs.flutter.dev/get-started/install).
As for your IDE, one of IntelliJ IDEA, Android Studio, and VS Code is recommended. See guide [here](https://docs.flutter.dev/get-started/editor).
Verify your setup with:
```
flutter doctor
```
and address any issue it points out.

## Running and Testing

You should be able to run, debug, and unit-test the program with IDE features (some sort of run button, depending on your IDE of choice).

Should the need arise, run the program with:
```
flutter run -d <windows/macOS/linux>
```

Run unit tests with
```
flutter test
```

## Building Executables

Build executables with:
```
flutter build <windows/macOS/linux>
```

After succeeding, the executable is available under `build/<windows/macOS/linux>/x64/release/bundle`.
That folder includes all the necessary libraries and data files that the generated executable depends on.
Please distribute the entire folder.
