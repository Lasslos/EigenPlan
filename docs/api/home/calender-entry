# GET /WebUntis/api/rest/view/v2/calendar-entry/detail

```
GET https://schuldorf.webuntis.com/WebUntis/api/rest/view/v2/calendar-entry/detail?elementType=5&elementId=4379&startDateTime=2026-08-19T09%3A50%3A00&endDateTime=2026-08-19T11%3A20%3A00&school=schuldorf
```

**Auth:** Bearer token required.

Full detail of one or more calendar entries (a period, exam, event, ...) by element + time range. Used for the
"tap a period to see detail" drill-down. `elementType=5` (STUDENT) is the only value observed; the full
integer-enum mapping is unconfirmed.

## Response — schuldorf (student)

```json
{
  "calendarEntries": [
    {
      "id": 6503423,
      "previousId": 6503426,
      "nextId": null,
      "absenceReasonId": null,
      "booking": null,
      "color": null,
      "endDateTime": "2026-08-19T11:20:00",
      "exam": null,
      "homeworks": [],
      "klasses": [
        {
          "displayName": "10cGym",
          "hasTimetable": true,
          "id": 4434,
          "longName": "10cGym",
          "shortName": "10cGym"
        }
      ],
      "lesson": {
        "lessonId": 125236,
        "lessonNumber": 21300
      },
      "lessonInfo": null,
      "mainStudentGroup": null,
      "notesAll": null,
      "notesAllFiles": [],
      "notesStaff": null,
      "notesStaffFiles": [],
      "originalCalendarEntry": null,
      "permissions": [
        "READ_HOMEWORK"
      ],
      "resources": [],
      "rooms": [
        {
          "displayName": "14-10",
          "hasTimetable": false,
          "id": 75,
          "longName": "14-10",
          "shortName": "14-10",
          "status": "REGULAR"
        }
      ],
      "singleEntries": [
        {
          "id": 6503423,
          "previousId": 6503426,
          "nextId": null,
          "createdAt": null,
          "endDateTime": "2026-08-19T10:35:00",
          "lastUpdate": null,
          "permissions": [
            "READ_HOMEWORK"
          ],
          "startDateTime": "2026-08-19T09:50:00",
          "teachingContent": null,
          "teachingContentFiles": [],
          "integrationsSection": []
        },
        {
          "id": 6503426,
          "previousId": 6503420,
          "nextId": 6503423,
          "createdAt": null,
          "endDateTime": "2026-08-19T11:20:00",
          "lastUpdate": null,
          "permissions": [
            "READ_HOMEWORK"
          ],
          "startDateTime": "2026-08-19T10:35:00",
          "teachingContent": null,
          "teachingContentFiles": [],
          "integrationsSection": []
        }
      ],
      "startDateTime": "2026-08-19T09:50:00",
      "status": "TAKING_PLACE",
      "students": [],
      "subType": {
        "displayInPeriodDetails": false,
        "displayName": "Unterricht",
        "id": 1
      },
      "subject": {
        "displayName": "D",
        "hasTimetable": false,
        "id": 31,
        "longName": "Deutsch",
        "shortName": "D"
      },
      "substText": null,
      "teachers": [
        {
          "displayName": "Musterlehrerin Anna",
          "hasTimetable": false,
          "id": 140,
          "longName": "Musterlehrerin",
          "shortName": "MusA",
          "status": "REGULAR",
          "imageUrl": null
        }
      ],
      "teachingContent": null,
      "teachingContentFiles": [],
      "type": "NORMAL_TEACHING_PERIOD",
      "videoCall": null,
      "integrationsSection": []
    }
  ]
}
```

## Response — wolfsburger-oberschule (teacher)

```json
{
  "calendarEntries": [
    {
      "id": 2654843,
      "previousId": null,
      "nextId": null,
      "absenceReasonId": null,
      "booking": null,
      "color": null,
      "endDateTime": "2026-08-18T13:10:00",
      "exam": null,
      "homeworks": [],
      "klasses": [
        {
          "displayName": "5d",
          "hasTimetable": true,
          "id": 1139,
          "longName": "5d OBS",
          "shortName": "5d"
        }
      ],
      "lesson": {
        "lessonId": 100654,
        "lessonNumber": 8096
      },
      "lessonInfo": "KL-Unterricht",
      "mainStudentGroup": null,
      "notesAll": null,
      "notesAllFiles": [],
      "notesStaff": null,
      "notesStaffFiles": [],
      "originalCalendarEntry": null,
      "permissions": [
        "WRITE_NOTES_STAFF",
        "WRITE_NOTES_ALL"
      ],
      "resources": [],
      "rooms": [
        {
          "displayName": "1a5",
          "hasTimetable": true,
          "id": 3,
          "longName": "5d",
          "shortName": "1a5",
          "status": "SUBSTITUTION"
        }
      ],
      "singleEntries": [],
      "startDateTime": "2026-08-18T07:55:00",
      "status": "SUBSTITUTION",
      "students": [],
      "subType": {
        "displayInPeriodDetails": false,
        "displayName": "Unterricht",
        "id": 1
      },
      "subject": null,
      "substText": null,
      "teachers": [
        {
          "displayName": "ML",
          "hasTimetable": true,
          "id": 134,
          "longName": "Musterlehrer",
          "shortName": "ML",
          "status": "REGULAR",
          "imageUrl": null
        },
        {
          "displayName": "ML2",
          "hasTimetable": false,
          "id": 514,
          "longName": "Musterlehrer2",
          "shortName": "ML2",
          "status": "REGULAR",
          "imageUrl": null
        }
      ],
      "teachingContent": null,
      "teachingContentFiles": [],
      "type": "EVENT",
      "videoCall": null,
      "integrationsSection": [
        {
          "id": 28,
          "name": "Messenger",
          "url": "https://eassistent.at/mobileapp?tenant_id=6763800&school=wolfsburger-oberschule&lesson_id=100654&period_id=2654843&classes=5d%20OBS&subjects=&start=2026-08-18T07:55:00&end=2026-08-18T13:10:00",
          "iconName": "pa-eassistent-logo",
          "type": "APP",
          "appId": "com.eassistent.untis",
          "hideBrowserControls": true,
          "reloadDetailsOnResume": false
        }
      ]
    },
    {
      "id": 2499695,
      "previousId": null,
      "nextId": 2499698,
      "absenceReasonId": null,
      "booking": null,
      "color": "2feecb",
      "endDateTime": "2026-08-18T09:25:00",
      "exam": null,
      "homeworks": [],
      "klasses": [
        {
          "displayName": "7d",
          "hasTimetable": true,
          "id": 1169,
          "longName": "7d OBS",
          "shortName": "7d"
        }
      ],
      "lesson": {
        "lessonId": 98571,
        "lessonNumber": 122600
      },
      "lessonInfo": null,
      "mainStudentGroup": {
        "id": 55207,
        "name": "Te_7d_ML"
      },
      "notesAll": null,
      "notesAllFiles": [],
      "notesStaff": null,
      "notesStaffFiles": [],
      "originalCalendarEntry": null,
      "permissions": [
        "WRITE_NOTES_STAFF",
        "WRITE_NOTES_ALL"
      ],
      "resources": [],
      "rooms": [
        {
          "displayName": "1W13",
          "hasTimetable": true,
          "id": 25,
          "longName": "Technikraum",
          "shortName": "1W13",
          "status": "REGULAR"
        }
      ],
      "singleEntries": [
        {
          "id": 2499695,
          "previousId": null,
          "nextId": 2499698,
          "createdAt": null,
          "endDateTime": "2026-08-18T08:40:00",
          "lastUpdate": null,
          "permissions": [
            "WRITE_NOTES_STAFF",
            "WRITE_NOTES_ALL"
          ],
          "startDateTime": "2026-08-18T07:55:00",
          "teachingContent": null,
          "teachingContentFiles": [],
          "integrationsSection": [
            {
              "id": 28,
              "name": "Messenger",
              "url": "https://eassistent.at/mobileapp?tenant_id=6763800&school=wolfsburger-oberschule&lesson_id=98571&period_id=2499695&classes=7d%20OBS&subjects=Technik&start=2026-08-18T07:55:00&end=2026-08-18T08:40:00",
              "iconName": "pa-eassistent-logo",
              "type": "APP",
              "appId": "com.eassistent.untis",
              "hideBrowserControls": true,
              "reloadDetailsOnResume": false
            }
          ]
        },
        {
          "id": 2499698,
          "previousId": 2499695,
          "nextId": 2499701,
          "createdAt": null,
          "endDateTime": "2026-08-18T09:25:00",
          "lastUpdate": null,
          "permissions": [
            "WRITE_NOTES_STAFF",
            "WRITE_NOTES_ALL"
          ],
          "startDateTime": "2026-08-18T08:40:00",
          "teachingContent": null,
          "teachingContentFiles": [],
          "integrationsSection": [
            {
              "id": 28,
              "name": "Messenger",
              "url": "https://eassistent.at/mobileapp?tenant_id=6763800&school=wolfsburger-oberschule&lesson_id=98571&period_id=2499698&classes=7d%20OBS&subjects=Technik&start=2026-08-18T08:40:00&end=2026-08-18T09:25:00",
              "iconName": "pa-eassistent-logo",
              "type": "APP",
              "appId": "com.eassistent.untis",
              "hideBrowserControls": true,
              "reloadDetailsOnResume": false
            }
          ]
        }
      ],
      "startDateTime": "2026-08-18T07:55:00",
      "status": "CANCELLED",
      "students": [],
      "subType": {
        "displayInPeriodDetails": false,
        "displayName": "Unterricht",
        "id": 1
      },
      "subject": {
        "displayName": "Te",
        "hasTimetable": false,
        "id": 18,
        "longName": "Technik",
        "shortName": "Te"
      },
      "substText": null,
      "teachers": [
        {
          "displayName": "ML",
          "hasTimetable": true,
          "id": 134,
          "longName": "Musterlehrer",
          "shortName": "ML",
          "status": "REGULAR",
          "imageUrl": null
        }
      ],
      "teachingContent": null,
      "teachingContentFiles": [],
      "type": "NORMAL_TEACHING_PERIOD",
      "videoCall": null,
      "integrationsSection": [
        {
          "id": 28,
          "name": "Messenger",
          "url": "https://eassistent.at/mobileapp?tenant_id=6763800&school=wolfsburger-oberschule&lesson_id=98571&period_id=2499695&classes=7d%20OBS&subjects=Technik&start=2026-08-18T07:55:00&end=2026-08-18T08:40:00&block=true",
          "iconName": "pa-eassistent-logo",
          "type": "APP",
          "appId": "com.eassistent.untis",
          "hideBrowserControls": true,
          "reloadDetailsOnResume": false
        }
      ]
    }
  ]
}
```

Note the second entry's `mainStudentGroup.name` (`Te_7d_ML`) embeds the teacher's short code in a
compound group identifier — worth keeping in mind if generating display names from group identifiers.
