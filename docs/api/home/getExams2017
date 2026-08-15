# getExams2017

```
POST https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi&m=getExams2017&a=false&s=cjd-koewi.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getExams2017`.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getExams2017",
  "params": [
    {
      "endDate": "2026-08-22",
      "id": 1664,
      "startDate": "2026-08-15",
      "type": "CLASS",
      "auth": {
        "clientTime": 1786790506363,
        "otp": 63818,
        "user": "Q1"
      }
    }
  ]
}
```

## Responses

`CLASS`-scoped request:

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "type": "CLASS",
    "id": 1664,
    "exams": []
  }
}
```

`STUDENT`-scoped request:

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "type": "STUDENT",
    "id": 4379,
    "exams": []
  }
}
```

`exams` was empty in both captures — item shape unconfirmed. Needs a follow-up capture against a school with
real exam data.
