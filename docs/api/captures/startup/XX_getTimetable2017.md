# getTimetable2017

```
POST https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi&m=getTimetable2017&a=false&s=cjd-koewi.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getTimetable2017`. The legacy timetable call — still functional, but the app's own UI
now appears to prefer the newer REST timetable endpoints (`../home/timetable_grid.md`, `../home/timetable_entries.md`) for rendering. `periods` came back empty in every capture against this server generation; this
response is otherwise useful for `masterData`'s time-grid shape. See `../../spec/NOTES.md` §4.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getTimetable2017",
  "params": [
    {
      "endDate": "2026-08-15",
      "id": 1664,
      "masterDataTimestamp": 1786788455112,
      "startDate": "2026-08-15",
      "timetableTimestamp": 0,
      "timetableTimestamps": [
        0
      ],
      "type": "CLASS",
      "auth": {
        "clientTime": 1786788458176,
        "otp": 730465,
        "user": "Q1"
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
    "timetable": {
      "displayableStartDate": "2026-08-15",
      "displayableEndDate": "2026-08-15",
      "periods": []
    },
    "masterData": {
      "timeStamp": 1786788459057,
      "absenceReasons": [],
      "departments": [],
      "duties": [],
      "eventReasons": [],
      "eventReasonGroups": [],
      "excuseStatuses": [],
      "holidays": null,
      "klassen": [],
      "rooms": [],
      "subjects": [],
      "teachers": [],
      "teachingMethods": [],
      "schoolyears": [],
      "timeGrid": {
        "days": [
          {
            "day": "MON",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:55"
              },
              {
                "label": "2",
                "startTime": "T09:10",
                "endTime": "T10:10"
              },
              {
                "label": "3",
                "startTime": "T10:20",
                "endTime": "T11:20"
              },
              {
                "label": "4",
                "startTime": "T11:45",
                "endTime": "T12:45"
              },
              {
                "label": "5",
                "startTime": "T12:55",
                "endTime": "T13:55"
              },
              {
                "label": "MiPau",
                "startTime": "T13:55",
                "endTime": "T14:25"
              },
              {
                "label": "7",
                "startTime": "T14:25",
                "endTime": "T15:25"
              },
              {
                "label": "8",
                "startTime": "T15:35",
                "endTime": "T16:35"
              },
              {
                "label": "",
                "startTime": "T16:45",
                "endTime": "T19:00"
              },
              {
                "label": "",
                "startTime": "T19:00",
                "endTime": "T22:00"
              }
            ]
          },
          {
            "day": "TUE",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:55"
              },
              {
                "label": "2",
                "startTime": "T09:10",
                "endTime": "T10:10"
              },
              {
                "label": "3",
                "startTime": "T10:20",
                "endTime": "T11:20"
              },
              {
                "label": "4",
                "startTime": "T11:45",
                "endTime": "T12:45"
              },
              {
                "label": "5",
                "startTime": "T12:55",
                "endTime": "T13:55"
              },
              {
                "label": "MiPau",
                "startTime": "T13:55",
                "endTime": "T14:25"
              },
              {
                "label": "7",
                "startTime": "T14:25",
                "endTime": "T15:25"
              },
              {
                "label": "8",
                "startTime": "T15:35",
                "endTime": "T16:35"
              },
              {
                "label": "",
                "startTime": "T16:45",
                "endTime": "T19:00"
              },
              {
                "label": "",
                "startTime": "T19:00",
                "endTime": "T22:00"
              }
            ]
          },
          {
            "day": "WED",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:55"
              },
              {
                "label": "2",
                "startTime": "T09:10",
                "endTime": "T10:10"
              },
              {
                "label": "3",
                "startTime": "T10:20",
                "endTime": "T11:20"
              },
              {
                "label": "4",
                "startTime": "T11:45",
                "endTime": "T12:45"
              },
              {
                "label": "5",
                "startTime": "T12:55",
                "endTime": "T13:55"
              },
              {
                "label": "MiPau",
                "startTime": "T13:55",
                "endTime": "T14:25"
              },
              {
                "label": "7",
                "startTime": "T14:25",
                "endTime": "T15:25"
              },
              {
                "label": "8",
                "startTime": "T15:35",
                "endTime": "T16:35"
              },
              {
                "label": "",
                "startTime": "T16:45",
                "endTime": "T19:00"
              },
              {
                "label": "",
                "startTime": "T19:00",
                "endTime": "T22:00"
              }
            ]
          },
          {
            "day": "THU",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:55"
              },
              {
                "label": "2",
                "startTime": "T09:10",
                "endTime": "T10:10"
              },
              {
                "label": "3",
                "startTime": "T10:20",
                "endTime": "T11:20"
              },
              {
                "label": "4",
                "startTime": "T11:45",
                "endTime": "T12:45"
              },
              {
                "label": "5",
                "startTime": "T12:55",
                "endTime": "T13:55"
              },
              {
                "label": "MiPau",
                "startTime": "T13:55",
                "endTime": "T14:25"
              },
              {
                "label": "7",
                "startTime": "T14:25",
                "endTime": "T15:25"
              },
              {
                "label": "8",
                "startTime": "T15:35",
                "endTime": "T16:35"
              },
              {
                "label": "",
                "startTime": "T16:45",
                "endTime": "T19:00"
              },
              {
                "label": "",
                "startTime": "T19:00",
                "endTime": "T22:00"
              }
            ]
          },
          {
            "day": "FRI",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:55"
              },
              {
                "label": "2",
                "startTime": "T09:10",
                "endTime": "T10:10"
              },
              {
                "label": "3",
                "startTime": "T10:20",
                "endTime": "T11:20"
              },
              {
                "label": "4",
                "startTime": "T11:45",
                "endTime": "T12:45"
              },
              {
                "label": "5",
                "startTime": "T12:55",
                "endTime": "T13:55"
              },
              {
                "label": "MiPau",
                "startTime": "T13:55",
                "endTime": "T14:25"
              },
              {
                "label": "7",
                "startTime": "T14:25",
                "endTime": "T15:25"
              },
              {
                "label": "8",
                "startTime": "T15:35",
                "endTime": "T16:35"
              },
              {
                "label": "",
                "startTime": "T16:45",
                "endTime": "T19:00"
              },
              {
                "label": "",
                "startTime": "T19:00",
                "endTime": "T22:00"
              }
            ]
          }
        ]
      }
    }
  }
}
```
