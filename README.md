# Writer Plus

**Author:** `Adesh(Poz)`  
**Created:** `September 2026`

---

Writer Plus is a Flutter-based writing application for creating, editing, organizing, and exporting notes and documents locally. It is built for users who want a simple, distraction-free environment for writing while keeping documents structured and accessible across local storage.

_(Note: Inspiration (and personal need) for this specific project arises from an android app by the name of [WriterP](https://play.google.com/store/apps/details?id=co.easy4u.writer&hl=en-US), which stopped receiving updates a few years ago and has since become glitchy and dated (UI-wise). This project was intended as a replacement/improvement over that. As such, it was created with personal use in mind, rather than to create a project for everyone or which offers lots of useful features that other people might like. That said, if you want a simple and elegant writing tool, this is more than up for the task, I believe.)_

## Screenshots



<table>
  <tr>
    <th>Home Screen</th>
    <th>Editor — Keyboard Visible</th>
    <th>Editor — Keyboard Hidden</th>
  </tr>
  <tr>
    <td>
      <img src="screenshots/Writer Plus Home Page.jpeg" width="250">
    </td>
    <td>
      <img src="screenshots/Writer Plus Editor_with Keyboard Visible.jpeg" width="250">
    </td>
    <td>
      <img src="screenshots/Writer Plus Editor_without Keyboard Visible.jpeg" width="250">
    </td>
  </tr>
</table>

## Overview

The app combines markdown editing and rich text formatting in a single workflow. It supports local document management, nested folders, export to common file types, and file sharing outside the application. The feature set is designed around simple and practical writing tasks rather than a cloud-first document system or an AI-writing tool. If you want AI assistance in your writing, I suggest looking for other projects.

## Features

- Rich text editing with formatting controls for structured writing
- Markdown document support for lightweight, portable notes
- Plain text, Markdown, and rich text export options
- Local storage management with document and folder organization
- Nested subfolder support for keeping writing projects organized
- Document statistics including word count, character count, and reading speed estimates
- External sharing support for saving or sending files outside the app
- Cross-platform Flutter application setup for mobile and desktop targets

## Tech Stack

- `Flutter`
- `Dart`
- `flutter_quill` for rich text editing
- `markdown` and `markdown_quill` for markdown conversion
- `path_provider` and `file_picker` for local file access
- `share_plus` for external sharing
- `permission_handler` for platform permissions
- Material 3 UI design

## Project Structure

- `lib/main.dart`: application entry point and theme configuration
- `lib/routes.dart`: named route definitions
- `lib/screens/`: UI screens including the home view, editor, and app info screen
- `lib/services/`: file handling, export logic, and document storage services
- `lib/helpers/`: utility and support logic
- `lib/reusables/`: shared UI building blocks
- `test/`: project tests
- `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`: platform-specific project files

## Getting Started

### Prerequisites

- Flutter SDK installed and configured on your machine

_(Note: This project was built and tested with Flutter 3.44.9 and Dart 3.12.2, but it should be able to run on other Dart 3 SDKs and beyond, assuming they meet the dependency requirements. I focused on creating an up-to-date environment for this project, so most of the packages are on the latest available versions, or close to it, as of date.)_

- A supported platform target for the device or emulator you plan to run on

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Run analyzer checks

```bash
flutter analyze
```

### Run tests

```bash
flutter test
```

## Build Commands

### Android

```bash
flutter build apk
```

Or, if you want a smaller, more compact APK, run: 

```bash
flutter build apk --release --split-per-abi
```

Then, install the one that your system supports. :)

### iOS

```bash
flutter build ios
```

### Web

```bash
flutter build web
```

_(Note: Haven't tested it on either ios or web, so I can't guarantee it'll work on those platforms. It might. But it might not, haha. Although, I'm pretty sure it should work on iOS.)_

## Other Notes

Screenshots of the project can be found in `screenshots` folder. And a sample apk of this project is provided in the `apk` folder. It's a Universal (Fat) APK that can be installed on most Android devices. So, if you want to check the app itself, feel free to install it on your device. Keep it mind that it's about triple the size of a per-system APK(at ~60 MB, since it's a Universal APK) that you'd get from `flutter build apk --release --split-per-abi` (which creates abi-specific apks that are all sized ~20 MB).

Or, if you don't trust random APKs online (sensible of you), download the project, set it up and create your own APK of the project after perusing the code! :D

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

