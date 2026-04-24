# Retrofit Bingo — Caller App

Flutter Android app for the **KDFN Community Retrofit Initiative** bingo game night. Designed to be used by the caller to draw addresses, verify winning cards, and guide the evening through multiple rounds.

---

## How the Game Works

Instead of letters B-I-N-G-O, columns are named after streets in the retrofit program:

| Column | Streets |
|--------|---------|
| **MURPHY** | Murphy Rd |
| **HANNA** | Hanna Cr |
| **McCANDLESS** | McCandless Cr |
| **SWAN/CROW/O'BRIEN** | Swan Dr · Crow St · O'Brien Rd/Pl |
| **Mc STREETS** | McCrimmon Cr · McClennan Rd · McIntyre Dr |

Draw slips are full addresses (e.g. *"25 Murphy Rd"*). Players mark the house number in the matching street column.

**Wild card:** 77 Long Lake Rd — players mark any unclaimed square.

---

## Round Sequence

The app guides the caller through 5 progressive rounds on the same card:

1. **Single Line** — any row, column, or diagonal
2. **Two Lines** — any two lines
3. **Four Corners** — all four corner squares
4. **T-Shape** — top row + middle column
5. **Full House** — all 25 squares

Drawn addresses carry over into each new round. Players do not need new cards between rounds.

---

## App Features

- 🎱 **Ball machine sound effects** — roll, drop, and reveal on each draw
- 🎉 **Instant bingo verification** — enter any card number (1–1000) to check automatically
- 🏆 **Confetti animation** on confirmed bingo
- 📋 **Round summary** screen after each round showing winners
- 🔇 **Mute toggle** for sound effects
- 🕓 **Draw history** — last 8 draws shown at a glance

---

## Setup

### Prerequisites
- Flutter 3.x
- Android Studio or Android SDK
- A physical Android device or emulator

### Run
```bash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```
The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Card Data

All 1,000 card layouts are embedded in `assets/data/bingo_cards.json`. The printed PDF cards (`bingo_cards_1000.pdf`) are the physical counterpart — card numbers match exactly.

---

## Project Structure

```
lib/
  main.dart                  — App entry, providers
  models/
    bingo_card.dart           — Card model, bingo detection, game types
    game_state.dart           — Draw bag, round management, game flow
  services/
    audio_service.dart        — Sound effect playback
  screens/
    home_screen.dart          — Game setup & round sequence overview
    caller_screen.dart        — Main draw interface
    check_card_screen.dart    — Card verification with visual grid
    round_summary_screen.dart — End-of-round results & next round
assets/
  data/bingo_cards.json       — 1,000 card layouts
  sounds/                     — MP3 sound effects
  images/kdfn-logo.png        — KDFN logo (transparent)
```
