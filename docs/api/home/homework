# getHomeWork2017

```
POST https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi&m=getHomeWork2017&a=false&s=cjd-koewi.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getHomeWork2017`.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getHomeWork2017",
  "params": [
    {
      "endDate": "2026-08-22",
      "id": 1664,
      "startDate": "2026-08-15",
      "type": "CLASS",
      "auth": {
        "clientTime": 1786790507388,
        "otp": 63818,
        "user": "Q1"
      }
    }
  ]
}
```

## Responses

No homework in range:

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "homeWorks": [],
    "lessonsById": {}
  }
}
```

Homework present:

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "homeWorks": [
      {
        "id": 30982,
        "lessonId": 126867,
        "startDate": "2026-08-11",
        "endDate": "2026-08-18",
        "text": "Testfragen S.185 beantwortet:\nNr.1; Nr.2 (1 von 2)\nNr.3\nNr.4; Nr.5 ; Nr.6 (1 von 3)\nNr.7\nNr.8; Nr.9",
        "remark": null,
        "completed": false,
        "attachments": []
      },
      {
        "id": 31093,
        "lessonId": 128361,
        "startDate": "2026-08-13",
        "endDate": "2026-08-20",
        "text": "Materialien mitbringen",
        "remark": null,
        "completed": false,
        "attachments": []
      },
      {
        "id": 31207,
        "lessonId": 124884,
        "startDate": "2026-08-14",
        "endDate": "2026-08-21",
        "text": "Beendet die Tabelle über Bestandteile des Auges und deren Funktion",
        "remark": null,
        "completed": false,
        "attachments": []
      }
    ],
    "lessonsById": {
      "126867": { "id": 126867, "subjectId": 175, "klassenIds": [4434], "teacherIds": [694] },
      "124884": { "id": 124884, "subjectId": 10, "klassenIds": [4434], "teacherIds": [1100] },
      "128361": { "id": 128361, "subjectId": 651, "klassenIds": [4416, 4434], "teacherIds": [103] }
    }
  }
}
```

`lessonsById` is a map keyed by `lessonId` (as a string), letting `homeWorks[].lessonId` be resolved to
subject/klasse/teacher IDs without a separate lookup call.
