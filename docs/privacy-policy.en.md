# Privacy Policy (TimerUtility)

Last updated: 2026-06-20
Version: 1.0 (final version for Play Store submission)
Canonical version: [docs/privacy-policy.md](privacy-policy.md) (Japanese)
This document: English translation

TimerUtility ("the App") respects user privacy and adopts a **zero-collection
architecture** as a design priority. This policy clarifies what data the App
handles, and — more importantly — what it does not.

---

## 1. Summary

- **The App does not collect or transmit any personal information.**
- All data (timers, alarms, world-clock entries, settings, diagnostic logs)
  is stored only on the user's device.
- The App has no network communication features (there is no backend server).
- No advertising SDK, analytics SDK, or crash-reporting SDK is bundled.
- Location data is used only ephemerally for world-clock timezone inference;
  it never leaves the device and is not persisted.

---

## 2. Data NOT collected (corresponds to "no data collected" on the Play Store
Data Safety form)

The App does **not** collect any of the following:

- Personally identifying information (name, email, phone, address, date of birth)
- Account identifiers (Google account, social media accounts)
- Device identifiers (IMEI, advertising ID, ANDROID_ID)
- Access to contacts / calendar / photos / microphone / camera (these
  permissions are not requested)
- App usage statistics, crash reports, or analytics data
- Payment / billing information (no in-app purchases are implemented)

---

## 3. Data handled only on-device

The following data is stored within the App's private storage on the user's
device to support its features, and is **never transmitted off the device**.

| Data | Purpose | Storage | How to delete |
| --- | --- | --- | --- |
| Timer settings (count, durations, labels, sound, snooze configuration) | Multi-timer feature, boot-time restore | On-device SQLite (Drift) | In-app UI, or Android Settings → Apps → Clear storage |
| Alarm settings (time, weekday repeat, enabled state, sound) | Scheduled-alarm feature | On-device SQLite (Drift) | Same as above |
| Presets | Preset feature | On-device SQLite (Drift) | Same as above |
| World-clock entries (timezone identifiers and display order) | World-clock feature | On-device SQLite (Drift) | Same as above |
| User preferences (theme, language, default sound, CVD mode, diagnostic-log toggle, etc.) | Persisting settings-screen options | On-device SharedPreferences | Same as above |
| Diagnostic logs (only when the user explicitly enables them) | Tester/developer troubleshooting | On-device app-private directory (JSON Lines, rotation: 14 days / 50 MB total / 1 MB per file) | Toggle off in the Settings screen, or clear storage |

All of this data is fully removed when the App is uninstalled (standard Android
OS behavior).

---

## 4. Location data handling

The App uses location data **only** to automatically infer the user's current
timezone in the world-clock feature.

- Permission: `ACCESS_COARSE_LOCATION` (coarse accuracy only; the App does
  **not** request `ACCESS_FINE_LOCATION`).
- When used: Only when the user explicitly performs "Add current location"
  in the world-clock screen.
- How used: Coordinates are passed to the on-device `geocoding` API to derive
  a country code, which is then mapped to a timezone identifier (e.g.,
  `Asia/Tokyo`).
- **Coordinates never leave the device.** They are held only in memory during
  conversion and are not written to Drift / SharedPreferences.
- If the user denies location permission, the App falls back to the device's
  system timezone via `FlutterTimezone.getLocalTimezone`.

---

## 5. Permission rationale

The eight permissions declared in [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)
are used solely as follows.

| Permission | Purpose | When prompted |
| --- | --- | --- |
| `ACCESS_COARSE_LOCATION` | Current-location timezone inference in world clock (see §4) | OS dialog during "Add current location" |
| `POST_NOTIFICATIONS` | Display timer / alarm notifications (required on Android 13+) | OS dialog when the first timer/alarm is created |
| `SCHEDULE_EXACT_ALARM` | Exact-time alarm delivery (avoids Doze) | Settings deep-link on Android 14+ |
| `USE_EXACT_ALARM` | Alternative permission auto-granted to clock/alarm-category apps on Android 14+ | Auto-granted (no user prompt) |
| `USE_FULL_SCREEN_INTENT` | Show alarms over the lock screen (Android 14+ requires pre-approval) | Settings deep-link on Android 14+ |
| `WAKE_LOCK` | Wake CPU when an alarm fires | Auto-granted |
| `VIBRATE` | Vibration for notifications / alarms | Auto-granted |
| `RECEIVE_BOOT_COMPLETED` | Auto-restore timers / alarms after device reboot | Auto-granted |

---

## 6. Diagnostic logging

The App records internal operational events **only when the user explicitly
turns on** the "Record diagnostic logs" toggle in the Settings screen.

- Contents: timer / alarm start-stop-snooze events, error information, and
  permission grant results. **PII is masked in advance**:
  - Latitude/longitude is never recorded (only timezone identifiers).
  - User-entered timer / alarm label strings are not recorded.
- Storage: on-device app-private directory (JSON Lines, rotation: 14 days /
  50 MB total / 1 MB per file).
- Sharing: only when the user presses "Share diagnostic logs" does the App
  bundle the logs into a zip and hand it to the Android OS Share Sheet, where
  the **user chooses the destination** (email, Drive, messaging app, etc.).
  **The App never auto-uploads anything.**
- Deletion: Turning off the toggle stops new recordings (existing files
  remain). Full deletion is via "Clear storage" or uninstall.

---

## 7. Third-party services

The App **does not use any third-party analytics, advertising, or backend
services.**

The bundled third-party libraries (Flutter SDK, Riverpod, Drift,
flutter_local_notifications, audioplayers, permission_handler, geolocator,
geocoding, share_plus, etc.) are client libraries that wrap OS APIs and do not
make outbound network requests. (`geocoding` uses Android's built-in
`Geocoder` API, which uses on-device data and does not contact Google's
servers.)

A full dependency listing is in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

---

## 8. Children's privacy

The App is not designed for children under 13 (COPPA threshold). However,
because the App collects **no personal information whatsoever**, no additional
privacy risk arises if a child uses it.

---

## 9. Data encryption

The App handles no personal, credential, or networked data, so there is no
data subject to encryption-in-transit requirements. Drift / SharedPreferences
files follow Android OS's standard app-private storage protections
(accessible only after device unlock).

---

## 10. User rights

Because the App does not collect personal information, there is no data
subject to GDPR / CCPA / Japan-APPI "access, correction, deletion" requests.

To remove all on-device App data:

- Android Settings → Apps → TimerUtility → Storage & cache → Clear storage
- Or uninstall the App

---

## 11. Changes to this policy

If this policy is updated, the "Last updated" date at the top of this file is
revised and published via GitHub Pages. Material changes are announced in
GitHub Release notes and the Play Store "What's new" entry.

---

## 12. Contact

For questions or concerns about this policy:

- GitHub Issues: https://github.com/Bonkoturyu/TimerUtility/issues
- Maintainer: [@Bonkoturyu](https://github.com/Bonkoturyu) (via GitHub
  profile contact)

For sensitive matters such as security vulnerabilities, please use the
maintainer's GitHub profile contact rather than a public issue.
