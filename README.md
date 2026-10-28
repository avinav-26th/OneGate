# OneGate - Enterprise Visitor Management Mobile Application

> **Sumadhura Real Estate Practical Assignment Submission**  
> **Position**: Flutter Developer  
> **Brand & Application**: OneGate  
> **Visual Identity**: Deep Navy (`#142B3B`), Mint Teal (`#38DCC0`), Off-White (`#F4F7F8`), Slate Surface (`#1E293B`)

---

## 1. Executive Summary & System Overview

**OneGate** is a production-grade, enterprise-ready Visitor Management Mobile Application developed with Flutter & Dart for gated communities, residential projects, and corporate front desks. Built specifically for real estate security personnel and front-desk staff, OneGate streamlines the complete visitor lifecycle from initial pre-registration to contactless QR scanning, multi-session check-in/out logging, and real-time daily metrics monitoring.

### Core Capabilities
- **Streamlined KYC Onboarding**: Capture visitor details with strict validation (Name, 10-digit mobile number, optional email, purpose of visit, host project, and dynamic visitor categories).
- **Instant Digital QR Passes**: High-fidelity vector QR gate passes rendered on-device with unique pass codes (`VIS001`, `VIS002`).
- **Sub-Second Hardware QR Scanning**: Real-time barcode decoding using device camera hardware with duplicate-scan prevention and fallback manual pass lookup.
- **Multi-Session Visit Activity Timeline**: Complete audit trail supporting repeat visits across multiple days without re-entering visitor KYC data.
- **Robust Offline-First Architecture**: Instant 0ms cache startup backed by a durable pending mutation sync queue that auto-replays updates when network connectivity resumes.
- **Enterprise Soft-Delete Recycle Bin**: Quarantines deleted records for 30 days with a 3-second auto-dismissing Undo SnackBar and one-tap restoration.

---

## 2. Technical Stack & Dependencies

| Component | Package / Tool | Version | Architecture Role |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter | `>=3.6.0 <4.0.0` | Cross-platform client application framework |
| **Language** | Dart | `>=3.6.0 <4.0.0` | Strongly-typed object-oriented language |
| **State Management** | `flutter_riverpod` | `^2.6.1` | Declarative, compile-safe, reactive state orchestration |
| **Networking** | `dio` | `^5.8.0+1` | HTTP client with configurable timeouts and error handling |
| **QR Code Generation** | `qr_flutter` | `^4.1.0` | Vector-rendered QR code pass issuance |
| **Barcode / QR Scanning**| `mobile_scanner` | `^6.0.4` | Hardware-accelerated camera preview and QR decoding |
| **Offline Persistence** | `shared_preferences` | `^2.5.2` | Local JSON snapshot caching & pending mutation queue |
| **Device Sensors** | `light` | `^3.0.0` | Ambient light sensor for automated flashlight assistance |

---

## 3. Architecture & Design Principles

OneGate adheres to **Clean Architecture** with a **Feature-First** modular organization:

```
lib/
├── app/                              # Application bootstrap, navigation & theme
│   ├── widgets/                      # SmoothCurvedNavBar, custom shell components
│   ├── app.dart                      # MaterialApp root with theme provider
│   ├── main_navigation_shell.dart    # Root scaffold with Riverpod tab state
│   └── theme.dart                    # Light and Dark theme configurations
├── core/                             # Cross-cutting foundational modules
│   ├── constants/                    # AppColors, AppStrings, ApiConstants, AppConstants
│   ├── data/                         # Tiered data orchestrator (Instant/Heavy/Dynamic)
│   ├── errors/                       # Custom failures and exception handlers
│   └── utils/                        # Validators, DateFormatter, AppSnackBar
└── features/                         # Independent feature-driven domains
    ├── dashboard/                    # Overview metrics, greeting banner, recent visitors
    │   ├── presentation/
    │   │   ├── controllers/          # DashboardMetrics & RecentVisitors providers
    │   │   ├── screens/              # DashboardScreen
    │   │   └── widgets/              # GreetingBanner, TodayMetricsCard, RecentVisitorTile
    ├── scanner/                      # Camera-based QR gate pass verification
    │   └── presentation/             # QrScannerScreen, Manual pass lookup dialog
    └── visitors/                     # Visitor registry, profile, form & recycle bin
        ├── data/                     # VisitorRepositoryImpl, network sync, local cache
        ├── domain/                   # Visitor entity, VisitSession, VisitStatusPolicy
        └── presentation/
            ├── controllers/          # VisitorListNotifier, VisitorDetailsNotifier, VisitorFormNotifier
            ├── screens/              # VisitorListScreen, VisitorDetailsScreen, VisitorFormScreen, RecycleBinScreen
            └── widgets/              # VisitorCard, StatusChip, CustomButton, DeleteDialog, EmptyStateWidget
```

### Architectural Highlights

#### 1. Compile-Safe, Reactive State Management (Riverpod)
* **Zero-`setState` Root Navigation & Details**: Tab indices and visitor details are managed through Riverpod providers (`mainNavigationIndexProvider`, `visitorDetailsNotifierProvider`), eliminating redundant rebuilds of whole-screen widget trees.
* **Aggressive Mutation Guards**: Built-in debouncing (`_pendingActions` set and `_isMutating` locks) prevents double-clicks, multiple rapid submissions, or conflicting status transitions.
* **Unidirectional Data Flow**: Mutating a visitor status automatically propagates updates to dashboard metrics, filtered visitor lists, and cached sessions simultaneously.

#### 2. Decoupled Collapsing Header Architecture
* In [`VisitorDetailsScreen`](lib/features/visitors/presentation/screens/visitor_details_screen.dart), the collapsible QR header is decoupled from the scroll viewport:
  * Placed as an independent `_QrHeader` widget inside a root `Column` above an `Expanded(child: SingleChildScrollView)`.
  * **Result**: Scrollable content can never slide underneath or get hidden behind the header card.
  * Driven by an explicit `AnimationController` triggered by user drag gestures (`NotificationListener<ScrollNotification>`), guaranteeing binary, reliable transitions between expanded and compact modes across all visitor statuses without getting stuck halfway.

#### 3. Zero-Latency Theme Transitions
* Configured `themeAnimationDuration: Duration.zero` on `MaterialApp` to eliminate Flutter's staggered 200ms lerp delay.
* Replaced Material `CircleAvatar` widgets (which hardcode an internal 200ms `AnimatedContainer`) with explicit `Container(shape: BoxShape.circle)` widgets.
* **Result**: Dark and Light mode transitions occur atomically in the exact same render frame with zero visual tearing or delayed color popping.

---

## 4. Setup & Execution Instructions

### Prerequisites
- **Flutter SDK**: `>=3.6.0` (Dart `>=3.6.0`)
- **IDE**: VS Code (with Flutter extension) or Android Studio
- **Platform**: Physical Android device or Android Virtual Device (AVD running API 26+)

### Installation & Run Steps

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd one_gate
   ```

2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify static analysis**:
   ```bash
   flutter analyze
   ```
   *(Expected output: `No issues found!`)*

4. **Run automated test suite**:
   ```bash
   flutter test test/widget_test.dart
   ```
   *(Expected output: `All 8 tests passed!`)*

5. **Launch the application**:
   ```bash
   flutter run
   ```

6. **Generate production release APK**:
   ```bash
   flutter build apk --release
   ```
   The built binary will be available at:  
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Mock REST API Details

### Cloud Endpoint Configuration
OneGate integrates with a live, persistent MockAPI REST service:
- **Base Endpoint**: `https://6ae0ffeebe3bc8fead9826a2.mockapi.io/api/v1`
- **Resource Collection**: `/visitors`
- **Live Data URL**: [https://6ae0ffeebe3bc8fead9826a2.mockapi.io/api/v1/visitors](https://6ae0ffeebe3bc8fead9826a2.mockapi.io/api/v1/visitors)

### Supported REST Operations

| Method | Endpoint | Action Description | Request Body Example |
| :--- | :--- | :--- | :--- |
| **GET** | `/visitors` | Fetch complete visitor directory | *None* |
| **GET** | `/visitors/{id}` | Fetch individual visitor by Pass ID | *None* |
| **POST** | `/visitors` | Register new visitor pass | `{"name": "Rahul Sharma", "mobile": "9876543210", ...}` |
| **PUT/PATCH**| `/visitors/{id}` | Update visitor details | `{"name": "Rahul Sharma", "project": "Project B"}` |
| **PATCH** | `/visitors/{id}` | Update gate status & timestamps | `{"status": "Checked In", "check_in_time": "..."}` |
| **DELETE** | `/visitors/{id}` | Permanent record removal | *None* |

### Pre-populated Test Profiles
The live MockAPI service contains standardized test records covering all statuses:
* `VIS001` - **Rahul Sharma** (Customer, Project A, *Registered*)
* `VIS002` - **Priya Patel** (Vendor, Project B, *Checked In*)
* `VIS003` - **Amit Kumar** (Contractor, Project C, *Checked Out*)
* `VIS004` - **Sneha Reddy** (Customer, Project A, *Registered*)
* `VIS005` - **Vikram Singh** (Guest, Project B, *Checked In*)

---

## 6. Complete Feature Matrix

### Mandatory Specifications
- [x] **Activity Dashboard**: Real-time KPI summary (Total Visitors Today, Currently Checked In, Checked Out Today) with pull-to-refresh.
- [x] **Quick Action Shortcuts**: Instant navigation to Register Visitor, Scan Gate Pass, and View All Visitors.
- [x] **Strict Form Validation & Length Caps**:
  - Full Name: Mandatory, non-empty, capped at 100 characters.
  - Mobile Number: Restrained strictly to **10 numeric digits** (input formatter prevents typing >10 digits).
  - Email Address: Optional; RFC 5322 regex validation capped at **254 characters**.
  - Purpose of Visit: Input length capped at 500 characters with quick-fill tag chips.
- [x] **Dynamic 'Other' Visitor Category**: Dynamic text input field opens when "Other" is selected to capture custom roles.
- [x] **Digital Vector QR Pass**: Instant on-device vector QR rendering (`qr_flutter`) embedding the unique Pass ID.
- [x] **Hardware QR Scanner**: Real-time camera feed (`mobile_scanner`) with duplicate debouncing and auto-pause.
- [x] **Manual Pass Entry**: Accessible dialog for front-desk guards to type IDs manually if the camera is obstructed.
- [x] **Strict Status Transition Policy**: Enforces valid transitions (`Registered -> Checked In -> Checked Out -> Re-visiting`) via `VisitStatusPolicy`.
- [x] **Delete Confirmation Dialog**: Destructive action safeguard preventing accidental record loss.

### Advanced & Bonus Enhancements
- [x] **100% Offline-First Synchronization**: Local storage acts as the single source of truth; background sync queue retries pending network requests automatically.
- [x] **Soft-Delete Recycle Bin**: Deleted visitors enter a 30-day quarantine with an Undo SnackBar and permanent restore/purge controls.
- [x] **Multi-Session Visit Activity Timeline**: Allows visitors to return multiple times ("Start New Visit") while preserving complete historical session durations and timestamps.
- [x] **Sub-Pixel Curved Navigation Bar**: Custom painter bottom bar with a floating active indicator that tracks page swipe fractions continuously.
- [x] **Zero-Latency Dark / Light Theme**: Comprehensive dual theme with app bar toggle, instant color synchronization, and subtle time-based greeting banners.
- [x] **Touch Dismissal & Keyboard Management**: Tapping outside any input field or search bar across the application instantly unfocuses the keyboard.

---

## 7. Automated Test Suite

Automated unit and widget tests are located in [`test/widget_test.dart`](test/widget_test.dart):

```bash
flutter test test/widget_test.dart
```

### Verified Test Cases
1. **`VisitStatusPolicy` Check-In Eligibility**: Asserts that `registered` and `checkedOut` visitors can check in for new sessions.
2. **`VisitStatusPolicy` Check-Out Constraint**: Asserts that check-out is strictly prohibited unless current status is `checkedIn`.
3. **`VisitStatusPolicy` Terminal State Rules**: Validates status constraints and re-visiting policies.
4. **`Validators` Mobile Number Rule**: Ensures exactly 10 digits are required; rejects non-numeric and short strings.
5. **`Validators` Non-Empty Name Rule**: Validates mandatory visitor names.
6. **Soft Delete Preservation**: Asserts that `copyWith` preserves `isDeleted` and `deletedAt` timestamps.
7. **Active vs. Recycle Bin Aggregation**: Verifies that metrics counters exclude quarantined records.
8. **`VisitSession` Duration Calculation**: Verifies session duration formatting (`45 mins`, `2 hrs 10 mins`) and completion flags.

---

## 8. Known Limitations & Edge-Case Handling

1. **MockAPI Single-Collection Schema**: MockAPI stores flat JSON documents. To support full multi-session audit logs, the app persists the complete `visit_history` list locally and synchronizes root status updates with the cloud endpoint.
2. **Device Ambient Light Sensor Hardware**: Budget Android devices poll light sensors irregularly. The auto-flash trigger activates upon detection of illuminance $< 15$ lux when environmental changes occur.
3. **Emulator Camera Preview**: Android emulators without a configured virtual scene cannot decode physical barcodes; the integrated "Manual Entry" modal serves as the primary fallback on emulators.
4. **Dynamic 'Other' Custom Category Persistence**: User-entered custom visitor roles are saved in the local session cache and display; cloud sync persists standard category headers until relational schema migrations are enabled on the backend.

---

## 9. Future Horizons & Scalability Roadmap

1. **Regional Multi-Language Localization (i18n & l10n)**: Introduce `flutter_localizations` with `.arb` dictionaries for English, Hindi, Kannada, and Telugu to support diverse on-site security personnel.
2. **Rotating TOTP Dynamic Passes**: Implement time-based rotating QR passes (30-second HMAC-SHA256 tokens) to eliminate screenshot-sharing vulnerabilities.
3. **On-Device OCR ID Scanning**: Integrate Google ML Kit text recognition to auto-populate visitor names, IDs, and vehicle license plates at the gate within 1 second.
4. **Gate-to-Gate Real-Time Sync**: Incorporate WebSockets / SSE to broadcast check-in/out events across multi-gate perimeters instantaneously.

---

## 10. License & Copyright

Developed for the **Sumadhura Real Estate** Developer Practical Assessment.  
Copyright &copy; 2026. All rights reserved.
