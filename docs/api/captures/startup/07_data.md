# GET /WebUntis/api/rest/view/v3/mobile/data

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v3/mobile/data?school=cjd-koewi
```

**Auth:** Bearer token required.

Tenant + logged-in-user summary, fetched right after obtaining a bearer token. Distinct payload from
`getUserData2017`'s `userData` block — see `../../spec/NOTES.md` §5 for why these probably shouldn't be merged
into one model.

## cjd-koewi

```json
{
  "schoolYear": null,
  "tenant": {
    "id": "5237400",
    "displayName": "Jugenddorf-Christophorusschule",
    "wuVersion": "2027.0.2",
    "language": "",
    "schoolLoginName": "cjd-koewi"
  },
  "user": {
    "id": 134,
    "username": "Q1",
    "person": {
      "id": 1664,
      "displayName": "Q1",
      "imageUrl": null
    },
    "referencedStudents": [],
    "locale": "de",
    "departmentId": 1,
    "role": "KLASSE",
    "permissions": [
      "READ_MESSAGES"
    ]
  }
}
```

## bs-gfv (anonymous — no logged-in user)

```json
{
  "schoolYear": null,
  "tenant": {
    "id": "3816800",
    "displayName": "Städt.BS GFV",
    "wuVersion": "2027.0.2",
    "language": "",
    "schoolLoginName": "bs-gfv"
  },
  "user": null
}
```

## schuldorf

```json
{
  "schoolYear": {
    "dateRange": {
      "start": "2026-08-10T00:00:00",
      "end": "2027-06-27T00:00:00"
    },
    "id": 21,
    "name": "2026/2027"
  },
  "tenant": {
    "id": "4738900",
    "displayName": "Gesamtschule im  Schuldorf",
    "wuVersion": "2027.0.2",
    "language": "",
    "schoolLoginName": "schuldorf"
  },
  "user": {
    "id": 24728,
    "username": "musterschueler",
    "person": {
      "id": 4379,
      "displayName": "Mustermann Max",
      "imageUrl": null
    },
    "referencedStudents": [],
    "locale": "deNG",
    "departmentId": 5,
    "role": "STUDENT",
    "permissions": [
      "READ_MESSAGES",
      "CLASS_REGISTER",
      "CHANGE_OWN_PASSWORD"
    ]
  }
}
```

## wolfsburger-oberschule (teacher account)

```json
{
  "schoolYear": {
    "dateRange": {
      "start": "2026-08-13T00:00:00",
      "end": "2027-07-07T00:00:00"
    },
    "id": 20,
    "name": "2026/2027"
  },
  "tenant": {
    "id": "6763800",
    "displayName": "Wolfsburger Oberschule",
    "wuVersion": "2027.0.2",
    "language": "",
    "schoolLoginName": "wolfsburger-oberschule"
  },
  "user": {
    "id": 1163,
    "username": "ML",
    "person": {
      "id": 134,
      "displayName": "ML",
      "imageUrl": null
    },
    "referencedStudents": [],
    "locale": "de",
    "departmentId": 1,
    "role": "TEACHER",
    "permissions": [
      "READ_MESSAGES",
      "CLASS_REGISTER",
      "CHANGE_OWN_PASSWORD"
    ]
  }
}
```
