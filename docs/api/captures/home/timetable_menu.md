# GET /WebUntis/api/rest/view/v1/timetable/menu

```
GET https://bs-gfv.webuntis.com/WebUntis/api/rest/view/v1/timetable/menu?school=bs-gfv
anonymous-school-base64: YnMtZ2Z2
```

**Auth:** Bearer token, or `anonymous-school-base64` header for anonymous-login schools.

Timetable "menu" — presumably the available resources/views for the current user (own class/student, or for a
teacher a searchable list of classes/teachers/rooms). **Every capture of this endpoint hit the error path
below** (this particular account has no timetable access) — the 200-response success shape was never
observed and needs a follow-up capture against an account that actually has timetable access.

## Response (404 — no timetable access for this account)

```json
{
  "errorCode": "NO_TIMETABLES_AVAILABLE_FOR_YOUR_USER",
  "requestId": "ae5538a079b6225703a3d044bb1a3693",
  "traceId": "",
  "validationErrors": [
    {
      "path": "",
      "errorMessage": "No timetables available for the current user!"
    }
  ]
}
```
