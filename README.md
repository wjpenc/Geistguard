# GeistGuard

An iPhone app for spotting harmful algal blooms on Geist Reservoir (Fishers, Indiana), built for the 2026 Congressional App Challenge.

- **Check:** take a photo of the water and an on-device AI model (MobileNetV3, TensorFlow Lite) sorts it into possible bloom, look-alike, clear water, or not water. Camera photos of water are added to the shared map with a small preview. Library photos are checked but never added.
- **Map:** community reports from the last 7 days, or 6 months of bloom reports as hotspots.
- **Upstream:** checks whether your location or any address drains to Geist (USGS watershed boundary) and gives runoff tips based on the National Weather Service forecast.
- **Stay safe:** save a spot to see possible blooms reported within 1 mile in the last 48 hours, plus safety info for dog owners, swimmers, boaters, and anyone who drinks Geist water.

GeistGuard gives a visual estimate only. It never says water is safe. Always check [IDEM's algae advisories](https://www.in.gov/idem/algae/) before contact with the water.

## Running it

GeistGuard has only been tested on iPhone, so these steps are for iOS.

### You need

- A Mac with [Xcode](https://developer.apple.com/xcode/) and CocoaPods
- [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or newer (Dart 3.13)
- An iPhone running iOS 15 or later, or the iOS Simulator
- A free Apple ID to sign the app for your own phone

### Steps

```
git clone https://github.com/wjpenc/geistguard.git
cd geistguard
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode, select **Runner**, open **Signing & Capabilities**, and choose your own Apple ID under **Team**. If Xcode says the bundle identifier is taken, change it to something unique (for example `com.yourname.geistguard`).

Then plug in your iPhone (or pick a simulator) and run:

```
flutter run
```

On a real iPhone you may need to trust the developer certificate first: **Settings > General > VPN & Device Management**.

### Good to know

- **The simulator has no camera.** Use the photo library button to check a photo instead. Drag an image onto the simulator window to add it to its library. Library photos are not added to the map.
- **Allow location access** when asked. It is used to pin reports and to check the watershed. Upstream also lets you type any address instead.
- **Reports go to a shared demo database** (Firebase, anonymous sign-in, no account needed). Anything you add will show up on everyone's map for 7 days.
- The weather, address, and map services are free public APIs, so an internet connection is needed for those parts. The AI check works offline.

## Tests

```
flutter analyze
flutter test
```

## Project layout

- `lib/` is the app code. `main.dart` holds startup and the Check tab. The other screens are `map_screen.dart`, `upstream_screen.dart`, `safety_screen.dart`, and `about_screen.dart`.
- `assets/` holds the TFLite model, its labels, the watershed boundary, the logo, and the DM Sans font.
- `test/` holds the wording safety checks and watershed boundary checks.

## Credits

The full list is on the app's About screen. Training photos: iNaturalist and Wikimedia Commons contributors (Creative Commons). Watershed boundary: USGS Watershed Boundary Dataset. Weather: National Weather Service. Addresses: Photon (OpenStreetMap) and the US Census Bureau Geocoder. Map: © OpenStreetMap contributors. Typeface: DM Sans (SIL Open Font License).
