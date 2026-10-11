# Etch

A minimalist habit tracker for iPhone (iOS 26+). Black, white and gray only: flat cards with a
faint sheen on their edges, floating on pure black. Tap a habit's circle to fill it with white, for
today or any earlier day; the Log shows each habit's last 26 weeks as a dot grid, and each habit's
page has a month calendar for editing its history. Home Screen widgets in small, medium and large
let you check in without opening the app. Free, unlimited habits, no accounts, no network.

English is the development language; Traditional Chinese (zh-Hant) is a full translation in
`Shared/Localizable.xcstrings`, shared by the app and the widgets.

## Build and test

Open `Etch.xcodeproj` in Xcode 26 or later and run the **Etch** scheme. Set your team under
Signing & Capabilities before running on a device, for both the **Etch** and **EtchWidgets**
targets. Both need the App Group `group.dev.noky.etch`: the habit store lives there so the widgets
can read it. On first launch the app copies a store from before the App Group into it.

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
| `Shared/` | Compiled into both the app and the widgets: `Day` and `Month` (local calendar days as `yyyyMMdd`, week and month layout), the SwiftData models, `Store` (the App Group store), the palette (`Graphite.swift` explains every color), `DotGrid`, `CheckDot` and the string catalog. |
| `Etch/Design/` | The rest of the design system: cards, button styles, the component catalog. |
| `Etch/Core/` | `Stats` (streaks, totals). Pure, tested. |
| `Etch/Views/` | The two tabs, the detail page and the editor sheet. |
| `EtchWidgets/` | The widget extension: a timeline of today's habits and an App Intent that checks in from the Home Screen. |
| `EtchTests/` | Unit tests (Swift Testing). |
| `EtchUITests/` | End-to-end flows with screenshots attached to the results. |

## Debug launch arguments

Debug builds only; none of this ships. Add them in the scheme's Run → Arguments, or pass them to
`xcrun simctl launch`.

| Argument | Effect |
|---|---|
| `-EtchInMemory` | Throwaway empty store |
| `-EtchSeed 20` | Add 20 habits with up to a year of history (empty store only) |
| `-EtchCatalog` | Show every design component side by side |
| `-EtchTab log` | Start on the Log tab |
| `-EtchOpenFirst` | With `-EtchTab log`, open the first habit's detail page |
| `-EtchRenderIcon` | With `-EtchCatalog`, render `AppIcon.png` into the app's Documents folder |

The app icon is drawn in `AppIconArt` (`Etch/Design/GraphiteCatalog.swift`). To regenerate it:

```sh
xcrun simctl launch booted dev.noky.etch -EtchCatalog -EtchRenderIcon
cp "$(xcrun simctl get_app_container booted dev.noky.etch data)/Documents/AppIcon.png" \
   Etch/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```
