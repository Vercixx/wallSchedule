# wallSchedule

Native iOS app that renders today's class schedule (from Моя Школа /
`authedu.mosreg.ru`) onto a wallpaper image, exposed to Shortcuts via an App
Intent so it can be set as Home/Lock Screen wallpaper.

No official public API exists for this backend. The app emulates the
official app's request headers and enforces a strict local rate limit
(1-2 automatic requests/day) to avoid triggering anti-automation detection.
See `project.yml` for the app target and `.github/workflows/build-ipa.yml`
for the build.

## Build

The unsigned `.ipa` is built on GitHub Actions using a macOS runner (Xcode
project itself is generated on CI via [XcodeGen](https://github.com/yonaskolb/XcodeGen)
from `project.yml`, not committed). Download the `wallSchedule-ipa` artifact
from the workflow run and sideload it with AltStore or SideStore, which
resign it locally using your free Apple ID at install time (re-signing
needed every 7 days unless you have a paid Apple Developer account).

## Setup

1. Intercept your own bearer token from the official Дневник.ру / Моя Школа
   app using mitmproxy or Charles.
2. Paste it into the app's login screen.
3. In Shortcuts, build an automation: "Run wallSchedule > Get Wallpaper" →
   "Set Wallpaper" (Home Screen and/or Lock Screen, no confirmation).

The app enforces a 1-2 automatic-fetch/day cap on its own regardless of how
often the automation runs, and serves the last cached schedule instead of
calling the network past that cap.

Known risk: on iOS 18.0-18.1 the "Set Wallpaper" action can intermittently
fail when run from an automation trigger (works fine run manually). If that
happens, fall back to: have the intent return the image, save it to Photos,
and set the wallpaper manually from there.

## Reverting to your normal wallpaper

Pure Shortcuts, no app involvement:

1. Save your normal wallpaper as an image in Photos once.
2. Build a second time-triggered automation (e.g. "At 5:00 PM") that runs
   "Set Wallpaper" with that saved image.
