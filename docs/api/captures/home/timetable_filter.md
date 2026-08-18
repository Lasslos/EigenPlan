# GET /WebUntis/api/rest/view/v1/timetable/filter

```
GET https://wolfsburger-oberschule.webuntis.com/WebUntis/api/rest/view/v1/timetable/filter?resourceType=CLASS&includePublicTimetables=true&school=wolfsburger-oberschule
```

**Auth:** Bearer token, or `anonymous-school-base64` — **confirmed live (2026-08 probe against `bs-gfv`),
but partial, not blanket**: `resourceType=CLASS` gets a normal 200 with the anonymous header;
`STUDENT`/`TEACHER`/`ROOM` get `403 Forbidden` on the exact same session. A narrower authorization
boundary than `timetable/menu`'s (which accepts the header regardless, since it has no `resourceType`
param at all). See `../../spec/NOTES.md` §2b/§4b.

Not documented in this repo prior to this capture — the searchable directory of resources for a given
`resourceType`, used by the "switch timetable" picker's search UI once the user picks a resourceType tab
(populated from `timetable/menu`'s `availableTimetables`). One unified response shape is returned
regardless of `resourceType` requested — only the array matching the requested type is populated, the
rest come back empty. Live-probed 2026-08 against `wolfsburger-oberschule` (TEACHER account) for all four
known `ResourceType` values.

`includePublicTimetables=true` was sent on every request in the original app capture this endpoint was
discovered from; its effect is **UNKNOWN** — not isolated against a request with it omitted or `false`,
so it's unconfirmed whether it's what exposes resources beyond what the account could otherwise see (this
bears on the anonymous-access open question in `../../spec/NOTES.md` §2b/§3 — worth a follow-up capture
comparing `true` vs. omitted before relying on it for an anonymous "browse without logging in" feature).

## Response shape (all four `resourceType` values, wolfsburger-oberschule TEACHER account)

Top-level object, same for every `resourceType`:

```json
{
  "resourceType": "CLASS",
  "preSelected": { "id": 1139, "shortName": "5d", "longName": "5d OBS", "displayName": "5d" },
  "buildings": [],
  "departments": [],
  "roomGroups": [],
  "resourceTypes": [],
  "assignmentGroups": [],
  "classes": [ /* only for CLASS/STUDENT, see below */ ],
  "resources": [],
  "rooms": [ /* only for ROOM, see below */ ],
  "subjects": [],
  "students": [ /* only for STUDENT, see below */ ],
  "teachers": [ /* only for TEACHER, see below */ ]
}
```

- `preSelected`: the resource that would be highlighted/pre-selected by default for this `resourceType` —
  `null` for `STUDENT`/`ROOM` (no default), the caller's own class-ish default otherwise. For
  `resourceType=TEACHER` it was the caller's own teacher resource (`id: 134`, same as `timetable/menu`'s
  `myTimetable.resource`).
- `buildings`/`departments`/`roomGroups`/`resourceTypes`/`assignmentGroups`/`resources`/`subjects`: always
  empty in every capture so far — presumably populated for schools that use those groupings (a school
  with multiple buildings, department-scoped rooms, etc.); shape **UNKNOWN**.

### `resourceType=CLASS` and `resourceType=STUDENT` — `classes[]`

Both requested types return the **same** populated `classes[]` array (the full list of the school's
classes) — `STUDENT` additionally populates `students[]` (see below), `CLASS` does not.

```json
{
  "class": { "id": 1208, "shortName": "10a", "longName": "10a OBS", "displayName": "10a" },
  "classTeacher1": { "id": 98, "shortName": "ML1", "longName": "Musterlehrer1", "displayName": "ML1" },
  "classTeacher2": null,
  "department": { "id": 1, "shortName": "WOBS", "longName": "WOBS", "displayName": "WOBS" }
}
```

`class` matches the same `TimetableResource` shape (`id`/`shortName`/`longName`/`displayName`) used
throughout `timetable/entries` and `timetable/menu`. `classTeacher1`/`classTeacher2` are `null` when
unset (observed for most classes). `department` is also `null` for some classes on the full
(unfiltered) list — every class in the small sample shown above happened to have one, but the live
coverage test (`test/live/api_coverage_live_test.dart`) hit a `null` department requesting the full
list, so the model treats it as nullable.

### `resourceType=STUDENT` — `students[]`

In addition to `classes[]` above, populates a full per-student directory (this school: several hundred
entries — every enrolled student, not scoped to the caller's own classes):

```json
{
  "student": { "id": 6542, "shortName": "MusterschuelerA", "longName": "Musterschüler A", "displayName": "Musterschüler A" },
  "classes": [
    {
      "class": { "id": 1145, "shortName": "6a", "longName": "6a OBS", "displayName": "6a" },
      "dateRange": { "start": "2026-08-13", "end": "2027-07-07" },
      "department": { "id": 1, "shortName": "WOBS", "longName": "WOBS", "displayName": "WOBS" }
    }
  ],
  "assignmentGroups": [],
  "imageUrl": null
}
```

`student.shortName`/`longName`/`displayName` carry the real student's name — **genuine PII**, redacted
above. `classes[]` is the student's own class membership history (a student can have more than one entry
if they changed classes mid-year, per `dateRange`); `imageUrl` was `null` for every student observed
(presumably a profile photo URL when set).

### `resourceType=TEACHER` — `teachers[]`

```json
{
  "teacher": { "id": 134, "shortName": "ML", "longName": "Musterlehrer", "displayName": "ML" },
  "departments": [ { "id": 1, "shortName": "WOBS", "longName": "WOBS", "displayName": "WOBS" } ],
  "imageUrl": null
}
```

### `resourceType=ROOM` — `rooms[]`

```json
{
  "room": { "id": 1, "shortName": "1a3", "longName": "5b", "displayName": "1a3" },
  "capacity": 0,
  "roomGroups": [],
  "building": null,
  "department": null
}
```

`capacity` was `0` for every room observed — **UNKNOWN** whether that's a real "no capacity set" default
or this field was never actually populated for this school. `building`/`department` were `null` for every
room observed (this school has no multi-building/department room grouping configured).
