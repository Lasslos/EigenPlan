# POST /WebUntis/api/mobile/v2/{school}/authentication

```
POST https://cjd-koewi.webuntis.com/WebUntis/api/mobile/v2/cjd-koewi/authentication
```

REST username/password login — exchanges credentials directly for a JWT, without going through
`getAppSharedSecret`/`getAuthToken`. See `../../spec/NOTES.md` for the open question of whether this JWT is fully
interchangeable with the one `getAuthToken` issues.

## Request

```json
{
  "password": "<redacted>",
  "username": "<redacted>"
}
```

## Response

```json
{
  "jwt": "<jwt — decoded payload below>",
  "isPasswordChangeRequired": false,
  "isEmailUpdateRequired": false
}
```

Decoded JWT payload:

```json
{
  "tenant_id": "5237400",
  "sub": "Q1",
  "roles": "",
  "iss": "webuntis",
  "locale": "de",
  "sc": "de",
  "user_type": "USER",
  "route": "herakles2.internal.webuntis.com",
  "user_id": 134,
  "host": "",
  "sn": "cjd-koewi",
  "scopes": "mg:r",
  "exp": 1786789354,
  "per": ["mg:r"],
  "iat": 1786788454,
  "username": "Q1",
  "sr": "DE-NW",
  "person_id": 1664
}
```

Note `host` is empty here — the equivalent claim from `getAuthToken` (`XX_getAuthToken.md`) carries the real
school server hostname instead. `sub`/`username` ("Q1") is a shared cohort login (German *Qualifikationsphase
1* year-group), not an individual's name.
