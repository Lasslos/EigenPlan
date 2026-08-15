# Untis API Reverse Engineering Guide

This guide explains how to intercept network traffic from the Untis Mobile Android app to analyze its backend API endpoints.

## Prerequisites

* [Android Studio](https://developer.android.com/studio) (with Android Emulator installed)
* [HTTP Toolkit](https://httptoolkit.com/) installed on your host machine

## Setup & Interception Steps

1. **Create an Android Virtual Device (AVD):**
    * In Android Studio, open the **Device Manager**.
    * Create a new device (e.g., `Pixel 6 Pro`).
    * Select a system image with **Google APIs** (avoid images with Google Play, as they prevent standard `adb root` access needed for system CA certificate injection).
2. **Launch HTTP Toolkit:**
    * Open HTTP Toolkit on your host machine.
    * Click **Android Device via ADB**. HTTP Toolkit will automatically detect the running emulator, gain system privileges, and inject its CA certificate.
3. **Install the Target App:**
    * Open the browser inside the emulator and download [APKPure](https://apkpure.com/).
    * Search for and install **Untis Mobile** via APKPure.
4. **Capture Traffic:**
    * Open Untis Mobile on the emulator and perform actions (login, view timetable, etc.).
    * Inspect live HTTP/HTTPS requests, headers, and JSON payloads inside HTTP Toolkit.

## Output

Raw, per-endpoint capture notes live under `captures/` — this is the evidence trail, not the reference docs:

- `captures/startup/` — the login/bootstrap sequence, one file per request, organized per school-portal variant
  (normal password+SSO, anonymous, SSO/key-based — see `spec/NOTES.md` for the walkthrough of each).
- `captures/home/` — in-app endpoints exercised after login (timetable, homework, exams, messages, dashboard).

The readable, consolidated reference lives under `spec/`:

- `spec/openapi.yaml` — the consolidated, redacted OpenAPI specification derived from the captures above.
- `spec/NOTES.md` — prose companion to the spec: per-school login walkthroughs and a consolidated list of open
  questions that need a follow-up capture to resolve, including:
  - Does the server use `clientTime` (from the JSON-RPC `auth` object) only to reject requests with too much
    clock drift, or does it also use it to independently derive the expected OTP?
  - Is the JWT from `getAuthToken` interchangeable with the one from `POST .../authentication`, or does the
    app rely on them for different purposes?
  - How reliably does `masterDataTimestamp`-based change detection work in practice (i.e. when does the server
    actually consider master data stale)?