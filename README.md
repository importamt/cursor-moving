# CursorMoving

A tiny macOS menu bar app that moves the cursor while you're away. When you stop using the keyboard and mouse for a while, it smoothly draws a shape with the cursor and puts it back where it was.

[한국어](README.ko.md)

## Features

- **Idle detection**: starts only after no keyboard/mouse input for 5 sec, 10 sec, 15 sec, 30 sec (default), 1 min or 5 min
- **Shapes**: zigzag, circle, square or star, drawn smoothly over about 2 seconds
- **Stays out of your way**: stops immediately when you move the mouse or press a key, and returns the cursor to where it started
- **Global shortcut**: `⌃⌥⌘M` toggles it on/off (customizable)
- **Settings**: launch at login, start moving on launch, English / 한국어, shortcut
- No network access, no data collection

## Installation

1. Download the latest `CursorMoving-x.y.z.zip` from [**Releases**](https://github.com/importamt/cursor-moving/releases/latest).
2. Unzip it and move `CursorMoving.app` to your `Applications` folder.
3. Open `CursorMoving.app`. A cursor icon appears in the menu bar (there is no Dock icon).
4. Grant **Accessibility** access when prompted:
   **System Settings → Privacy & Security → Accessibility → CursorMoving** on.
   macOS needs this permission for any app that moves the cursor.

The app is signed with a Developer ID and notarized by Apple, so it opens without Gatekeeper warnings.

**Requirements**: macOS 13 Ventura or later (Apple silicon and Intel)

## Usage

Click the menu bar icon:

| Menu | Description |
|------|-------------|
| Start Moving / Stop Moving | Turn it on or off (`⌃⌥⌘M`) |
| Idle Time | How long to wait without input before drawing |
| Shape | Zigzag / Circle / Square / Star |
| Settings… | Open settings (`⌘,`) |

The icon turns green while it is on.

### Settings

- **General**: Launch at login, Start moving when app launches
- **Language**: English (default) / 한국어
- **Shortcut**: click **Change…**, press the new key combination (e.g. `⌘⌥O`) and click **OK**.
  It must include `⌘`, `⌥` or `⌃`. Combinations already used by another app are rejected.

## Uninstall

1. Quit CursorMoving from its menu.
2. Delete `CursorMoving.app` from `Applications`.
3. Remove CursorMoving from **System Settings → Privacy & Security → Accessibility** (and **General → Login Items** if enabled).
4. Optionally remove its preferences: `defaults delete com.imbotaem.cursormoving`

## License

[MIT](LICENSE)
