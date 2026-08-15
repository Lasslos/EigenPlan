# POST https://push.webuntis.com/api/register/

```
POST https://push.webuntis.com/api/register/
```

**Auth:** Bearer token required. Note this is on a different host (`push.webuntis.com`), not the school's
server. Registers (or updates) this device for push notifications; sent once at startup after login. EigenPlan
has push/background notifications intentionally disabled for now (see `CLAUDE.md`) — documented here for
completeness only.

## Request

```json
{
  "deviceId": "abc123def456abcd",
  "deviceOs": "ANDROID",
  "environment": "develop",
  "fcmToken": "<redacted-fcm-token>",
  "product": "um"
}
```

`deviceId` is an arbitrary client-generated identifier. `fcmToken` is a Firebase Cloud Messaging registration
token — sensitive, treat like a credential. `environment: "develop"` was the only value observed; a
`production` value for release builds is plausible but unconfirmed.

## Response

Echoes the registration back:

```json
{
  "deviceOs": "ANDROID",
  "deviceId": "abc123def456abcd",
  "fcmToken": "<redacted-fcm-token>",
  "environment": "develop",
  "product": "um"
}
```
