# GET /WebUntis/api/rest/view/v1/schoolyears

```
GET https://wolfsburger-oberschule.webuntis.com/WebUntis/api/rest/view/v1/schoolyears?school=wolfsburger-oberschule
```

**Auth:** Bearer token. Anonymous-header support **UNKNOWN** — not yet probed against an anonymous
account with real timetable access.

Not documented in this repo prior to this capture (distinct from the legacy `getUserData2017`'s
`masterData.schoolyears`, tracked as a known gap in `test/live/known_gaps.dart`). Returns every school
year the school has on record, most recent first — not scoped to "current" or to any particular resource.
Live-probed 2026-08 against `wolfsburger-oberschule` (TEACHER account): 11 years, 2016/2017 through
2026/2027.

## Response (200)

```json
[
  { "id": 20, "name": "2026/2027", "dateRange": { "start": "2026-08-13", "end": "2027-07-07" } },
  { "id": 17, "name": "2025/2026", "dateRange": { "start": "2025-08-14", "end": "2026-07-01" } },
  { "id": 15, "name": "2024/2025", "dateRange": { "start": "2024-08-05", "end": "2025-07-02" } }
]
```

(remaining 8 entries follow the same shape, one per school year back to 2016/2017 — omitted here, no new
structure).

Flat array, no wrapper object. `id`/`name` match `getUserData2017`'s legacy `masterData.schoolyears` shape
1:1 as far as field names go (unconfirmed whether the `id` values are actually the same numbering scheme
between the legacy RPC and this REST endpoint — not cross-checked). Nothing in `timetable/entries`'s
confirmed query params (`start`/`end`/`format`/`resourceType`/`resources`/`periodTypes`/`layout`/`school`)
references a school-year id at all, so this endpoint's relationship to the timetable resource-picker flow
is **UNKNOWN** — it was called in the same click sequence the resource-picker was reverse-engineered from,
but nothing observed here ties it back to `timetable/menu`/`timetable/filter`/`timetable/entries`. Likely
just populates a separate "school year" settings/archive screen, not part of the picker itself.
