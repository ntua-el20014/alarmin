# Alarmin

Alarms, calendar, timer, and stopwatch. Android app (`com.mobile.alarmin`).

## Releasing to Google Play

Once switched on, `.github/workflows/play-internal.yml` uploads every push to
`main` to the Internal testing track, with the version code set
automatically. Production releases are promoted in the Play Console. The
steps below are for manual builds.

1. Bump `version` in `pubspec.yaml`. The number after `+` is the Play
   version code and must go up with every upload (`1.0.1+2`, `1.0.2+3`, ...).
2. Build the bundle:

   ```
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```

3. Upload `build/app/outputs/bundle/release/app-release.aab` in the Play
   Console. Keep `build/symbols` for that version: it turns obfuscated crash
   stack traces back into readable ones (`flutter symbolize`).

### Signing key

Release builds are signed with the upload key in `android/upload-keystore.jks`,
whose passwords are in `android/key.properties`. Neither file may be shared
or published. **Back both up somewhere safe** (password manager, encrypted
drive): Play only accepts updates signed with this key, and replacing a lost
one means a support request to Google.

Without `key.properties`, release builds fall back to the debug key, which is
fine for local testing but rejected by Play.

## Development

```
flutter test
flutter analyze
dart run build_runner build   # after changing the drift database schema
```

The `alarm` plugin is vendored with local patches; see
`packages/alarm/ALARMIN_PATCHES.md`.
