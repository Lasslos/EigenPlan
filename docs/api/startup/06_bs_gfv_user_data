# getUserData2017 — bs-gfv (anonymous)

```
POST https://bs-gfv.webuntis.com/WebUntis/jsonrpc_intern.do?school=bs-gfv&m=getUserData2017&a=true&s=bs-gfv.webuntis.com&v=a6.7.0
```

Note the `a=true` query parameter (anonymous flag) and the `auth` object's literal `otp: 0` /
`user: "#anonymous#"` — no shared secret or TOTP is computed for this login mode.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getUserData2017",
  "params": [
    {
      "elementId": 0,
      "auth": {
        "clientTime": 1786794734914,
        "otp": 0,
        "user": "#anonymous#"
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
    "masterData": {
      "timeStamp": 1786794735495,
      "absenceReasons": [
        {
          "id": 10,
          "name": "krank",
          "longName": "Erkrankung",
          "active": true,
          "automaticNotificationEnabled": false
        },
        {
          "id": 11,
          "name": "ÜBA",
          "longName": "Überbetriebl. Ausbildung",
          "active": true,
          "automaticNotificationEnabled": false
        }
      ],
      "departments": [
        {
          "id": 26,
          "name": "BVJ",
          "longName": "BVJ"
        },
        {
          "id": 39,
          "name": "FL",
          "longName": "FL"
        }
      ],
      "duties": [
        {
          "id": 16,
          "name": "1. Ordungsdienst",
          "longName": "1. Ordnungsdienst",
          "type": "STEWARD"
        },
        {
          "id": 17,
          "name": "2. Ordnungsdienst",
          "longName": "2. Ordnungsdienst",
          "type": "STEWARD"
        }
      ],
      "eventReasons": [
        {
          "id": 1,
          "name": "Eintritt",
          "longName": "Eintritt Schule",
          "elementType": "STUDENT",
          "groupId": 4,
          "active": true
        },
        {
          "id": 20,
          "name": "Nachteilsausgleich",
          "longName": "Nachteilsausgleich (LRS etc.)",
          "elementType": "STUDENT",
          "groupId": 11,
          "active": true
        }
      ],
      "eventReasonGroups": [
        {
          "id": 4,
          "name": "Klassenzugehörigkeit",
          "longName": "Klassenzugehörigkeit",
          "active": true
        },
        {
          "id": 6,
          "name": "Verhalten",
          "longName": "Verhalten im Unterricht",
          "active": true
        }
      ],
      "excuseStatuses": [
        {
          "id": 1,
          "name": "entsch.",
          "longName": "entschuldigt",
          "excused": true,
          "active": true
        },
        {
          "id": 2,
          "name": "unentsch.",
          "longName": "unentschuldigt",
          "excused": false,
          "active": true
        }
      ],
      "holidays": null,
      "klassen": [],
      "rooms": [
        {
          "id": 78,
          "name": "K e.04",
          "longName": "Kapuzinerhölzl e.04",
          "departmentId": 0,
          "foreColor": null,
          "backColor": null,
          "active": true,
          "displayAllowed": false
        },
        {
          "id": 22,
          "name": "K e.06",
          "longName": "Kapuzinerhölzl e.06",
          "departmentId": 0,
          "foreColor": "#000000",
          "backColor": "#00ff40",
          "active": true,
          "displayAllowed": false
        }
      ],
      "subjects": [
        {
          "id": 19,
          "name": "BDV",
          "longName": "Bzh-Datenverarbeitung",
          "departmentIds": [],
          "foreColor": "#000000",
          "backColor": "#00ff00",
          "active": false,
          "displayAllowed": false
        },
        {
          "id": 90,
          "name": "BerHan",
          "longName": "Berufliche Handlungsfähigkeit",
          "departmentIds": [],
          "foreColor": "#000000",
          "backColor": "#ff8455",
          "active": true,
          "displayAllowed": false
        }
      ],
      "teachers": [],
      "teachingMethods": [],
      "schoolyears": [
        {
          "id": 12,
          "name": "2023/2024",
          "startDate": "2023-09-12",
          "endDate": "2024-07-26"
        },
        {
          "id": 15,
          "name": "2024/2025",
          "startDate": "2024-09-10",
          "endDate": "2025-07-31"
        }
      ],
      "timeGrid": {
        "days": [
          {
            "day": "MON",
            "units": [
              {
                "label": "1",
                "startTime": "T08:30",
                "endTime": "T09:15"
              },
              {
                "label": "2",
                "startTime": "T09:15",
                "endTime": "T10:00"
              }
            ]
          },
          {
            "day": "TUE",
            "units": [
              {
                "label": "1",
                "startTime": "T08:30",
                "endTime": "T09:15"
              },
              {
                "label": "2",
                "startTime": "T09:15",
                "endTime": "T10:00"
              }
            ]
          }
        ]
      }
    },
    "userData": {
      "elemType": null,
      "elemId": -1,
      "displayName": "IDC_ANONYMOUSUSER",
      "schoolName": "Städt.BS GFV",
      "departmentId": 0,
      "children": [],
      "klassenIds": [],
      "rights": []
    },
    "settings": {
      "showAbsenceReason": true,
      "showAbsenceText": true,
      "absenceCheckRequired": true,
      "defaultAbsenceReasonId": 15,
      "defaultLatenessReasonId": 15,
      "defaultAbsenceEndTime": "END_OF_DAY",
      "customAbsenceEndTime": null,
      "showCalendarDetails": false,
      "defaultAbsenceExcuseStatusId": 2
    }
  }
}
```

Note `userData.elemId` is `-1` and `displayName` is the literal string `IDC_ANONYMOUSUSER` — this looks like
an untranslated i18n key, not a real display name, and is the steady-state shape for this school's login mode
(not an edge case).

