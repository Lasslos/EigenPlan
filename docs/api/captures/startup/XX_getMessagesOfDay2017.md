# getMessagesOfDay2017

```
POST https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi&m=getMessagesOfDay2017&a=false&s=cjd-koewi.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getMessagesOfDay2017`. Distinct concept from the REST `/messages` family (see
`../home/messages.md`) — this is the older "message of the day" list, not the general inbox.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getMessagesOfDay2017",
  "params": [
    {
      "date": "2026-08-15",
      "auth": {
        "clientTime": 1786788459646,
        "otp": 730465,
        "user": "Q1"
      }
    }
  ]
}
```

## Responses

cjd-koewi — no messages for this date:

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "messages": []
  }
}
```

schuldorf — one message with two externally-hosted attachments (`id: -1` on both — likely means "no numeric
id, externally hosted" rather than a real attachment id):

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "messages": [
      {
        "id": 146,
        "subject": "Login zu WebUntis und UntisMobile",
        "body": "Hier findet ihr die Anleitung um euch bei WebUntis und UntisMobile (App) anzumelden.",
        "attachments": [
          {
            "id": -1,
            "name": "Anleitung WebUntis_SuS - Englisch.pdf",
            "url": "https://example-my.sharepoint.invalid/:b:/g/personal/redacted/redacted3"
          },
          {
            "id": -1,
            "name": "Anleitung WebUntis_SuS.pdf",
            "url": "https://example-my.sharepoint.invalid/:b:/g/personal/redacted/redacted4"
          }
        ]
      }
    ]
  }
}
```
