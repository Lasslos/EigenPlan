# getStudentAbsences2017

```
POST https://schuldorf.webuntis.com/WebUntis/jsonrpc_intern.do?school=schuldorf&m=getStudentAbsences2017&a=false&s=schuldorf.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getStudentAbsences2017`.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getStudentAbsences2017",
  "params": [
    {
      "includeUnExcused": true,
      "startDate": "2026-08-08T12:00Z",
      "endDate": "2026-09-15T12:00Z",
      "includeExcused": true,
      "auth": {
        "clientTime": 1786796614129,
        "otp": 87948,
        "user": "musterschueler"
      }
    }
  ]
}
```

Note `startDate`/`endDate` use a non-standard ISO-ish format with a literal `Z` but no seconds and no
colon-separated offset (`2026-08-08T12:00Z`), unlike `getTimetable2017`'s plain `YYYY-MM-DD` dates.

## Response

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "absences": []
  }
}
```

`absences` was empty in every capture — item shape unconfirmed. Needs a follow-up capture against an account
with a real recorded absence.
