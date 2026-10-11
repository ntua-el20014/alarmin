Put the app icon here as `icon.png` (square PNG, 1024x1024 recommended).

Then, from the `alarmin` folder:

    dart run flutter_launcher_icons
    flutter build apk --release --split-per-abi

The first command generates the Android launcher icons in
`android/app/src/main/res/`. Run it again whenever `icon.png` changes.
