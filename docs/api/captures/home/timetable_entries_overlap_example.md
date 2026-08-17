# GET /WebUntis/api/rest/view/v1/timetable/entries — overlapping-period example

```
GET https://wolfsburger-oberschule.webuntis.com/WebUntis/api/rest/view/v1/timetable/entries?start=2026-08-17&end=2026-08-23&format=1&resourceType=TEACHER&resources=134&periodTypes=...&layout=PRIORITY&school=wolfsburger-oberschule
GET https://wolfsburger-oberschule.webuntis.com/WebUntis/api/rest/view/v1/timetable/entries?start=2026-08-17&end=2026-08-23&format=1&resourceType=CLASS&resources=1139&periodTypes=...&layout=PRIORITY&school=wolfsburger-oberschule
```

**Auth:** Bearer token required.

Live capture (curl, not HTTP Toolkit) of the same real morning — 2026-08-17, teacher account — viewed both as
`resourceType=TEACHER` (own timetable) and `resourceType=CLASS` (the 5d homeroom's timetable). Captured
specifically to resolve `../../spec/NOTES.md`'s open question about `layoutStartPosition`/`layoutWidth`, since
every prior capture happened to show the non-overlapping case (`layoutWidth: 1000` throughout). This one has
a genuine overlap and a genuine substitution, so both are documented here rather than left as `**UNKNOWN**` in
the spec. See `../../spec/openapi.yaml`'s `GridEntry` schema for the consolidated field documentation this
capture informed.

## What this confirms

- **`layoutStartPosition`/`layoutWidth` are real, not always `0`/`1000`.** All entries below share
  `layoutGroup: 1` (they co-occur in time). A day-long `EVENT` gets a fixed-width column for its entire span;
  the remaining width is shared dynamically by whatever else is happening at each moment — full width when
  only one thing is active, split evenly when two things genuinely coincide (11:35–12:20 below: two different
  subjects, each `layoutWidth: 333` out of 1000). No client-side collision/packing algorithm is needed — this
  is meant to be rendered directly.
- **Position-slot ordering depends on `resourceType`.** Same physical event, two views:
  - `resourceType=TEACHER`: `position1=CLASS`, `position2=SUBJECT` (or `INFO` for the `EVENT`), `position3=ROOM`,
    `position4=TEACHER` (populated only when there's a *second* teacher co-teaching — your own attendance is
    implicit from the resource you queried).
  - `resourceType=CLASS`: `position1=TEACHER` (an array when co-taught — see the `EVENT` entry below, which
    lists two teachers in one slot), `position2=SUBJECT`/`INFO`, `position3=ROOM`. `position4` unused here.
- **`GridEntryPositionItem.removed` is real.** The 09:45–11:15 and 10:30–11:15 periods are a genuine
  substitution: `position3` (ROOM) and `position4` (TEACHER) both carry a `current`/`removed` pair — the new
  room/teacher with status `ADDED`, the original with status `REMOVED`. Confirms the substitution
  strikethrough UI has real data to render against.
- **`statusDetail: "SUBSTITUTED"`** — a non-null value, previously only ever seen `null`.
- **`texts[].type: "LESSON_INFO"`** — a second `texts` type alongside the previously-documented
  `SUBSTITUTION_TEXT`.
- **`color` tracks status/type, not a stable per-subject identity** — the same subject appears with different
  colors depending on status (e.g. a cancelled period renders grey `bfc8cf` regardless of subject; one
  cancelled period here instead renders `ff0000`, i.e. plain red — inconsistent with the grey seen elsewhere
  for the same status, and unconfirmed why). Reinforces that the app's own per-subject color preference should
  stay authoritative rather than trusting server `color`.

## Response — `resourceType=TEACHER` (own timetable)

```json
{
  "date": "2026-08-17",
  "resourceType": "TEACHER",
  "resource": { "id": 134, "shortName": "ML", "longName": "Musterlehrer", "displayName": "" },
  "status": "REGULAR",
  "dayEntries": [],
  "gridEntries": [
    {
      "ids": [2654834],
      "duration": { "start": "2026-08-17T07:55", "end": "2026-08-17T13:10" },
      "type": "EVENT",
      "status": "CHANGED",
      "statusDetail": null,
      "layoutStartPosition": 0,
      "layoutWidth": 500,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": ["NOTES"],
      "position1": [{ "current": { "type": "CLASS", "status": "REGULAR", "shortName": "5d", "longName": "5d OBS", "displayName": "5d", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "INFO", "status": "REGULAR", "shortName": "KL-Unterricht", "longName": "KL-Unterricht", "displayName": "KL-Unterricht", "displayNameLabel": null }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "ADDED", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "position4": [{ "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML2", "longName": "Musterlehrer2", "displayName": "ML2", "displayNameLabel": "NAME" }, "removed": null }],
      "position5": null, "position6": null, "position7": null,
      "texts": [{ "type": "LESSON_INFO", "text": "KL-Unterricht" }],
      "lessonText": "", "lessonInfo": "KL-Unterricht", "substitutionText": "",
      "userName": null, "moved": null, "durationTotal": null, "link": null
    },
    {
      "ids": [2637416],
      "duration": { "start": "2026-08-17T09:25", "end": "2026-08-17T09:45" },
      "type": "BREAK_SUPERVISION",
      "status": "REGULAR",
      "layoutStartPosition": 500,
      "layoutWidth": 500,
      "layoutGroup": 1,
      "color": "D47AEB",
      "icons": [],
      "position1": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "PH 2", "longName": "NW/ HW/Te/ Musik", "displayName": "PH 2", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": null, "position3": null, "position4": null,
      "texts": [], "lessonText": null, "lessonInfo": null, "substitutionText": null
    },
    {
      "ids": [2500541],
      "duration": { "start": "2026-08-17T09:45", "end": "2026-08-17T10:30" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CHANGED",
      "statusDetail": "SUBSTITUTED",
      "layoutStartPosition": 500,
      "layoutWidth": 500,
      "layoutGroup": 1,
      "color": "2feecb",
      "icons": ["NOTES"],
      "position1": [{ "current": { "type": "CLASS", "status": "REGULAR", "shortName": "7a", "longName": "7a OBS", "displayName": "7a", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Te", "longName": "Technik", "displayName": "Te", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{
        "current": { "type": "ROOM", "status": "ADDED", "shortName": "1W11", "longName": "Küche", "displayName": "1W11", "displayNameLabel": "NAME" },
        "removed": { "type": "ROOM", "status": "REMOVED", "shortName": "1W13", "longName": "Technikraum", "displayName": "1W13", "displayNameLabel": "NAME" }
      }],
      "position4": [{
        "current": { "type": "TEACHER", "status": "ADDED", "shortName": "ML4", "longName": "Musterlehrer4", "displayName": "ML4", "displayNameLabel": "NAME" },
        "removed": { "type": "TEACHER", "status": "REMOVED", "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML", "displayNameLabel": "NAME" }
      }],
      "texts": [{ "type": "SUBSTITUTION_TEXT", "text": "ganze Klasse" }],
      "lessonText": "", "lessonInfo": null, "substitutionText": "ganze Klasse"
    },
    {
      "ids": [2500544],
      "duration": { "start": "2026-08-17T10:30", "end": "2026-08-17T11:15" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CHANGED",
      "statusDetail": "SUBSTITUTED",
      "layoutStartPosition": 500,
      "layoutWidth": 500,
      "layoutGroup": 1,
      "color": "2feecb",
      "icons": [],
      "position1": [{ "current": { "type": "CLASS", "status": "REGULAR", "shortName": "7a", "longName": "7a OBS", "displayName": "7a", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Te", "longName": "Technik", "displayName": "Te", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{
        "current": { "type": "ROOM", "status": "ADDED", "shortName": "1W11", "longName": "Küche", "displayName": "1W11", "displayNameLabel": "NAME" },
        "removed": { "type": "ROOM", "status": "REMOVED", "shortName": "1W13", "longName": "Technikraum", "displayName": "1W13", "displayNameLabel": "NAME" }
      }],
      "position4": [{
        "current": { "type": "TEACHER", "status": "ADDED", "shortName": "ML4", "longName": "Musterlehrer4", "displayName": "ML4", "displayNameLabel": "NAME" },
        "removed": { "type": "TEACHER", "status": "REMOVED", "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML", "displayNameLabel": "NAME" }
      }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2427670],
      "duration": { "start": "2026-08-17T11:35", "end": "2026-08-17T12:20" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 500,
      "layoutWidth": 500,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": [],
      "position1": [{ "current": { "type": "CLASS", "status": "REGULAR", "shortName": "5d", "longName": "5d OBS", "displayName": "5d", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Verf", "longName": "Verfügung", "displayName": "Verf", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2581226],
      "duration": { "start": "2026-08-17T12:25", "end": "2026-08-17T13:10" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 500,
      "layoutWidth": 500,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": [],
      "position1": [{ "current": { "type": "CLASS", "status": "REGULAR", "shortName": "5d", "longName": "5d OBS", "displayName": "5d", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Kl-Essen", "longName": "Klassenessen", "displayName": "Kl-Essen", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2499131, 2499134],
      "duration": { "start": "2026-08-17T14:05", "end": "2026-08-17T15:35" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "REGULAR",
      "layoutStartPosition": 0,
      "layoutWidth": 1000,
      "layoutGroup": 2,
      "color": "2feecb",
      "icons": [],
      "position1": [{ "current": { "type": "CLASS", "status": "REGULAR", "shortName": "7b", "longName": "7b OBS", "displayName": "7b", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Te", "longName": "Technik", "displayName": "Te", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1W12", "longName": "Werkraum 1", "displayName": "1W12", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    }
  ],
  "backEntries": []
}
```

## Response — `resourceType=CLASS` (same day, homeroom 5d's view)

Same physical periods, different position-slot semantics (`position1` is now `TEACHER`), and a wider layout
group since the class has *two* genuinely simultaneous periods at 11:35–12:20 (two different subjects, split
`333`/`333` on either side of the day-long `EVENT`'s `333`-wide column) instead of the teacher-view's single
half/half split.

```json
{
  "date": "2026-08-17",
  "resourceType": "CLASS",
  "resource": { "id": 1139, "shortName": "5d", "longName": "5d OBS", "displayName": "" },
  "status": "REGULAR",
  "dayEntries": [],
  "gridEntries": [
    {
      "ids": [2654834],
      "duration": { "start": "2026-08-17T07:55", "end": "2026-08-17T13:10" },
      "type": "EVENT",
      "status": "CHANGED",
      "layoutStartPosition": 0,
      "layoutWidth": 333,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": ["NOTES"],
      "position1": [
        { "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML", "displayNameLabel": "NAME" }, "removed": null },
        { "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML2", "longName": "Musterlehrer2", "displayName": "ML2", "displayNameLabel": "NAME" }, "removed": null }
      ],
      "position2": [{ "current": { "type": "INFO", "status": "REGULAR", "shortName": "KL-Unterricht", "longName": "KL-Unterricht", "displayName": "KL-Unterricht", "displayNameLabel": null }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "ADDED", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "position4": null,
      "texts": [{ "type": "LESSON_INFO", "text": "KL-Unterricht" }],
      "lessonText": "", "lessonInfo": "KL-Unterricht", "substitutionText": ""
    },
    {
      "ids": [2521871, 2521874],
      "duration": { "start": "2026-08-17T07:55", "end": "2026-08-17T09:25" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 333,
      "layoutWidth": 666,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": [],
      "position1": [{ "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML3", "longName": "Musterlehrer3", "displayName": "ML3", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "spko", "longName": "Sport Koedukativ", "displayName": "spko", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "SpoB", "longName": "Sporthalle B", "displayName": "SpoB", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2436694, 2436697],
      "duration": { "start": "2026-08-17T09:45", "end": "2026-08-17T11:15" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 333,
      "layoutWidth": 666,
      "layoutGroup": 1,
      "color": "ff0000",
      "icons": [],
      "position1": [{ "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML2", "longName": "Musterlehrer2", "displayName": "ML2", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "De", "longName": "Deutsch", "displayName": "De", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2427670],
      "duration": { "start": "2026-08-17T11:35", "end": "2026-08-17T12:20" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 333,
      "layoutWidth": 333,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": [],
      "position1": [{ "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Verf", "longName": "Verfügung", "displayName": "Verf", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2430067],
      "duration": { "start": "2026-08-17T11:35", "end": "2026-08-17T12:20" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 667,
      "layoutWidth": 333,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": [],
      "position1": [{ "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML2", "longName": "Musterlehrer2", "displayName": "ML2", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Verf", "longName": "Verfügung", "displayName": "Verf", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    },
    {
      "ids": [2581226],
      "duration": { "start": "2026-08-17T12:25", "end": "2026-08-17T13:10" },
      "type": "NORMAL_TEACHING_PERIOD",
      "status": "CANCELLED",
      "layoutStartPosition": 333,
      "layoutWidth": 666,
      "layoutGroup": 1,
      "color": "bfc8cf",
      "icons": [],
      "position1": [{ "current": { "type": "TEACHER", "status": "REGULAR", "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML", "displayNameLabel": "NAME" }, "removed": null }],
      "position2": [{ "current": { "type": "SUBJECT", "status": "REGULAR", "shortName": "Kl-Essen", "longName": "Klassenessen", "displayName": "Kl-Essen", "displayNameLabel": "NAME" }, "removed": null }],
      "position3": [{ "current": { "type": "ROOM", "status": "REGULAR", "shortName": "1a5", "longName": "5d", "displayName": "1a5", "displayNameLabel": "NAME" }, "removed": null }],
      "texts": [], "lessonText": "", "lessonInfo": null, "substitutionText": ""
    }
  ],
  "backEntries": []
}
```
