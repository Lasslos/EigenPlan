# getUserData2017 — wolfsburger-oberschule (teacher account)

```
POST https://wolfsburger-oberschule.webuntis.com/WebUntis/jsonrpc_intern.do?school=wolfsburger-oberschule&m=getUserData2017&a=false&s=wolfsburger-oberschule.webuntis.com&v=a6.7.0
```

Request body follows the same shape as `06_cjd_getUserData.md`, with `auth.user` set to the logged-in teacher's
username. Response below — captured against a teacher account, useful for seeing role-dependent fields
(`userData.elemType: TEACHER`, `rights`) that differ from a student/class account.

## Response

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "masterData": {
      "timeStamp": 1786797145149,
      "absenceReasons": [
        {
          "id": 35,
          "name": "krank",
          "longName": "Krankmeldung durch Eltern",
          "active": true,
          "automaticNotificationEnabled": false
        },
        {
          "id": 36,
          "name": "Arzt",
          "longName": "Arztbesuch",
          "active": true,
          "automaticNotificationEnabled": false
        }
      ],
      "departments": [
        {
          "id": 2,
          "name": "BBS",
          "longName": "BBS"
        },
        {
          "id": 10,
          "name": "Schulsozialarbeit",
          "longName": "Schulsozialarbeit"
        }
      ],
      "duties": [
        {
          "id": 1,
          "name": "Ordner",
          "longName": "Klassenordner",
          "type": "STEWARD"
        },
        {
          "id": 2,
          "name": "KS",
          "longName": "Klassensprecher",
          "type": "PREFECT"
        }
      ],
      "eventReasons": [
        {
          "id": 65,
          "name": "anderer Verstoß",
          "longName": "anderer Verstoß",
          "elementType": "STUDENT",
          "groupId": 4,
          "active": true
        },
        {
          "id": 3,
          "name": "verlässt Schule",
          "longName": "verlässt Schulgelände",
          "elementType": "STUDENT",
          "groupId": 4,
          "active": true
        }
      ],
      "eventReasonGroups": [
        {
          "id": 1,
          "name": "Neu",
          "longName": "Neu",
          "active": true
        },
        {
          "id": 2,
          "name": "SV",
          "longName": "Sozialverhalten",
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
          "name": "nicht entsch.",
          "longName": "nicht entschuldigt",
          "excused": false,
          "active": true
        }
      ],
      "holidays": [
        {
          "id": 1,
          "name": "Ferien1",
          "longName": "Herbstferien",
          "startDate": "2016-10-04",
          "endDate": "2016-10-15"
        },
        {
          "id": 2,
          "name": "Ferien2",
          "longName": "Weihnachtsferien",
          "startDate": "2016-12-21",
          "endDate": "2017-01-06"
        }
      ],
      "klassen": [
        {
          "id": 1208,
          "name": "10a",
          "longName": "10a OBS",
          "departmentId": 1,
          "startDate": "2026-08-13",
          "endDate": "2027-07-07",
          "foreColor": null,
          "backColor": null,
          "active": true,
          "displayable": true
        },
        {
          "id": 1211,
          "name": "10b",
          "longName": "10b OBS",
          "departmentId": 1,
          "startDate": "2026-08-13",
          "endDate": "2027-07-07",
          "foreColor": null,
          "backColor": null,
          "active": true,
          "displayable": true
        }
      ],
      "rooms": [
        {
          "id": 66,
          "name": "?",
          "longName": "noch offen",
          "departmentId": 0,
          "foreColor": null,
          "backColor": null,
          "active": false,
          "displayAllowed": true
        },
        {
          "id": 67,
          "name": "1/2/3 OG",
          "longName": "1./2./3. OG",
          "departmentId": 0,
          "foreColor": null,
          "backColor": null,
          "active": true,
          "displayAllowed": true
        }
      ],
      "subjects": [
        {
          "id": 144,
          "name": "Abordnung",
          "longName": "Abordnung",
          "departmentIds": [],
          "foreColor": null,
          "backColor": null,
          "active": true,
          "displayAllowed": false
        },
        {
          "id": 154,
          "name": "AG",
          "longName": "AG",
          "departmentIds": [],
          "foreColor": null,
          "backColor": null,
          "active": true,
          "displayAllowed": false
        }
      ],
      "teachers": [
        {
          "id": 381,
          "name": "Musterlehrer8",
          "firstName": "",
          "lastName": "Musterlehrer8",
          "departmentIds": [],
          "foreColor": null,
          "backColor": null,
          "entryDate": null,
          "exitDate": null,
          "active": false,
          "displayAllowed": false
        },
        {
          "id": 494,
          "name": "Musterlehrer9",
          "firstName": "",
          "lastName": "Musterlehrer9",
          "departmentIds": [],
          "foreColor": null,
          "backColor": null,
          "entryDate": null,
          "exitDate": null,
          "active": false,
          "displayAllowed": false
        }
      ],
      "teachingMethods": [],
      "schoolyears": [
        {
          "id": 1,
          "name": "2016/2017",
          "startDate": "2016-08-04",
          "endDate": "2017-06-21"
        },
        {
          "id": 2,
          "name": "2017/2018",
          "startDate": "2017-08-03",
          "endDate": "2018-06-27"
        }
      ],
      "timeGrid": {
        "days": [
          {
            "day": "MON",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:40"
              },
              {
                "label": "2",
                "startTime": "T08:40",
                "endTime": "T09:25"
              }
            ]
          },
          {
            "day": "TUE",
            "units": [
              {
                "label": "1",
                "startTime": "T07:55",
                "endTime": "T08:40"
              },
              {
                "label": "2",
                "startTime": "T08:40",
                "endTime": "T09:25"
              }
            ]
          }
        ]
      }
    },
    "userData": {
      "elemType": "TEACHER",
      "elemId": 134,
      "displayName": "ML",
      "schoolName": "Wolfsburger Oberschule",
      "departmentId": 1,
      "children": [],
      "klassenIds": [
        1139
      ],
      "rights": [
        "CLASSREGISTER",
        "R_MY_ABSENCES"
      ]
    },
    "settings": {
      "showAbsenceReason": true,
      "showAbsenceText": true,
      "absenceCheckRequired": true,
      "defaultAbsenceReasonId": 47,
      "defaultLatenessReasonId": 45,
      "defaultAbsenceEndTime": "CUSTOM",
      "customAbsenceEndTime": "T15:50",
      "showCalendarDetails": false,
      "defaultAbsenceExcuseStatusId": 4
    }
  }
}
```

