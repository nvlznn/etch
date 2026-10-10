# Etch

A minimalist habit tracker for iPhone (iOS 26+). Black, white and gray only; every surface is graphite,
raised or pressed in; finishing a habit fills its dimple with white, and the Log
shows each habit as a dot-grid plate. Free, unlimited habits,
no accounts, no network.

English is the development language; Traditional Chinese (zh-Hant) is a full translation in
`Etch/Localizable.xcstrings`.

## Build and test

Open `Etch.xcodeproj` in Xcode 26 or later and run the **Etch** scheme. Set your team under
Signing & Capabilities before running on a device.

```sh
# Unit tests (Day, Stats) and UI tests (all flows), on any iOS 26+ simulator
xcodebuild -project Etch.xcodeproj -scheme Etch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

`EtchUITests/testLogScrollPerformance` measures scrolling 20 habits × a year of history. The
simulator doesn't report hitch rates, so run it on a device for meaningful numbers.

## Layout

| Folder | |
|---|---|
| `Etch/Design/` | The graphite design system. The only place colors and shadows are defined. `Graphite.swift` explains the light source and every color. |
| `Etch/Core/` | `Day` (local calendar days as `yyyyMMdd`, week layout) and `Stats` (streaks, totals). Pure, tested. |
| `Etch/Models/` | SwiftData models, stored on the device only. |
| `Etch/Views/` | The two tabs, the detail page and the editor sheet. |
| `EtchTests/` | Unit tests (Swift Testing). |
| `EtchUITests/` | End-to-end flows with screenshots attached to the results. |

## Debug launch arguments

Debug builds only; none of this ships. Add them in the scheme's Run → Arguments, or pass them to
`xcrun simctl launch`.

| Argument | Effect |
|---|---|
| `-EtchInMemory` | Throwaway empty store |
| `-EtchSeed 20` | Add 20 habits with up to a year of history (empty store only) |
| `-EtchCatalog` | Show every design component side by side, to check the light direction |
| `-EtchTab log` | Start on the Log tab |
| `-EtchOpenFirst` | With `-EtchTab log`, open the first habit's detail page |
| `-EtchRenderIcon` | With `-EtchCatalog`, render `AppIcon.png` into the app's Documents folder |

The app icon is drawn with the app's own `Dimple`. To regenerate it:

```sh
xcrun simctl launch booted com.noky.etch -EtchCatalog -EtchRenderIcon
cp "$(xcrun simctl get_app_container booted com.noky.etch data)/Documents/AppIcon.png" \
   Etch/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```
