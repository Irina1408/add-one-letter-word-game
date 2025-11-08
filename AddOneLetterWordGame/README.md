# Add-one-letter Word Game

A production-ready iOS 16+ SwiftUI implementation of the Balda-style "add one letter" word game featuring offline dictionary validation, AI opponents, pass-and-play mode, history and statistics, Core Data persistence, accessibility support, and automated tests.

## Highlights

- **Gameplay**: N×N board sized to the chosen seed word (4–7 letters). Players add exactly one letter adjacent to existing tiles, trace a unique dictionary-valid word including the new letter, and score by word length.
- **Modes**: Play vs computer with three AI difficulties (easy/medium/hard) or pass-and-play with privacy overlay between turns.
- **Dictionary**: Offline trie-backed lookup using a 130k-word frequency-ranked lexicon and curated seed lists per board size. Normal/strict validation modes.
- **AI**: Time-budgeted heuristics with increasing search depth per difficulty, ensuring responsive moves via background tasks.
- **Persistence**: Core Data stores settings, match history, turn-by-turn replays, statistics, and longest words. In-memory preview variant provided for testing.
- **UI/UX**: SwiftUI interface with dynamic type, VoiceOver labels, subdued animations, sound & haptics toggles, hint system, tutorial, and in-app rules. Supports light/dark mode.
- **Testing**: Unit tests for engine, dictionary, AI, persistence plus UI automation smoke tests.

## Requirements

- Xcode 15 or later (Swift 5.9 toolchain)
- iOS 16.0 deployment target

## Getting Started

1. Open `AddOneLetterWordGame.xcodeproj` in Xcode.
2. Select the **AddOneLetterWordGame** scheme and build/run on an iOS 16+ simulator or device.
3. Use the **Settings** tab to configure mode, difficulty, dictionary strictness, sound, haptics, and hints.
4. Launch the interactive tutorial from Settings for a guided walkthrough.

## Testing

- **Unit Tests**: `Cmd+U` with the **AddOneLetterWordGame** scheme selected runs unit and UI tests.
- **UI Tests**: The automation suite covers launch, new game sheet, and navigation to settings.

## Project Structure

- `AddOneLetterWordGame/` – App sources (SwiftUI views, view models, game engine, services, persistence, support utilities).
- `Resources/` – Asset catalogs, sounds, dictionary data, preview assets.
- `AddOneLetterWordGameTests/` – Unit test targets.
- `AddOneLetterWordGameUITests/` – UI automation tests.

## Privacy

The app is fully offline. No analytics or network calls; all player data stays on device. `PrivacyInfo.xcprivacy` declares the "no data collected" policy.

## Support

A placeholder support email (`support@addonelettergame.com`) is linked from Settings > Learn & Support. Replace with your own contact address before submission.
