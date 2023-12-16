# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## xxx

### Added

- Added an delete account button to the info menu ([#102](https://github.com/garritfra/fling/pull/102))

### Maintenance

- Bump cloud_firestore from 4.5.2 to 4.5.3
- Bump firebase_core from 2.10.0 to 2.11.0
- Bump firebase_crashlytics from 3.1.1 to 3.1.2
- Bump firebase_ui_auth from 1.2.2 to 1.2.4
- Bump package_info_plus from 3.1.0 to 3.1.2
- Bump protobufjs and google-gax in /functions
- Bump semver from 7.3.8 to 7.5.3 in /functions
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
