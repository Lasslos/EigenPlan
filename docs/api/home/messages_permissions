# GET /WebUntis/api/rest/view/v1/messages/permissions

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/messages/permissions?school=cjd-koewi
```

**Auth:** Bearer token required.

What the current user is allowed to do in the messages UI — compose, reply, request read receipts, etc.

## Response

```json
{
  "recipientOptions": [],
  "allowRequestReadConfirmation": false,
  "recipientSearchMaxResult": 100,
  "showDraftsTab": false,
  "showSentTab": false,
  "canForbidReplies": false,
  "maxFileSize": 7000000,
  "maxFileCount": 5
}
```

`recipientOptions` was empty for all four captured accounts (none could compose messages) — item shape
unconfirmed. `maxFileSize`/`maxFileCount`/`recipientSearchMaxResult` imply a compose form exists even though
its request shape was never captured.
