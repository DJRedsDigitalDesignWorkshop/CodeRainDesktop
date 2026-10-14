# CodeRainDesktop 1.0.0
By djred. Native animated macOS desktop wallpaper based on CodeRainSaver 1.1.21 (b05a1b8). The original project remains untouched.

[Download CodeRainDesktop 1.0.0](https://github.com/DJRedsDigitalDesignWorkshop/CodeRainDesktop/releases/tag/v1.0.0). The public DMG is Developer ID signed, Apple notarized, and stapled.

Install: open the DMG, drag CodeRainDesktop to Applications, then open it. The 雨 menu controls appearance, pause, 30/60 fps, and optional launch at login. Quit restores the existing wallpaper immediately. Desktop icons remain clickable. Requires macOS 13+ on Apple Silicon.

Uses the original cached glyph sprites and column strips, Core Animation composition, one shared timer, no browser/video decoder, and no screen recording permission. Default 30 fps; sleep and lock stop callbacks. Preferences are isolated from the screen saver. Full-screen app coverage does not currently suspend rendering. Energy use depends on display count and resolution; measure on target hardware before assuming a CPU budget.

Build: `zsh Scripts/build.sh`. Default builds are ad-hoc signed for local testing; set SIGNING_IDENTITY for Developer ID signing. Notarization requires a configured Apple notary profile.
