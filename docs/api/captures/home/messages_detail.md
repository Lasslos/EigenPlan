# GET /WebUntis/api/rest/view/v1/messages/{messageId}

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/messages/4857?school=cjd-koewi
```

**Auth:** Bearer token required.

Full message content + attachments. Two attachment mechanisms observed, both shown below.

## Response — S3-backed attachment (`storageAttachments`)

```json
{
  "id": 4857,
  "subject": "Schulmusical - Termine nächste Woche!",
  "content": "Liebe Schulgemeinde,\nhier die Ankündigung des Schulmusicals.\n\n\nEs ist soweit. Die lange Wartezeit hat endlich ein Ende.\n\nAm 12.06 um 18:30 Uhr und am 14.06 um 16 Uhr führen wir das Musical in einer neuen Adaption unserer Musical-AG in der Aula auf.\nBeeilt euch und holt euch Tickets in den großen Pausen (oder nutzt die Abendkasse jeweils am Tag der Veranstaltung).\n\nWir freuen uns auf euch!\n\n",
  "sender": {
    "className": null,
    "displayName": "Admin_2",
    "imageUrl": null,
    "userId": 145
  },
  "sentDateTime": "2026-06-05T15:52:00",
  "allowMessageDeletion": false,
  "attachments": [],
  "blobAttachment": null,
  "storageAttachments": [
    {
      "id": "68d39a3f-7a7d-4aaa-b597-641d6cf121c1",
      "name": "Schulmusical-Plakat.pdf"
    }
  ],
  "isReply": false,
  "isReplyAllowed": false,
  "isReportMessage": false,
  "isReplyForbidden": false,
  "replyHistory": [],
  "requestConfirmation": null
}
```

`storageAttachments[].id` is passed as the `messageId` path segment of `../home/attachments.md`'s
`attachmentstorageurl` endpoint to resolve an actual download URL.

## Response — externally-hosted attachment (`attachments`)

```json
{
  "id": 11743,
  "subject": "Wintertürchen 17.12.",
  "content": "Also available in English today.",
  "sender": {
    "className": null,
    "displayName": "Musterlehrer Frank",
    "imageUrl": null,
    "userId": 49
  },
  "sentDateTime": "2025-12-17T07:11:00",
  "allowMessageDeletion": true,
  "attachments": [
    {
      "id": "0",
      "name": "17.12. eng.pdf",
      "downloadUrl": "https://example-my.sharepoint.invalid/:b:/g/personal/redacted/redacted1"
    },
    {
      "id": "0",
      "name": "17.12..pdf",
      "downloadUrl": "https://example-my.sharepoint.invalid/:b:/g/personal/redacted/redacted2"
    }
  ],
  "blobAttachment": null,
  "storageAttachments": [],
  "isReply": false,
  "isReplyAllowed": true,
  "isReportMessage": false,
  "isReplyForbidden": false,
  "replyHistory": [],
  "requestConfirmation": null
}
```

`attachments[].id` is always the literal string `"0"` for this kind of attachment — likely means "no real
numeric id, externally hosted" rather than a meaningful identifier; `downloadUrl` is directly usable, no
signed-URL dance needed. `blobAttachment` and `requestConfirmation` were `null` in every capture — shape
unconfirmed for both; `blobAttachment`'s name suggests a third, inline-base64 attachment mechanism.
