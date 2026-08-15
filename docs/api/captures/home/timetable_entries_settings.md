# GET /WebUntis/api/rest/view/v1/timetable/entries/settings

```
GET https://schuldorf.webuntis.com/WebUntis/api/rest/view/v1/timetable/entries/settings?resourceType=STUDENT&school=schuldorf
```

**Auth:** Bearer token required.

Per-resource-type display settings for the timetable UI (which overlays/highlights to show). All fields are
booleans.

## Response

```json
{
  "showSymbols": true,
  "showTeacherAbsences": false,
  "showStudentAbsences": false,
  "showRoomLocks": false,
  "showResourceLocks": false,
  "showForeignSubstitutions": false,
  "showICal": false,
  "showICalExport": false,
  "showAllDropdownElements": false,
  "highlightChanges": true,
  "highlightExams": true,
  "highlightCancellations": true,
  "highlightExternalEntries": false
}
```
