# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## v0.11.0 (2026-05-05)

### Added

- Phase 1 Slice 1 — `GET /v1/me` and `PATCH /v1/me` end-to-end ([#543](https://github.com/garritfra/fling/pull/543)):
  - Backend: `RequestContext`, structured logger, `AppError` hierarchy + Hono error handler, `requestId` middleware, Firebase ID-token auth middleware, and a `me` feature slice (`schemas`, `repo`, `service`, `routes`, `events`); `/v1/openapi.json` served unauthenticated
  - Flutter: Riverpod-based `features/me` read path; `ProviderScope` bootstrap
  - Tooling: `CONTRIBUTING.md` with local dev / emulator / API testing / migrations workflow; backend tests now run under the Firebase emulator in CI; hosting emulator moved to port 5050 (5000 conflicts with AirPlay)

### Reverted

- Revert tab layout for lists ([#511](https://github.com/garritfra/fling/pull/511))

### Infrastructure

Phase 0 of the rewrite — foundation work, no user-facing changes ([#540](https://github.com/garritfra/fling/pull/540)):

- **Backend (Hono API):** empty v1 API behind `/v1/healthz` with OpenAPI spec; `openapi:generate` script and committed baseline; idempotent migration runner with `000-initial` baseline
- **Flutter:** added `riverpod`, `freezed`, `go_router`, `connectivity`, `shared_preferences` deps and scaffold; generated `dart-dio` client from OpenAPI
- **Slice scaffolding:** `core/` and `features/` directories under `functions/`
- **Lint / boundaries:** backend boundary rules (no cross-feature, no core→feature); inner-feature boundary rules now actually fire; grep-based Flutter import-boundary check (CI-portable)
- **Rules / Firestore:** baseline `firestore.rules` mirroring current behaviour; Phase-0 carve-out documented and tested; Vitest rules tests against the emulator
- **CI / ops:** unified `ci.yml` (backend, flutter, contracts, deploy); tolerate pre-existing info-level analyzer findings; `scripts/snapshot-prod.sh` for pre-merge rollback snapshots, preserving all 5 live composite indexes via REST API; `scripts/dev.sh` for the Firebase emulator suite
- **Toolchain:** Node 20, TypeScript 5, normalised ESLint config in `functions/`
- **Docs:** rewrite design spec, migration status tracker, Phase 0 plan (closed — prod deploy + smoke verified)

### Maintenance

- Change Dependabot update schedule to monthly
- Bump `firebase-admin` from 13.5.0 to 13.7.0 in /functions ([#444](https://github.com/garritfra/fling/pull/444), [#485](https://github.com/garritfra/fling/pull/485), [#498](https://github.com/garritfra/fling/pull/498))
- Bump `fast-xml-parser` from 5.3.4 to 5.7.1 in /functions ([#492](https://github.com/garritfra/fling/pull/492), [#496](https://github.com/garritfra/fling/pull/496), [#507](https://github.com/garritfra/fling/pull/507), [#509](https://github.com/garritfra/fling/pull/509), [#538](https://github.com/garritfra/fling/pull/538))
- Bump `protobufjs` from 7.4.0 to 7.5.5 in /functions ([#537](https://github.com/garritfra/fling/pull/537))
- Bump `lodash` from 4.17.21 to 4.18.1 in /functions ([#476](https://github.com/garritfra/fling/pull/476), [#533](https://github.com/garritfra/fling/pull/533))
- Bump `node-forge` from 1.3.1 to 1.4.0 in /functions ([#452](https://github.com/garritfra/fling/pull/452), [#520](https://github.com/garritfra/fling/pull/520))
- Bump `js-yaml` from 3.14.1 to 3.14.2 in /functions ([#447](https://github.com/garritfra/fling/pull/447))
- Bump `path-to-regexp` from 0.1.12 to 0.1.13 in /functions ([#526](https://github.com/garritfra/fling/pull/526))
- Bump `picomatch` from 2.3.1 to 2.3.2 in /functions ([#519](https://github.com/garritfra/fling/pull/519))
- Bump `flatted` from 3.2.7 to 3.4.2 in /functions ([#508](https://github.com/garritfra/fling/pull/508))
- Bump `brace-expansion` in /functions ([#528](https://github.com/garritfra/fling/pull/528))
- Bump `minimatch`, `qs`, `express`, `jws`, `@google-cloud/storage` in /functions ([#454](https://github.com/garritfra/fling/pull/454), [#468](https://github.com/garritfra/fling/pull/468), [#484](https://github.com/garritfra/fling/pull/484), [#495](https://github.com/garritfra/fling/pull/495))
- Bump `typescript` from 5.9.3 to 6.0.2 in /functions ([#521](https://github.com/garritfra/fling/pull/521))
- Bump `@typescript-eslint/eslint-plugin` and `@typescript-eslint/parser` in /functions ([#504](https://github.com/garritfra/fling/pull/504), [#505](https://github.com/garritfra/fling/pull/505), [#515](https://github.com/garritfra/fling/pull/515), [#524](https://github.com/garritfra/fling/pull/524), [#530](https://github.com/garritfra/fling/pull/530), [#535](https://github.com/garritfra/fling/pull/535), [#536](https://github.com/garritfra/fling/pull/536))
- Bump `cupertino_icons` from 1.0.8 to 1.0.9 ([#525](https://github.com/garritfra/fling/pull/525))
- Bump `org.jetbrains.kotlin.android` in /android ([#465](https://github.com/garritfra/fling/pull/465), [#488](https://github.com/garritfra/fling/pull/488), [#516](https://github.com/garritfra/fling/pull/516), [#552](https://github.com/garritfra/fling/pull/552))
- Bump `gradle-wrapper` from 9.1.0 to 9.4.1 in /android ([#483](https://github.com/garritfra/fling/pull/483), [#502](https://github.com/garritfra/fling/pull/502), [#517](https://github.com/garritfra/fling/pull/517))
- Bump `aws-sdk-s3` from 1.141.0 to 1.208.0 in /android ([#462](https://github.com/garritfra/fling/pull/462))
- Bump `faraday` from 1.10.3 to 1.10.5 in /android ([#489](https://github.com/garritfra/fling/pull/489))
- Bump `actions/upload-artifact` from 4 to 7 ([#442](https://github.com/garritfra/fling/pull/442), [#459](https://github.com/garritfra/fling/pull/459), [#499](https://github.com/garritfra/fling/pull/499))
- Bump `actions/checkout` from 5.0.0 to 6.0.2 ([#456](https://github.com/garritfra/fling/pull/456), [#480](https://github.com/garritfra/fling/pull/480))
- Bump `actions/setup-node` from 4 to 6 ([#547](https://github.com/garritfra/fling/pull/547))
- Bump `ruby/setup-ruby` from 1.266.0 to 1.306.0 ([#443](https://github.com/garritfra/fling/pull/443), [#450](https://github.com/garritfra/fling/pull/450), [#457](https://github.com/garritfra/fling/pull/457), [#461](https://github.com/garritfra/fling/pull/461), [#470](https://github.com/garritfra/fling/pull/470), [#474](https://github.com/garritfra/fling/pull/474), [#478](https://github.com/garritfra/fling/pull/478), [#482](https://github.com/garritfra/fling/pull/482), [#487](https://github.com/garritfra/fling/pull/487), [#501](https://github.com/garritfra/fling/pull/501), [#506](https://github.com/garritfra/fling/pull/506), [#514](https://github.com/garritfra/fling/pull/514), [#522](https://github.com/garritfra/fling/pull/522), [#534](https://github.com/garritfra/fling/pull/534), [#548](https://github.com/garritfra/fling/pull/548))

## v0.10.2 (2025-10-31)

### Fixed

- Fix text input field being obscured by navigation bar on Android
- Fix Firebase Functions build by updating import to use v1 API compatibility layer

## v0.10.1 (2025-10-22)

### Fixed

- Sort templates by name ([#429](https://github.com/garritfra/fling/pull/429))

### Maintenance

- Update flutter and gradle versions ([#428](https://github.com/garritfra/fling/pull/428))
- Bump typescript from 5.8.3 to 5.9.3 in /functions ([#426](https://github.com/garritfra/fling/pull/426))
- Bump ruby/setup-ruby from 1.247.0 to 1.265.0 ([#427](https://github.com/garritfra/fling/pull/427), [#425](https://github.com/garritfra/fling/pull/425), [#424](https://github.com/garritfra/fling/pull/424), [#417](https://github.com/garritfra/fling/pull/417))
- Bump rexml from 3.3.9 to 3.4.2 in /android ([#423](https://github.com/garritfra/fling/pull/423))
- Bump actions/setup-java from 4 to 5 ([#414](https://github.com/garritfra/fling/pull/414))
- Bump actions/checkout from 4.2.2 to 5.0.0 ([#410](https://github.com/garritfra/fling/pull/410))
- Bump form-data to 2.5.5 in /functions ([#400](https://github.com/garritfra/fling/pull/400))

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
