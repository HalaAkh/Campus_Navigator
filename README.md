# 🧭 Campus Navigator LAU — Flutter App

Indoor BLE beacon navigation for Lebanese American University, Nicol Hall Floors 4 & 5.

---

## 📁 Project Structure

```
lib/
├── main.dart                          # Entry point, Firebase init, Provider
├── config/
│   └── app_config.dart                # API keys, OpenAI prompts (F4 & F5)
├── data/
│   └── rooms.dart                     # All 57 rooms + 6 beacons (real MAC addresses)
├── models/                            # (types defined in data/rooms.dart)
├── services/
│   ├── auth_service.dart              # Firebase Auth (@lau.edu.lb validation)
│   ├── beacon_service.dart            # flutter_blue_plus BLE scanning
│   ├── navigation_service.dart        # OpenAI GPT-4o-mini routing (multi-floor)
│   └── permission_service.dart        # Bluetooth + Location permissions
├── utils/
│   ├── theme.dart                     # Colors, typography, decorations
│   ├── app_state.dart                 # Provider state (beacons, nav, settings)
│   └── app_navigator.dart             # Full screen routing (23 screens)
├── widgets/
│   ├── common/widgets.dart            # GradientButton, AppCard, BottomTabBar, etc.
│   └── navigation/floor_plan_widget.dart  # Custom SVG floor maps (F4 & F5)
└── screens/
    ├── splash/splash_screen.dart
    ├── onboarding/onboarding_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   └── auth_screens.dart          # SignUp, ForgotPW, VerifyEmail, Permissions
    ├── home/home_screen.dart
    ├── search/search_screen.dart
    ├── navigation/
    │   ├── room_detail_screen.dart
    │   ├── active_navigation_screen.dart
    │   └── navigation_screens.dart    # FloorTransition, Arrived, BeaconLost
    ├── map/map_screen.dart
    ├── profile/profile_screen.dart
    └── settings/settings_screens.dart # Settings, SavedRooms, Help, Feedback, About
```

---

## 🚀 Setup Instructions

### 1. Flutter Environment
```bash
flutter --version  # Requires Flutter 3.x+
cd campus_navigator
flutter pub get
```

### 2. Firebase Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (creates google-services.json + GoogleService-Info.plist)
flutterfire configure
```

Then in Firebase Console:
- Enable **Email/Password** authentication
- Create **Firestore** database
- Add rule: only `@lau.edu.lb` emails can authenticate (handled in code)

### 3. OpenAI API Key
Pass your key via `--dart-define` at build time:
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

Or set it directly in `lib/config/app_config.dart` (dev only, never commit):
```dart
static const String openAiApiKey = 'sk-your-key-here';
```

### 4. Assets
Place these in `assets/images/`:
- `logo.png` — Campus Navigator logo
- `campus_map.png` — LAU Beirut 3D campus map

### 5. Run
```bash
# Android
flutter run

# iOS
open ios/Runner.xcworkspace
flutter run
```

---

## 🔵 Real Beacon MAC Addresses

### Floor 4
| Beacon | MAC | Location |
|--------|-----|----------|
| C6:2A | `C6:2A:90:A1:99:CB` | Elevator/Stairs Junction |
| E5:65 | `E5:65:DD:D0:91:EC` | Room 408 Junction |
| C8:93 | `C8:93:08:09:B2:CA` | Left Offices Corridor |

### Floor 5
| Beacon | MAC | Location |
|--------|-----|----------|
| FC:17 | `FC:17:8A:61:EC:6D` | Elevator/Stairs 1 Junction |
| F3:55 | `F3:55:BD:A3:65:2E` | Left Office Corridor |
| C7:A4 | `C7:A4:5A:D0:74:D8` | Room 511 Junction |

---

## 🏗️ Architecture

```
UI (Screens) → AppNavigator (router) → AppState (Provider)
                                            ↓
                              BeaconService (flutter_blue_plus)
                              NavigationService (OpenAI GPT-4o-mini)
                              AuthService (Firebase Auth)
```

**Navigation flow:**
```
Splash → Onboarding → Login/SignUp → VerifyEmail → Permissions → Home
Home → Search → RoomDetail → ActiveNavigation → Arrived
Home → Map
Home → Profile → Settings / Saved / Help / Feedback / About
```

---

## 🧠 OpenAI Integration

The app sends to GPT-4o-mini:
- Current beacon MAC address
- Destination room number
- Full floor layout system prompt (180-370 lines)
- Returns JSON with step-by-step path

Temperature: 0.3 (deterministic routing)
Max tokens: 1000
Response format: JSON object

Multi-floor logic mirrors `multi_floor_navigator.py`:
1. Navigate to stairs on current floor
2. Cross floors (Main Stairs near elevator OR Back Stairs near 408/511)
3. Navigate to destination on target floor

---

## 📱 Screens (23 total)

| # | Screen | File |
|---|--------|------|
| 1 | Splash | splash_screen.dart |
| 2-4 | Onboarding (3 slides) | onboarding_screen.dart |
| 5 | Login | login_screen.dart |
| 6 | Sign Up | auth_screens.dart |
| 7 | Forgot Password | auth_screens.dart |
| 8 | Verify Email | auth_screens.dart |
| 9 | Permissions | auth_screens.dart |
| 10 | Home Dashboard | home_screen.dart |
| 11 | Campus Map | map_screen.dart |
| 12 | Destination Search | search_screen.dart |
| 13 | Room Detail | room_detail_screen.dart |
| 14 | Active Navigation | active_navigation_screen.dart |
| 15 | Floor Transition | navigation_screens.dart |
| 16 | You've Arrived | navigation_screens.dart |
| 17 | Beacon Lost | navigation_screens.dart |
| 18 | Profile | profile_screen.dart |
| 19 | Settings | settings_screens.dart |
| 20 | Saved Rooms | settings_screens.dart |
| 21 | Help & FAQ | settings_screens.dart |
| 22 | Feedback | settings_screens.dart |
| 23 | About | settings_screens.dart |

---

## 🎨 Design System

- **Primary:** `#007A6E` (deep teal) → `#00BCD4` (bright teal) gradient
- **Accent:** `#F59E0B` (amber) — CTAs, badges, highlights
- **Success:** `#10B981`
- **Background:** `#F7FAFA`
- **Headings:** Fraunces (serif, warm)
- **Body:** Plus Jakarta Sans (rounded, friendly)
- **Buttons:** Pill shape (border-radius: 9999)
- **Cards:** 20px radius, warm teal-tinted shadow

---

## ⚠️ Notes

1. **No google-services.json included** — run `flutterfire configure` to generate
2. **OpenAI key is not included** — use `--dart-define` or set in app_config.dart
3. **Fonts are loaded via google_fonts** — requires internet on first run
4. **BLE scanning requires physical device** — won't work on simulator/emulator
5. **campus_map.png** — add your LAU campus map image to `assets/images/`
