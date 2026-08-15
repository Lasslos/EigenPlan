# getPeriodData2017

```
POST https://schuldorf.webuntis.com/WebUntis/jsonrpc_intern.do?school=schuldorf&v=a6.7.0
```

JSON-RPC 2.0, method `getPeriodData2017`. Note this call's URL omits the `m=`/`a=`/`s=` query parameters that
every other JSON-RPC call in this capture set includes — the method name is only present in the body here.
Resolves per-period detail (homework, notes, attendance permissions) for one or more `ttId`s, e.g. from a
`timetable/grid` cell's `ids[]` or a `calendar-entry/detail` `singleEntries[].id`.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getPeriodData2017",
  "params": [
    {
      "ttIds": [6503426, 6503423],
      "auth": {
        "clientTime": 1786796831617,
        "otp": 894103,
        "user": "musterschueler"
      }
    }
  ]
}
```

## Response

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "referencedStudents": [],
    "dataByTTId": {
      "6503426": {
        "ttId": 6503426,
        "absenceChecked": false,
        "studentIds": null,
        "absences": null,
        "classRegEvents": null,
        "exemptions": null,
        "prioritizedAttendances": null,
        "text": null,
        "topic": null,
        "homeWorks": [],
        "seatingPlan": null,
        "classRoles": null,
        "can": ["READ_HOMEWORK", "READ_PERIODINFO"],
        "studentAssignments": null
      },
      "6503423": {
        "ttId": 6503423,
        "absenceChecked": false,
        "studentIds": null,
        "absences": null,
        "classRegEvents": null,
        "exemptions": null,
        "prioritizedAttendances": null,
        "text": null,
        "topic": null,
        "homeWorks": [],
        "seatingPlan": null,
        "classRoles": null,
        "can": ["READ_HOMEWORK", "READ_PERIODINFO"],
        "studentAssignments": null
      }
    }
  }
}
```

`dataByTTId` is a map keyed by `ttId` (as a string). Several fields (`absences`, `classRegEvents`,
`exemptions`, `prioritizedAttendances`, `seatingPlan`, `classRoles`, `studentAssignments`) were `null` in every
capture — shape unconfirmed for any of them.
