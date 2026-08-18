# GET /WebUntis/api/rest/view/v1/timetable/menu

```
GET https://bs-gfv.webuntis.com/WebUntis/api/rest/view/v1/timetable/menu?school=bs-gfv
anonymous-school-base64: YnMtZ2Z2
```

**Auth:** Bearer token, or `anonymous-school-base64` header for anonymous-login schools.

Timetable "menu" — the available resources/views for the current user: their own timetable, any
"dependents" (e.g. a parent account's children), and which `ResourceType`s they're allowed to browse via
`timetable/filter` (see `timetable_filter.md`). This is the first call the app makes when opening the
"switch timetable" picker.

## Response — bs-gfv, anonymous (404 — no timetable access for this account)

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

## Response — wolfsburger-oberschule, TEACHER account (200, live probe 2026-08)

```
GET https://wolfsburger-oberschule.webuntis.com/WebUntis/api/rest/view/v1/timetable/menu?school=wolfsburger-oberschule
Authorization: Bearer <jwt>
```

```json
{
  "myTimetable": {
    "type": "TEACHER",
    "resource": { "id": 134, "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML" },
    "imageUrl": null
  },
  "dependents": [],
  "availableTimetables": ["CLASS", "STUDENT", "TEACHER", "ROOM"]
}
```

Confirms the previously-**UNKNOWN** nested shape (see `../../spec/NOTES.md` §3):

- `myTimetable`: `{type: ResourceType, resource: TimetableResource, imageUrl}` — the caller's own resource,
  same shape `timetable/entries`'s `resource` field uses (see `../../spec/openapi.yaml`'s
  `TimetableResource` schema). `imageUrl` was `null` for this account; unconfirmed whether it's ever
  populated (teacher/student profile photo, presumably).
- `dependents`: empty for this (teacher) account — presumably a list of the same
  `{type, resource, imageUrl}` shape as `myTimetable`, one per dependent (e.g. a parent account's
  children), but that shape is **still unconfirmed** — no account captured so far has any dependents.
- `availableTimetables`: **not** a list of specific resources — it's the list of `ResourceType` values
  this account is allowed to *browse* via `timetable/filter` (i.e. which resourceType tabs the "switch
  timetable" search UI should offer). **Confirmed narrower for non-teacher accounts** (2026-08 live probe,
  all four credentialed schools): `wolfsburger-oberschule` (TEACHER) got all four
  (`CLASS`/`STUDENT`/`TEACHER`/`ROOM`); `schuldorf` (STUDENT) got only `[CLASS, STUDENT]`; `cjd-koewi`
  (CLASS) got only `[CLASS]`. The picker UI should render exactly whatever this list contains per account,
  not assume all four tabs are always available.
