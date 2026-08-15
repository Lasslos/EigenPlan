# GET /WebUntis/api/rest/view/v1/messages

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/messages?school=cjd-koewi
```

**Auth:** Bearer token required.

Lists inbox messages (subject + preview, not full content — see `messages_detail` for that).

## Response

```json
{
  "incomingMessages": [
    {
      "id": 4890,
      "subject": "Gottesdienst-Erinnerung: Jg. 10 Gym/RS, EF, Q1 am 10.06.2026, 2. Std",
      "contentPreview": "Liebe Schüler:innen, am Mittwoch, den 10.06.2026 findet in der 2. Stunde unser letzter Gottesdienst in diesem Schuljahr statt. Wenn ihr Sport habt, trefft ihr euch mit einer Lehrperson vor der Kirche, geht zusammen in die Kirche und stellt eure Taschen und Rucksäcke an der Fensterwand am Eingang der Kirche ab. Habt ihr \"normalen\" Unterricht, trefft ihr euch mit eurer Lehrkraft im Fachraum, lasst eure Sachen dort liegen, um dann gemeinsam in die Kirche zu gehen. Setzt euch kurs-/klassenweise, acht Personen in die großen Bänke, vier Personen in die kleinen Bänke. ZIEHT EUCH WARM AN, die Kirche ist nicht beheizt! LG Admin",
      "sender": {
        "className": null,
        "displayName": "Admin_1",
        "imageUrl": null,
        "userId": 67
      },
      "sentDateTime": "2026-06-08T12:25:00",
      "allowMessageDeletion": false,
      "hasAttachments": false,
      "isMessageRead": true,
      "isReply": false,
      "isReplyAllowed": false
    },
    {
      "id": 4857,
      "subject": "Schulmusical - Termine nächste Woche!",
      "contentPreview": "Liebe Schulgemeinde, hier die Ankündigung des Schulmusicals. Es ist soweit — die lange Wartezeit hat endlich ein Ende. Am 12.06 um 18:30 Uhr und am 14.06 um 16 Uhr führen wir das Musical in einer neuen Adaption unserer Musical-AG in der Aula auf. Beeilt euch und holt euch Tickets in den großen Pausen (oder nutzt die Abendkasse jeweils am Tag der Veranstaltung). Wir freuen uns auf euch!",
      "sender": {
        "className": null,
        "displayName": "Admin_2",
        "imageUrl": null,
        "userId": 145
      },
      "sentDateTime": "2026-06-05T15:52:00",
      "allowMessageDeletion": false,
      "hasAttachments": true,
      "isMessageRead": true,
      "isReply": false,
      "isReplyAllowed": false
    },
    {
      "id": 4119,
      "subject": "Gottesdienst entfällt, Mittwoch, 18.03.2026",
      "contentPreview": "Liebe Schüler:innen, liebe Kolleg:innen, leider muss der Gottesdienst 10er RS/GYM und SII am Mittwoch, 18.03.2026, 1. Stunde, ausfallen. Liebe Grüße Admin",
      "sender": {
        "className": null,
        "displayName": "Admin_1",
        "imageUrl": null,
        "userId": 67
      },
      "sentDateTime": "2026-03-17T17:20:00",
      "allowMessageDeletion": false,
      "hasAttachments": false,
      "isMessageRead": true,
      "isReply": false,
      "isReplyAllowed": false
    },
    {
      "id": 4103,
      "subject": "Erinnerung: 10er und SII Gottesdienst 1. Stunde am 18.03.",
      "contentPreview": "Liebe Schüler:innen, am Mittwoch, den 18.03.2026 findet in der 1. Stunde unser dritter Gottesdienst in diesem Schuljahr statt. Wenn ihr Sport habt, trefft ihr euch mit einer Lehrperson vor der Kirche, geht zusammen in die Kirche und stellt eure Taschen und Rucksäcke an der Fensterwand am Eingang der Kirche ab. ZIEHT EUCH WARM AN, die Kirche ist nicht beheizt! LG Admin",
      "sender": {
        "className": null,
        "displayName": "Admin_1",
        "imageUrl": null,
        "userId": 67
      },
      "sentDateTime": "2026-03-17T09:11:00",
      "allowMessageDeletion": false,
      "hasAttachments": false,
      "isMessageRead": true,
      "isReply": false,
      "isReplyAllowed": false
    },
    {
      "id": 2634,
      "subject": "Erinnerung: Gottesdienst Jg. 10, EF und Q1 am Mittwoch, 01.10.2025, 1. Stunde",
      "contentPreview": "Liebe Schüler:innen, am Mittwoch, den 01.10.2025 findet in der 1. Stunde unser erster Gottesdienst in diesem Schuljahr statt. Setzt euch kurs-/klassenweise, acht Personen in die großen Bänke, vier Personen in die kleinen Bänke. ZIEHT EUCH WARM AN, die Kirche ist nicht beheizt! LG Admin",
      "sender": {
        "className": null,
        "displayName": "Admin_1",
        "imageUrl": null,
        "userId": 67
      },
      "sentDateTime": "2025-09-30T12:26:00",
      "allowMessageDeletion": false,
      "hasAttachments": false,
      "isMessageRead": true,
      "isReply": false,
      "isReplyAllowed": false
    }
  ],
  "readConfirmationMessages": []
}
```

`readConfirmationMessages` was empty in this capture — item shape unconfirmed; presumably messages awaiting a
read-confirmation reply, see `messages_permissions`'s `allowRequestReadConfirmation`.
