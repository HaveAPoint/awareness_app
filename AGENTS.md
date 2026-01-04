# Repository Guidelines

## Project Structure & Module Organization
This repository is a Flutter app with the main project under `frontend/`. Core Dart source lives in `frontend/lib/` (UI, data, and logic), tests live in `frontend/test/`, and web assets (icons, manifest) live in `frontend/web/`. Platform runners and build configs are in `frontend/android/`, `frontend/ios/`, `frontend/macos/`, `frontend/windows/`, and `frontend/linux/`. Root-level scripts `build_apk.sh` and `build_linux.sh` build release artifacts.

## Build, Test, and Development Commands
Run Flutter commands from `frontend/` unless noted.
- `flutter pub get` fetches Dart/Flutter dependencies.
- `flutter run` launches the app on the attached device or emulator.
- `flutter analyze` runs static analysis with repo lint rules.
- `flutter test` runs unit/widget tests.
- `./build_apk.sh` (repo root) builds a release Android APK.
- `./build_linux.sh` (repo root) builds a release Linux desktop bundle.
- For Linux dev, use `./build_linux.sh` when you need a clean rebuild, and `cd frontend && flutter run -d linux` for small, non-architectural updates.

## Coding Style & Naming Conventions
Follow standard Dart/Flutter formatting (2-space indentation via `dart format .`). Linting is configured in `frontend/analysis_options.yaml` and includes `flutter_lints`; keep code clean under `flutter analyze`. Use `snake_case` for filenames, `UpperCamelCase` for types/widgets, and `lowerCamelCase` for variables and methods.

## Testing Guidelines
Tests are under `frontend/test/` and follow the `*_test.dart` naming pattern. Prefer adding or updating tests alongside UI or logic changes and verify with `flutter test` before opening a PR.

## Commit & Pull Request Guidelines
Git history is mixed, but several commits use a `type: summary` style (e.g., `refactor: simplify task page`). Prefer that format with a short, imperative summary. PRs should include a brief description, testing performed (commands + results), and screenshots or short clips for UI changes. Link related issues if available.

## Docs & Specs
Project notes live in `frontend/ARCHITECTURE.md`, `frontend/MVP_SPEC.md`, and `frontend/DATAFLOW_VERIFICATION.md`. Update these when making structural or data-flow changes.
