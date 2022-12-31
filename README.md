# fling

A shopping list app.

Fling = FLutter Bring.

## Building

To compile this project, you have to do the following:

1. Create a firebase project
2. Follow instructions on how to set up an application
3. Copy google services in corresponding directory
    * **Android**: Copy google-services.json into `android/app/google-services.json`
    * **iOS**: TODO
4. Run the app via `flutter run`

## Release Workflow

1. Update version info in `pubspec.yaml`
2. Update changelog
3. Commit with name of version
4. `git tag -a <new tag> -m "$(git shortlog <previous tag>..HEAD)"`
5. `git push --tags`