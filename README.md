# PDF DREAMER

A cross-platform document workspace built with Flutter. Read, review, sign, and convert PDF and Markdown files — all in one place.

<p align="center">
  <img src="assets/img/PDF-DREAMER-LOGO.png" alt="PDF DREAMER logo" width="128" />
</p>

---

## Features

- **PDF viewer** — high-fidelity rendering with zoom, scroll, and page navigation via [pdfrx](https://pub.dev/packages/pdfrx)
- **Markdown viewer** — rich rendering with zoom support via [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus)
- **Image viewer** — open PNG, JPG, JPEG, and WebP files
- **Draw signatures** — freehand brush tool with configurable color and width
- **Image stamps** — upload signature images or watermarks, move, resize, and pin them
- **Undo / Redo** — full history for all edits
- **Save & Export** — persist annotations and convert between PDF and Markdown
- **PDF tools** — add watermarks, split and merge PDFs, and delete selected pages
- **Windows integration** — install for the current user and open PDF and Markdown files from Explorer
- **Linux integration** — distribute a `.tar.gz` bundle with a user installer and PDF/Markdown default associations
- **Multi-language** — Spanish, Portuguese, and English
- **Dark & Light themes** — respects system preference by default, manually selectable
- **Accent color** — choose a preset or enter a custom HEX color in Settings
- **Responsive** — works on Windows, macOS, Linux, Android, iOS, and Web

---

## Platforms

| Platform | Project configuration and validation |
|----------|--------|
| Windows  | Release x64 build and installer compilation verified on Windows 10; installation and shell checks pending |
| macOS    | Project target included; not validated in the current Windows environment |
| Linux    | Archive builder and user installer prepared; isolated packaging tests pass; native build and desktop checks pending |
| Android  | Project target included; not validated in the current Windows environment |
| iOS      | Project target included; not validated in the current Windows environment |
| Web      | Project target included; not validated in the current Windows environment |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart >= 3.8.1 (tested: Flutter 3.32.1)
- A supported platform toolchain (Android Studio, Xcode, Visual Studio, or GTK)
- For Markdown-to-PDF export on desktop: Microsoft Edge, Google Chrome, or Chromium. The intermediate HTML and browser profile are deleted after conversion.

### Setup

```bash
git clone https://github.com/mirazolabs/pdf_dreamer.git
cd pdf_dreamer
flutter pub get
```

### Run

```bash
# Desktop (default host platform)
flutter run

# Specific platform
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome
```

### Build

```bash
flutter build windows
flutter build macos
flutter build linux
flutter build apk
flutter build web
```

---

## Architecture

The project follows a **feature-first, layered architecture**:

```
lib/
├── main.dart                     # Entry point, platform init
├── app/
│   └── pdf_dreamer_app.dart      # Composition root (providers, theme, i18n)
├── core/
│   ├── theme/
│   │   └── app_theme.dart        # Light + dark theme definitions
│   └── localization/
│       └── app_localizations.dart # JSON-based i18n delegate
└── features/
    ├── document/
    │   ├── data/services/        # File picker, export services
    │   ├── domain/entities/      # Pure Dart models
    │   └── presentation/
    │       ├── controllers/      # ChangeNotifier (state management)
    │       ├── pages/            # Full-screen pages
    │       └── widgets/          # Reusable UI components
    └── settings/
        └── presentation/
            ├── controllers/      # Theme & locale state
            └── widgets/          # Settings panel
```

### State Management

[Provider](https://pub.dev/packages/provider) + **ChangeNotifier**. Two controllers manage all app state:

| Controller | Responsibilities |
|------------|-----------------|
| `DocumentController` | Document lifecycle, tools, brush strokes, image stamps, zoom, undo/redo, save/export |
| `SettingsController` | Locale, theme mode, and accent color (persisted via SharedPreferences) |

### Localization

Translations are stored as static JSON files under `assets/i18n/`. The `AppLocalizations` delegate loads the selected language at runtime and falls back to the English file if loading that language fails. Missing translation keys are displayed as their key names. Currently supported:

- `es` — Spanish
- `pt` — Portuguese
- `en` — English

To add a new language, create a `xx.json` file under `assets/i18n/`, copy the keys from an existing file, translate the values, and register the locale in `pdf_dreamer_app.dart` and `_AppLocalizationsDelegate`.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [provider](https://pub.dev/packages/provider) | State management |
| [pdfrx](https://pub.dev/packages/pdfrx) | PDF rendering |
| [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) | Markdown rendering |
| [file_picker](https://pub.dev/packages/file_picker) | File system dialogs |
| [pdf](https://pub.dev/packages/pdf) | PDF generation (markdown-to-PDF) |
| [window_manager](https://pub.dev/packages/window_manager) | Desktop window controls |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Persist user settings |
| [path](https://pub.dev/packages/path) | Path utilities |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Open document |
| `Ctrl+S` | Save changes |
| `Ctrl+Shift+C` | Convert PDF ↔ Markdown |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |
| `F5` / `Ctrl+Meta+F` | Toggle fullscreen |

---

## Windows installer and default apps

### Requirements

Build on Windows x64 with:

- Flutter with Dart 3.8.1 or newer; the Windows build was verified with Flutter 3.32.1 and Dart 3.8.1.
- Visual Studio 2022 with the **Desktop development with C++** workload and a Windows SDK.
- Inno Setup 6.3 or newer; installer compilation was verified with Inno Setup 6.7.3.

The installer targets Windows 10/11 x64. Windows 32-bit is not supported. Other
platform targets do not use this installer.

### Build the installer

Run from the repository root:

```powershell
flutter pub get
.\scripts\build_windows_installer.ps1

# Reuse an existing Windows Release build:
.\scripts\build_windows_installer.ps1 -SkipBuild

# Use a different Release directory:
.\scripts\build_windows_installer.ps1 -SkipBuild -BuildDir "C:\path\to\Release"

# Specify the compiler if it is not found automatically:
.\scripts\build_windows_installer.ps1 -SkipBuild -IsccPath "C:\path\to\ISCC.exe"
```

Without `-SkipBuild`, the script runs `flutter build windows --release`. By
default, it packages `build/windows/x64/runner/Release`. The complete Release
directory is required, including its DLLs and `data` folder.

The script locates the Visual C++ runtime through the Visual Studio installation.
Use `-RedistDir "C:\path\to\Microsoft.VC143.CRT"` to supply an x64 runtime directory
explicitly. Packaging fails if required runtime DLLs are missing.

Output: `build/installer/pdf_dreamer-<version>-windows-x64-setup.exe`. For version
`1.0.0+1`, the filename is `pdf_dreamer-1.0.0+1-windows-x64-setup.exe`.

Installer sources:

| File | Purpose |
|------|---------|
| `scripts/build_windows_installer.ps1` | Build or reuse Release, locate runtime DLLs, read application metadata, and invoke ISCC |
| `installer/windows/pdf_dreamer.iss` | Define installation, shortcuts, file associations, and uninstall behavior |
| `build/installer/build-config.iss` | Generated paths and metadata; excluded from Git with the rest of `build/` |

Run the PowerShell script once before compiling `pdf_dreamer.iss` in the Inno
Setup editor. It generates `build-config.iss`, including `BuildDir`; no manual
definition is needed in the editor. Regenerate this configuration after moving
the repository or changing the build directory or version.

### Install and choose defaults

Run the generated setup executable on the destination PC. It installs for the
current user in `%LOCALAPPDATA%\Programs\pdf_dreamer` without requiring
administrator privileges. The bundle includes Flutter, plugins, assets, and local
Visual C++ runtime DLLs; the destination PC does not need Flutter or Visual Studio.

Installation registers PDF Dreamer for `.pdf` and `.md` in **Open with** and
**Settings > Apps > Default apps**. On the final installer page, leave the option
to open Windows Settings selected, find PDF Dreamer, and choose it for both file
types. You can also use **Open with > Choose another app** from Explorer.

Windows requires the user to confirm default applications. Installation and
upgrades preserve existing defaults and do not modify `UserChoice`. The portable
Release bundle does not register associations when launched.

### File associations and launch behavior

| Extension | ProgID | MIME type |
|-----------|--------|-----------|
| `.pdf` | `pdf_dreamer.PDF` | `application/pdf` |
| `.md` | `pdf_dreamer.Markdown` | `text/markdown` |

The installer registers the ProgIDs and `OpenWithProgids` values under
`HKCU\Software\Classes`. It also registers
`HKCU\Software\Mirazo Labs\pdf_dreamer\Capabilities\FileAssociations` and
`HKCU\Software\RegisteredApplications` so Windows can enumerate the app.
The opening command quotes both the executable and document path:

```text
"<installation directory>\pdf_dreamer.exe" "%1"
```

Files passed by Explorer open after the workspace is ready. Each launch opens a
separate window. If a process receives several paths, it opens the first and
reports that the remaining files were skipped when the first opens successfully.
If the first path fails, the app displays an error without opening another path
implicitly. Paths retain spaces and Unicode characters; extensions are matched
without case sensitivity. Markdown is decoded as UTF-8 and rendered by the
existing Markdown viewer. Invalid or unreadable files display an error.

Upgrades use the same installer AppId, `pdf_dreamer`. Uninstall through Windows
Settings to remove the installed files and the application\'s registration entries.
The installer currently produces an unsigned executable.

### Validation

The following checks passed in the Windows development environment:

- `flutter analyze` with no issues.
- `flutter test` with all 11 tests passing, including launch-path and file-error tests.
- `flutter build windows --release`.
- Installer compilation with Inno Setup 6.7.3 using `-SkipBuild`.

The Flutter checks used dependencies resolved for the installed SDK. The original
repository lockfile was preserved; it was generated with a newer Dart SDK.

Before distributing a release, validate these steps on a clean Windows PC or VM:

1. Install with existing PDF and Markdown defaults and confirm they remain unchanged.
2. Confirm PDF Dreamer appears in **Open with** and **Default apps** for both extensions.
3. Choose PDF Dreamer manually and open a PDF and a UTF-8 Markdown file from Explorer.
4. Repeat with paths containing spaces, accents, and other Unicode characters.
5. Open another file while the app is running and confirm it opens in a separate window.
6. Test multiple arguments, missing files, unsupported formats, malformed UTF-8, and corrupt PDFs.
7. Upgrade and confirm the installation and user preferences are preserved.
8. Uninstall and confirm the application\'s entries are removed without affecting other apps.
9. Confirm the installed app works without Flutter, Visual Studio, or a separately installed Visual C++ runtime.

Installer compilation has been verified; these installation and shell checks are
still pending.

---

## Linux archive and installation

### Build on Linux

Use a Linux x64 machine with Flutter and the Linux desktop toolchain. Ubuntu 22.04
is the configured CI build environment. For Ubuntu/Debian, the build dependencies
include:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter config --enable-linux-desktop
flutter pub get
bash scripts/build_linux_archive.sh
```

The script runs `flutter build linux --release`, then packages the **complete**
`build/linux/x64/release/bundle` directory. It reads the package name and version
from `pubspec.yaml`, and the application ID from `linux/CMakeLists.txt`.

Output for the current version:

```text
build/installer/pdf_dreamer-1.0.0+1-linux-x64.tar.gz
```

To package an existing Linux build without recompiling:

```bash
bash scripts/build_linux_archive.sh --skip-build
# Or provide a bundle from another build directory:
bash scripts/build_linux_archive.sh --skip-build --bundle-dir /path/to/bundle --output-dir /path/to/output
```

The ELF header determines whether the archive is labelled `x64` or `arm64`.
Windows binaries and incomplete bundles are rejected. ARM64 packaging is supported
for an existing matching Linux bundle; the supplied CI job builds x64 only.
Build on the oldest Linux/glibc version you intend to support and validate each
target distribution. A `.tar.gz` bundle is not a universal binary for every Linux
distribution. See the [Flutter Linux build guide](https://docs.flutter.dev/platform-integration/linux/building).

### Build from GitHub Actions

After committing and pushing the workflow, open **Actions > Linux package > Run
workflow**. The manual workflow in `.github/workflows/linux-package.yml` installs
the Linux toolchain and Flutter 3.32.1 on Ubuntu 22.04, runs analysis and tests,
builds the application, and uploads the archive as `pdf-dreamer-linux-x64`.
Download that artifact and extract the contained `.tar.gz`.

The workflow is prepared but has not been run from the current Windows environment.
It does not publish a GitHub Release or run automatically on every push.

### Install and configure default readers

On the destination Linux desktop, extract the archive and run the installer as
your normal user, without `sudo`:

```bash
tar -xzf pdf_dreamer-1.0.0+1-linux-x64.tar.gz
cd pdf_dreamer-1.0.0+1-linux-x64
bash install.sh
```

The installer requires `xdg-utils`, `shared-mime-info`, and `desktop-file-utils`.
On Ubuntu/Debian, install these integration tools with:

```bash
sudo apt-get install -y xdg-utils shared-mime-info desktop-file-utils
```

The target also needs compatible system runtime libraries, including GTK 3. The
archive contains the Flutter engine, plugins and assets, so Flutter and development
tools are not required on the destination PC. Check `ldd bundle/pdf_dreamer` and
the libraries in `bundle/lib/` if runtime dependencies are missing.

By default, `install.sh` installs the app and requests PDF Dreamer as the default
for `application/pdf`, `text/markdown`, and the `text/x-markdown` alias. It verifies
each association with `xdg-mime query default` and reports failure if the desktop
does not accept a change. Run inside your graphical desktop session; desktop
policies can require an additional manual selection. It never assigns the general
`text/plain` type to PDF Dreamer. To preserve existing defaults:

```bash
bash install.sh --no-defaults
```

Files are installed under `${XDG_DATA_HOME:-$HOME/.local/share}/pdf_dreamer`.
The installer creates `applications/io.mirazolabs.pdf_dreamer.desktop`, copies the
app icon, registers Markdown MIME metadata, and refreshes the desktop/MIME caches.
The desktop entry uses a quoted absolute executable path and `%f` to deliver a
single local filename to the existing viewer, including spaces and Unicode.
Each launch creates a separate window, as configured in the Linux GTK runner.

Repeated installation creates a new release directory and updates the `current`
symlink. Older releases remain available to running windows. Use `--no-defaults`
when upgrading if you want to retain any default-reader changes made since the
previous installation. The archive includes [installation and removal instructions](installer/linux/README.md),
`install.sh`, `package.conf`, the MIME definition, app icon, and MIT license.

### Linux validation

Run the isolated packaging tests with:

```bash
bash test/linux_packaging_test.sh
```

These tests use a **non-runnable ELF fixture** and simulated XDG commands to check
archive contents, quoting, upgrades, default selection, `--no-defaults`, policy
failures, and architecture checks. They passed under Git Bash on Windows; this
does not validate a native Linux build or real desktop associations.

Before distributing, build on Linux and verify installation on a clean target
desktop, PDF/Markdown launch from the file manager, paths with accents and spaces,
opening a second window, missing runtime libraries, and default selection in
GNOME/KDE. Confirm `--no-defaults` preserves the existing readers. These native
build and desktop checks remain pending.

---

## Custom App Icon

The app icon is embedded via `windows/runner/resources/app_icon.ico`. To replace it:

1. Generate a `.ico` file containing sizes 16, 32, 48, 64, 128, and 256 px from your source image
2. Overwrite `windows/runner/resources/app_icon.ico`
3. Rebuild: `flutter build windows`

On Linux, replace the icon assets under `linux/`. On macOS, replace the `.icns` in `macos/Runner/Assets.xcassets`.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## About

Developed by [Mirazo Labs](https://mirazolabs.io) — building tools that empower creators.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/mirazolabs/pdf_dreamer).

### Development

```bash
# Run analyzer
flutter analyze

# Run tests
flutter test
```
