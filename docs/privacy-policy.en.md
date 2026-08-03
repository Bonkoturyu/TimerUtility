# Privacy Policy (TimerUtility)

Last updated: 2026-08-03
Version: 1.2
Canonical version: [Japanese](privacy-policy.md)

Languages: [日本語](privacy-policy.md) / **English** /
[简体中文](privacy-policy.zh-Hans.md) / [繁體中文](privacy-policy.zh-Hant.md) /
[한국어](privacy-policy.ko.md)

TimerUtility (the "App") minimizes the data needed for its features and does
not send user data to a developer-operated backend. This policy distinguishes
processing by the App, Android system services, and destinations selected by
the user.

---

## 1. Summary

- The App has no developer-operated backend. The developer does not
  automatically receive or remotely store user data from the App.
- Timers, alarms, world clocks, imported sounds, preferences, and diagnostic
  logs are stored on the device.
- The App bundles no advertising, analytics, or crash-reporting SDK.
- Only when an empty world-clock list is initialized for the first time does
  the App, after the OS permission prompt is granted, pass coarse location to
  Android's `Geocoder` system service. That service may
  use a network depending on the device and provider. The App does not persist
  raw coordinates, and the developer does not receive them.
- Microphone input is used transiently only for user-enabled, on-device voice
  stop. It is not recorded, stored, transmitted, or written to diagnostics.
- Diagnostic logs are never uploaded automatically. The user selects a
  destination through the Android Share Sheet.

---

## 2. Data not collected by the developer

The App does not collect the following on a developer-operated server:

- Name, email address, phone number, postal address, or date of birth
- Google, social-media, or other account identifiers
- IMEI, advertising ID, ANDROID_ID, or other device identifiers
- Contacts, calendar, photos, or camera data
- Audio recordings
- Usage analytics, crash reports, or analytics data
- Payment information (the App has no in-app purchases)

Google Play's Data Safety definition of collection includes data transmitted
off the device by an app or SDK. Because the Android `Geocoder` implementation
may use a network, the Play Console declaration is reviewed separately against
the actual system provider and current form.

---

## 3. Data stored on the device

| Data | Purpose | Storage | How to delete |
| --- | --- | --- | --- |
| Timer settings (duration, label, sound, snooze, etc.) | Multiple timers and restore | SQLite (Drift) | In-app UI, clear storage, or uninstall |
| Alarm settings (time, repeat, sound, etc.) | Scheduled alarms | SQLite (Drift) | Same as above |
| Presets | Preset feature | SQLite (Drift) | Same as above |
| World clocks (timezone identifiers and order) | World-clock feature | SQLite (Drift) | Same as above |
| Imported sound files, display names, and metadata | Preview and alarm playback | App-private files / SQLite (Drift) | Imported-sound management UI, clear storage, or uninstall |
| Preferences (theme, language, default sound, app volume, CVD, voice stop, diagnostics, etc.) | Persist settings | SharedPreferences | Clear storage or uninstall |
| Diagnostic logs (only when explicitly enabled) | Troubleshooting | App-private files (JSON Lines; up to 14 days / 50 MB total / 1 MB each) | Clear storage or uninstall |

An imported sound is a user-selected file copied from the Android file picker
into App-private storage. The App does not automatically send it elsewhere.

Microphone input and recognition candidates are not stored. They are used only
while a ringing screen is active and discarded after command matching.

---

## 4. Location data

- Permission: `ACCESS_COARSE_LOCATION` only. The App does not request
  `ACCESS_FINE_LOCATION`.
- When used: Only when an empty world-clock list is initialized for the first
  time. The OS permission dialog asks the user to allow or deny access.
- Processing: Coarse coordinates are passed to Android's `Geocoder` system
  service. Country or region information is mapped to a timezone identifier
  such as `Asia/Tokyo`.
- Network: The `Geocoder` backend depends on the device, OS, and service
  provider and may use a network.
- Storage: The App does not write raw coordinates or geocoding results to
  Drift, SharedPreferences, or diagnostic logs. Only the inferred timezone
  identifier is stored.
- If denied: The App falls back to the device's system timezone.

Official Android `Geocoder` documentation:
<https://developer.android.com/reference/android/location/Geocoder>

---

## 5. Permission rationale

The App declares the following 11 permissions in
[AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml).

| Permission | Purpose | Prompt |
| --- | --- | --- |
| `ACCESS_COARSE_LOCATION` | Initial current-location timezone inference (§4) | OS dialog when an empty world-clock list is first initialized |
| `RECORD_AUDIO` | On-device voice stop while ringing | OS dialog when voice stop is enabled |
| `POST_NOTIFICATIONS` | Timer and alarm notifications | OS dialog on Android 13+ |
| `SCHEDULE_EXACT_ALARM` | Schedule exact alarms | Settings link on applicable versions |
| `USE_EXACT_ALARM` | Exact alarms for clock/alarm use | System-granted; no dialog |
| `USE_FULL_SCREEN_INTENT` | Show the ringing screen over the lock screen | Settings link on applicable versions |
| `WAKE_LOCK` | Wake the CPU when ringing starts | Automatically granted |
| `VIBRATE` | Notification and alarm vibration | Automatically granted |
| `RECEIVE_BOOT_COMPLETED` | Restore schedules after reboot | Automatically granted |
| `FOREGROUND_SERVICE` | Run background alarm playback service | Automatically granted |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Declare that service as media playback | Automatically granted |

---

## 6. Diagnostic logging

The App stores operational logs on the device only when the user enables
"Record diagnostic logs" in Settings.

- Contents: timer/alarm start, stop, snooze, errors, and permission results.
- Excluded: latitude/longitude, microphone input, recognition candidates, and
  user-entered labels.
- Sharing: Only after "Share diagnostic logs" is selected does the App hand a
  zip file to the Android Share Sheet. The user chooses the destination and
  performs the send action. There is no automatic upload.
- Deletion: Turning the toggle off stops new entries. Clear storage or
  uninstall to remove existing files completely.

---

## 7. Third-party services

The App uses no third-party advertising, analytics, crash-reporting, or
developer backend service. It does use Android system services for location,
`Geocoder`, on-device speech recognition, and notifications. Their processing
also follows the device, OS, and service provider's implementation and privacy
settings.

When diagnostic logs are shared, the policy of the user-selected email, cloud
storage, messaging, or other destination applies. See
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) for the dependency list.

---

## 8. Children's privacy

The App is not directed to children under 13. If a child uses it, the same
handling described in this policy applies, and the developer does not receive
personal information from the App.

---

## 9. Security and communications

On-device data is stored in Android app-private storage and follows OS access
controls. The App exposes no developer-operated network endpoint. The App
cannot control transport used by Android system services or a destination the
user selects in the Share Sheet.

---

## 10. User rights and deletion

The developer holds no user data on a server, so there is no server-side data
for the developer to access, correct, or delete. On-device data can be removed
as follows:

- Imported sounds: delete them in the imported-sound management UI.
- Timers and alarms: delete them through the corresponding in-app UI.
- All data: Android Settings > Apps > TimerUtility > Storage & cache > Clear
  storage, or uninstall the App.

Data already shared to another app through the Share Sheet must be deleted at
that destination.

---

## 11. Changes to this policy

Updates revise the date and version above and are published on GitHub Pages.
Material changes are announced in GitHub Release notes or the Play Store
"What's new" section.

---

## 12. Contact

- GitHub Issues: <https://github.com/Bonkoturyu/TimerUtility/issues>
- Maintainer: [@Bonkoturyu](https://github.com/Bonkoturyu)

For sensitive matters such as security vulnerabilities, use the contact method
on the maintainer's GitHub profile instead of a public issue.
