# POST https://schoolsearch.webuntis.com/schoolquery2

JSON-RPC 2.0, method `searchSchool`. No authentication — this is the first call the app makes, before any
school is known.

## Example requests

By tenant ID:

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "searchSchool",
  "params": [{ "tenantid": "5237400" }]
}
```

By free-text search:

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "searchSchool",
  "params": [{ "search": "cjd" }]
}
```

## Example responses

Single match:

```json
{
  "result": {
    "size": 0,
    "schools": [
      {
        "server": "cjd-koewi.webuntis.com",
        "useMobileServiceUrlAndroid": false,
        "address": "53639, Königswinter, Cleethorpeser Platz 12",
        "displayName": "CJD Königswinter Christophorusschule",
        "loginName": "cjd-koewi",
        "schoolId": 5237400,
        "useMobileServiceUrlIos": false,
        "serverUrl": "https://cjd-koewi.webuntis.com/WebUntis/?school=cjd-koewi",
        "tenantId": "5237400",
        "mobileServiceUrl": null
      }
    ]
  },
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0"
}
```

Multiple matches (`search: "cjd"` returned 14 schools in total; truncated here to two representative entries —
`size` is always `0` regardless of actual result count, likely vestigial/unused):

```json
{
  "result": {
    "size": 0,
    "schools": [
      {
        "server": "cjd-koewi.webuntis.com",
        "useMobileServiceUrlAndroid": false,
        "address": "53639, Königswinter, Cleethorpeser Platz 12",
        "displayName": "CJD Königswinter Christophorusschule",
        "loginName": "cjd-koewi",
        "schoolId": 5237400,
        "useMobileServiceUrlIos": false,
        "serverUrl": "https://cjd-koewi.webuntis.com/WebUntis/?school=cjd-koewi",
        "tenantId": "5237400",
        "mobileServiceUrl": null
      },
      {
        "server": "cjd-frechen.webuntis.com",
        "useMobileServiceUrlAndroid": false,
        "address": "50226, Frechen, Clarenbergweg 81",
        "displayName": "CJD Jugenddorf-Christophorusschule",
        "loginName": "cjd-frechen",
        "schoolId": 6388200,
        "useMobileServiceUrlIos": false,
        "serverUrl": "https://cjd-frechen.webuntis.com/WebUntis/?school=cjd-frechen",
        "tenantId": "6388200",
        "mobileServiceUrl": null
      }
    ]
  },
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0"
}
```

No matches:

```json
{
  "result": { "size": 0, "schools": [] },
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0"
}
```

Search term too broad (observed for a 3-letter generic term):

```json
{
  "id": "untis-mobile-android-6.7.0",
  "error": { "code": -6003, "message": "too many results" },
  "jsonrpc": "2.0"
}
```
