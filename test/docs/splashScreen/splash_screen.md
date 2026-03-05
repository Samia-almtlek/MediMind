# Splash Screen Implementation – MediMind

## 1. Purpose of this document
This document explains the startup experience implemented for MediMind, including branding animation, micro-feedback, and transition into the authentication gate.

---

## 2. Startup routing role
- `main.dart` sets `SplashScreen` as the app home.
- `SplashScreen` is responsible for short branding display and then redirects to `AuthGate`.
- This keeps startup UX separate from auth decision logic.

---

## 3. Core behavior
Implemented in `presentation/screens/splash_screen.dart`:

- **Duration control:** `_splashDuration = 2 seconds`.
- **Typewriter effect:** app name characters appear progressively via periodic timer.
- **Blinking cursor:** separate timer toggles cursor visibility.
- **Logo animation:** gentle scale-in (`TweenAnimationBuilder`) for visual polish.
- **Audio micro-feedback:** two startup click sounds simulate a lightweight heartbeat.
- **Transition:** `Navigator.pushReplacement` to `AuthGate` after splash delay.

---

## 4. Responsive UI strategy
- Logo size scales from screen shortest side and is clamped for device consistency.
- Cache dimensions are computed from pixel ratio to keep logo rendering sharp.
- Text scales with shortest side and uses a fixed-height area to avoid layout jumps.

---

## 5. Lifecycle & stability
- Both timers are canceled in `dispose()` to prevent memory leaks and post-dispose state updates.
- `mounted` checks are applied before state updates and navigation.
- The implementation avoids blocking app initialization and keeps startup deterministic.

---

## 6. What must NOT be changed
- Initial route behavior (`home: SplashScreen`) unless startup strategy is redesigned.
- `pushReplacement` behavior toward `AuthGate` (prevents back-navigation to splash).
- Timer cleanup in `dispose()`.

---

## 7. Future improvements
- Replace static click sound with optional user setting (respect silent-mode preference).
- Add subtle fade transition into `AuthGate` for smoother visual continuity.
- Make splash timing configurable for A/B testing if product requires it.
