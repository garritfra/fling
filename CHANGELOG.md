# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

xxx

## v0.10.0 (2025-03-12)

### Added

- Tag functionality for improved organization 
  - Add tags to lists ([0778444](https://github.com/garritfra/fling/commit/0778444))
  - Add tags to templates ([71212ab](https://github.com/garritfra/fling/commit/71212ab))

### Maintenance

- Bump firebase-admin from 12.2.0 to 13.1.0 in /functions
- Bump typescript from 5.5.2 to 5.7.3 in /functions
- Bump actions/checkout from 4.1.7 to 4.2.2
- Bump ruby/setup-ruby from 1.187.0 to 1.221.0
- Bump flutter_launcher_icons from 0.13.1 to 0.14.3
- Bump url_launcher from 6.3.0 to 6.3.1
- Bump kotlin_version from 1.9.24 to 2.0.21 in /android
- Bump eslint-plugin-import from 2.30.0 to 2.31.0 in /functions
- Bump webrick from 1.8.1 to 1.8.2 in /android
- Bump rexml from 3.2.8 to 3.3.9 in /android

## v0.9.0 (2024-07-20)

### Added

- Manage and apply templates to lists ([#255](https://github.com/garritfra/fling/pull/255))
- Keep text field active after adding a new item ([#256](https://github.com/garritfra/fling/pull/256))

## v0.8.5 (2024-07-16)

### Maintenance

- Bump dart SDK from 3.1.0 to 3.22.2

## v0.8.4 (2024-07-16)

### Maintenance

- Fix linter warnings
- Bump cloud_firestore from 4.13.6 to 4.15.8
- Bump cloud_functions from 4.5.8 to 4.6.8
- Bump cupertino_icons from 1.0.6 to 1.0.8
- Bump dynamic_color from 1.6.8 to 1.7.0
- Bump firebase_auth from 4.15.3 to 4.17.8
- Bump firebase_core from 2.24.2 to 2.25.4
- Bump firebase_crashlytics from 3.4.8 to 3.4.18
- Bump firebase_ui_auth from 1.11.0 to 1.14.0
- Bump provider from 6.1.1 to 6.1.2
- Bump url_launcher from 6.2.2 to 6.3.0

## v0.8.3 (2023-12-20)

### Added

- Web Deployment ([#119](https://github.com/garritfra/fling/pull/119))
- Display example input in user invite dialog ([#124](https://github.com/garritfra/fling/pull/124))

### Maintenance

- Minor architecture refactorings ([#126](https://github.com/garritfra/fling/pull/126))

## v0.8.2 (2023-12-16)

### Added

- Added an delete account button to the info menu ([#102](https://github.com/garritfra/fling/pull/102))

### Maintenance

- Fix linter warnings
- Bump dart SDK from 2.19.6 to 3.1.0
- Bump cloud_firestore from 4.5.2 to 4.13.6
- Bump cloud_functions from 4.1.1 to 4.5.8
- Bump cupertino_icons from 1.0.5 to 1.0.6
- Bump dart SDK version from 2.19.6 to 3.1.0
- Bump dynamic_color from 1.6.3 to 1.6.8
- Bump firebase-functions from 3.18.0 to 4.5.0 in /functions
- Bump firebase_auth from 4.4.2 to 4.15.3
- Bump firebase_core from 2.10.0 to 2.24.2
- Bump firebase_crashlytics from 3.1.1 to 3.4.8
- Bump firebase_ui_auth from 1.2.2 to 1.11.0
- Bump package_info_plus from 3.1.0 to 5.0.1
- Bump protobufjs and google-gax in /functions
- Bump provider from 6.0.5 to 6.1.1
- Bump semver from 7.3.8 to 7.5.3 in /functions
- Bump url_launcher from 6.1.10 to 6.2.2
- Bump word-wrap from 1.2.3 to 1.2.4 in /functions

## v0.8.1 (2023-04-19)

### Added

- Confirm if checked items should be deleted

### Maintenance

- Bump dart SDK from 2.18.5 to 2.19.6
- Bump cloud_firestore from 4.4.3 to 4.5.2
- Bump cloud_functions from 4.0.11 to 4.1.1
- Bump cupertino_icons from 1.0.2 to 1.0.5
- Bump dynamic_color from 1.5.4 to 1.6.3
- Bump firebase_auth from 4.2.6 to 4.4.2
- Bump firebase_core from 2.4.0 to 2.10.0
- Bump firebase_crashlytics from 3.0.15 to 3.1.1
- Bump firebase_ui_auth from 1.1.14 to 1.2.2
- Bump package_info_plus from 3.0.3 to 3.1.0
- Bump flutter_launcher_icons from 0.11.0 to 0.13.1

## v0.8.0 (2023-03-05)

### Added

- Links to changelog and issue tracker

### Changed

- Respect dynamic system color theme ([#62](https://github.com/garritfra/fling/pull/62))
- Improved onboarding experience

## v0.7.0 (2023-03-05)

### Added

- Ability to delete lists ([#58](https://github.com/garritfra/fling/pull/58))
- Ability to leave households ([#61](https://github.com/garritfra/fling/pull/61))

### Maintenance

- Bump cloud_functions from 4.0.8 to 4.4.3
- Bump firebase_auth from 4.2.5 to 4.2.6
- Bump firebase_crashlytics from 3.0.9 to 3.0.15
- Bump firebase_ui_auth from 1.1.7 to 1.1.14
- Bump package_info_plus from 3.0.2 to 3.0.3

## v0.6.3 (2023-01-03)

### Improvements

- Bump firebase_ui_auth from 1.1.6 to 1.1.7
- Bump firebase_auth from 4.2.4 to 4.2.5

## v0.6.2 (2023-01-03)

### Improvements

- Added `com.google.android.gms.permission.AD_ID` permission to android manifest
to prepare app for Android 13

## v0.6.1 (2023-01-01)

### Fixes

- Fixed app not starting if user is logged out
- Fixed household switcher for new accounts

## v0.6.0 (2022-12-31)

### Improvements

- Info and license dialog
- Ability to add lists to household
- Invite users to household

### Fixes

- Fixed crashes for newly created accounts

## v0.5.1 (2022-12-28)

### Improvements

- Ability to create and switch households

## v0.5.0 (2022-12-22)

### Improvements

- Localize texts
- Login after account creation
- Respect system theme preferences
- Switch to Material You design guidelines

## v0.4.1 (2022-12-12)

### Improvements

- Items in a list can now be edited ([92ad451](https://github.com/garritfra/fling/commit/92ad45193e7395b375b25c408a147d0c31f4ab9d))

## v0.4.0 (2022-12-12)

### Improvements

- Initial introduction of user management (still in development)
