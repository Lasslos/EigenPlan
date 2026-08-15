# getAppSharedSecret

```
POST https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi&m=getAppSharedSecret&a=false&s=cjd-koewi.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getAppSharedSecret`. Exchanges username/password for a long-lived TOTP shared secret,
which is then persisted client-side and used to compute future `otp` values instead of asking for the
password again.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getAppSharedSecret",
  "params": [
    {
      "password": "<redacted>",
      "userName": "<redacted>"
    }
  ]
}
```

## Response

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": "ABCD1234EFGH5678"
}
```

`result` is a base32 TOTP secret (redacted/replaced with a placeholder above — treat this value like a
password; it does not expire on its own).
