# GET /WebUntis/api/rest/view/v1/timetable/grid

```
GET https://schuldorf.webuntis.com/WebUntis/api/rest/view/v1/timetable/grid?extendForEdgeBreakSupervisions=true&school=schuldorf
```

**Auth:** Bearer token required.

Timetable grid layout metadata: weekday/period-slot geometry, and the named display-format presets a school
can define (e.g. a lesson-numbered grid vs. a wall-clock-hours grid). Independent of any specific resource —
fetch once and cache, then combine with `timetable entries` for actual data.

## Response — schuldorf

```json
{
  "firstDayOfWeek": "MO",
  "studentFormat": 1,
  "classFormat": 1,
  "subjectFormat": 1,
  "teacherFormat": 1,
  "roomFormat": 1,
  "resourceFormat": -1,
  "formatDefinitions": [
    {
      "id": 0,
      "name": "default",
      "longname": "default",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": false,
      "showCancellations": true,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 4,
      "duration": {
        "start": "07:30",
        "end": "19:00"
      },
      "timeGridType": "LESSON_GRID",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": [
        {
          "name": "",
          "number": 1,
          "duration": {
            "start": "07:30",
            "end": "08:00"
          }
        },
        {
          "name": "",
          "number": 2,
          "duration": {
            "start": "08:00",
            "end": "08:45"
          }
        },
        {
          "name": "",
          "number": 3,
          "duration": {
            "start": "08:50",
            "end": "09:35"
          }
        },
        {
          "name": "",
          "number": 4,
          "duration": {
            "start": "09:50",
            "end": "10:35"
          }
        },
        {
          "name": "",
          "number": 5,
          "duration": {
            "start": "10:35",
            "end": "11:20"
          }
        },
        {
          "name": "",
          "number": 6,
          "duration": {
            "start": "11:40",
            "end": "12:25"
          }
        },
        {
          "name": "",
          "number": 7,
          "duration": {
            "start": "12:30",
            "end": "13:15"
          }
        },
        {
          "name": "",
          "number": 8,
          "duration": {
            "start": "13:20",
            "end": "14:05"
          }
        },
        {
          "name": "",
          "number": 9,
          "duration": {
            "start": "14:10",
            "end": "14:55"
          }
        },
        {
          "name": "",
          "number": 10,
          "duration": {
            "start": "15:00",
            "end": "15:45"
          }
        },
        {
          "name": "",
          "number": 11,
          "duration": {
            "start": "15:55",
            "end": "16:40"
          }
        },
        {
          "name": "",
          "number": 12,
          "duration": {
            "start": "16:40",
            "end": "17:25"
          }
        },
        {
          "name": "",
          "number": 13,
          "duration": {
            "start": "17:30",
            "end": "18:15"
          }
        },
        {
          "name": "",
          "number": 14,
          "duration": {
            "start": "18:15",
            "end": "19:00"
          }
        },
        {
          "name": "",
          "number": 15,
          "duration": {
            "start": "19:00",
            "end": "19:45"
          }
        }
      ]
    },
    {
      "id": 14,
      "name": "Schüler(Test)",
      "longname": "Schüler(Test)",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": false,
      "showCancellations": false,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 4,
      "duration": {
        "start": "08:00",
        "end": "19:45"
      },
      "timeGridType": "CLOCK_HOURS",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": []
    },
    {
      "id": 1,
      "name": "default",
      "longname": "default",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": true,
      "showCancellations": true,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 4,
      "duration": {
        "start": "07:30",
        "end": "18:15"
      },
      "timeGridType": "LESSON_GRID",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": [
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "07:30",
            "end": "08:00"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "08:00",
            "end": "08:45"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "08:50",
            "end": "09:35"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "09:50",
            "end": "10:35"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "10:35",
            "end": "11:20"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "11:40",
            "end": "12:25"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "12:30",
            "end": "13:15"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "13:20",
            "end": "14:05"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "14:10",
            "end": "14:55"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "15:00",
            "end": "15:45"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "15:55",
            "end": "16:40"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "16:40",
            "end": "17:25"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "17:30",
            "end": "18:15"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "18:15",
            "end": "19:00"
          }
        },
        {
          "name": "",
          "number": null,
          "duration": {
            "start": "19:00",
            "end": "19:45"
          }
        }
      ]
    },
    {
      "id": -1,
      "name": "RESOURCE_TIMETABLE_DEFAULT",
      "longname": "RESOURCE_TIMETABLE_DEFAULT",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": false,
      "showCancellations": true,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 1,
      "duration": {
        "start": "07:30",
        "end": "19:45"
      },
      "timeGridType": "LESSON_GRID",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": [
        {
          "name": "",
          "number": 1,
          "duration": {
            "start": "07:30",
            "end": "08:00"
          }
        },
        {
          "name": "",
          "number": 2,
          "duration": {
            "start": "08:00",
            "end": "08:45"
          }
        },
        {
          "name": "",
          "number": 3,
          "duration": {
            "start": "08:50",
            "end": "09:35"
          }
        },
        {
          "name": "",
          "number": 4,
          "duration": {
            "start": "09:50",
            "end": "10:35"
          }
        },
        {
          "name": "",
          "number": 5,
          "duration": {
            "start": "10:35",
            "end": "11:20"
          }
        },
        {
          "name": "",
          "number": 6,
          "duration": {
            "start": "11:40",
            "end": "12:25"
          }
        },
        {
          "name": "",
          "number": 7,
          "duration": {
            "start": "12:30",
            "end": "13:15"
          }
        },
        {
          "name": "",
          "number": 8,
          "duration": {
            "start": "13:20",
            "end": "14:05"
          }
        },
        {
          "name": "",
          "number": 9,
          "duration": {
            "start": "14:10",
            "end": "14:55"
          }
        },
        {
          "name": "",
          "number": 10,
          "duration": {
            "start": "15:00",
            "end": "15:45"
          }
        },
        {
          "name": "",
          "number": 11,
          "duration": {
            "start": "15:55",
            "end": "16:40"
          }
        },
        {
          "name": "",
          "number": 12,
          "duration": {
            "start": "16:40",
            "end": "17:25"
          }
        },
        {
          "name": "",
          "number": 13,
          "duration": {
            "start": "17:30",
            "end": "18:15"
          }
        },
        {
          "name": "",
          "number": 14,
          "duration": {
            "start": "18:15",
            "end": "19:00"
          }
        },
        {
          "name": "",
          "number": 15,
          "duration": {
            "start": "19:00",
            "end": "19:45"
          }
        }
      ]
    }
  ]
}
```

## Response — wolfsburger-oberschule

```json
{
  "firstDayOfWeek": "MO",
  "studentFormat": 1,
  "classFormat": 1,
  "subjectFormat": 1,
  "teacherFormat": 1,
  "roomFormat": 1,
  "resourceFormat": -1,
  "formatDefinitions": [
    {
      "id": 0,
      "name": "default",
      "longname": "default",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": false,
      "showCancellations": true,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 4,
      "duration": {
        "start": "07:45",
        "end": "18:15"
      },
      "timeGridType": "LESSON_GRID",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": [
        {
          "name": "1",
          "number": 1,
          "duration": {
            "start": "07:55",
            "end": "08:40"
          }
        },
        {
          "name": "2",
          "number": 2,
          "duration": {
            "start": "08:40",
            "end": "09:25"
          }
        },
        {
          "name": "3",
          "number": 3,
          "duration": {
            "start": "09:45",
            "end": "10:30"
          }
        },
        {
          "name": "4",
          "number": 4,
          "duration": {
            "start": "10:30",
            "end": "11:15"
          }
        },
        {
          "name": "5",
          "number": 5,
          "duration": {
            "start": "11:35",
            "end": "12:20"
          }
        },
        {
          "name": "6",
          "number": 6,
          "duration": {
            "start": "12:25",
            "end": "13:10"
          }
        },
        {
          "name": "7",
          "number": 7,
          "duration": {
            "start": "13:15",
            "end": "14:05"
          }
        },
        {
          "name": "8",
          "number": 8,
          "duration": {
            "start": "14:05",
            "end": "14:50"
          }
        },
        {
          "name": "9",
          "number": 9,
          "duration": {
            "start": "14:50",
            "end": "15:35"
          }
        }
      ]
    },
    {
      "id": 1,
      "name": "default",
      "longname": "default",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": false,
      "showCancellations": true,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 4,
      "duration": {
        "start": "07:40",
        "end": "18:15"
      },
      "timeGridType": "LESSON_GRID",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": [
        {
          "name": null,
          "number": 1,
          "duration": {
            "start": "07:55",
            "end": "08:40"
          }
        },
        {
          "name": null,
          "number": 2,
          "duration": {
            "start": "08:40",
            "end": "09:25"
          }
        },
        {
          "name": null,
          "number": 3,
          "duration": {
            "start": "09:45",
            "end": "10:30"
          }
        },
        {
          "name": null,
          "number": 4,
          "duration": {
            "start": "10:30",
            "end": "11:15"
          }
        },
        {
          "name": null,
          "number": 5,
          "duration": {
            "start": "11:35",
            "end": "12:20"
          }
        },
        {
          "name": null,
          "number": 6,
          "duration": {
            "start": "12:25",
            "end": "13:10"
          }
        },
        {
          "name": null,
          "number": 7,
          "duration": {
            "start": "13:15",
            "end": "14:05"
          }
        },
        {
          "name": null,
          "number": 8,
          "duration": {
            "start": "14:05",
            "end": "14:50"
          }
        },
        {
          "name": null,
          "number": 9,
          "duration": {
            "start": "14:50",
            "end": "15:35"
          }
        }
      ]
    },
    {
      "id": -1,
      "name": "RESOURCE_TIMETABLE_DEFAULT",
      "longname": "RESOURCE_TIMETABLE_DEFAULT",
      "showStartEndTimeOfSlots": true,
      "showStartEndTime": false,
      "showCancellations": true,
      "showExternalCalendars": true,
      "hideDetails": false,
      "minRows": 1,
      "duration": {
        "start": "07:55",
        "end": "15:35"
      },
      "timeGridType": "LESSON_GRID",
      "timeGridDays": [
        "MO",
        "TU",
        "WE",
        "TH",
        "FR"
      ],
      "timeGridSlots": [
        {
          "name": "1",
          "number": 1,
          "duration": {
            "start": "07:55",
            "end": "08:40"
          }
        },
        {
          "name": "2",
          "number": 2,
          "duration": {
            "start": "08:40",
            "end": "09:25"
          }
        },
        {
          "name": "3",
          "number": 3,
          "duration": {
            "start": "09:45",
            "end": "10:30"
          }
        },
        {
          "name": "4",
          "number": 4,
          "duration": {
            "start": "10:30",
            "end": "11:15"
          }
        },
        {
          "name": "5",
          "number": 5,
          "duration": {
            "start": "11:35",
            "end": "12:20"
          }
        },
        {
          "name": "6",
          "number": 6,
          "duration": {
            "start": "12:25",
            "end": "13:10"
          }
        },
        {
          "name": "7",
          "number": 7,
          "duration": {
            "start": "13:15",
            "end": "14:05"
          }
        },
        {
          "name": "8",
          "number": 8,
          "duration": {
            "start": "14:05",
            "end": "14:50"
          }
        },
        {
          "name": "9",
          "number": 9,
          "duration": {
            "start": "14:50",
            "end": "15:35"
          }
        }
      ]
    }
  ]
}
```

Note `duration.start`/`end` here use plain `"HH:mm"` (no `T` prefix), unlike the legacy `getUserData2017`
time-grid's `T`-prefixed times (e.g. `T07:55`) — the two are not the same format.


