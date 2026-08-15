# GET /WebUntis/api/rest/view/v2/home

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v2/home?school=cjd-koewi
```

**Auth:** Bearer token, or `anonymous-school-base64` header for anonymous-login schools:

```
GET https://bs-gfv.webuntis.com/WebUntis/api/rest/view/v2/home?school=bs-gfv
anonymous-school-base64: YnMtZ2Z2
```

Home screen sections — the app's landing screen.

## Responses

bs-gfv (anonymous) — only the events tile:

```json
{
  "schoolName": "Jugenddorf-Christophorusschule",
  "sections": [
    {
      "cells": [
        { "badge": null, "type": "MY_EVENTS" }
      ]
    }
  ],
  "integrationsSection": [],
  "isEmailUpdateRequired": false
}
```

schuldorf — events + absences tiles:

```json
{
  "schoolName": "Gesamtschule im Schuldorf",
  "sections": [
    {
      "cells": [
        { "badge": null, "type": "MY_EVENTS" },
        { "badge": null, "type": "STUDENT_ABSENCES" }
      ]
    }
  ],
  "integrationsSection": [],
  "isEmailUpdateRequired": false
}
```

wolfsburger-oberschule (teacher account) — teacher tiles plus third-party integration links:

```json
{
  "schoolName": "Wolfsburger Oberschule",
  "sections": [
    {
      "cells": [
        { "badge": null, "type": "MY_EVENTS" },
        { "badge": null, "type": "CLASS_TEACHER" },
        { "badge": { "count": 0 }, "type": "STUDENT_ABSENCES_ADMINISTRATION" },
        { "badge": null, "type": "CONTACT_HOURS" }
      ]
    }
  ],
  "integrationsSection": [
    {
      "id": 2,
      "name": "Homepage WOBS",
      "url": "https://www.wolfsburger-oberschule.de/?tenant_id=6763800&school=wolfsburger-oberschule",
      "iconName": null,
      "type": "WEB",
      "appId": "",
      "hideBrowserControls": true,
      "reloadDetailsOnResume": false
    },
    {
      "id": 8,
      "name": "Itslearning",
      "url": "https://wob.itslearning.com/?tenant_id=6763800&school=wolfsburger-oberschule",
      "iconName": null,
      "type": "WEB",
      "appId": "",
      "hideBrowserControls": true,
      "reloadDetailsOnResume": false
    },
    {
      "id": 23,
      "name": "Wollino",
      "url": "https://wollino.de?tenant_id=6763800&school=wolfsburger-oberschule",
      "iconName": "pa-eigenerlink-logo",
      "type": "WEB",
      "appId": "",
      "hideBrowserControls": true,
      "reloadDetailsOnResume": false
    },
    {
      "id": 28,
      "name": "Messenger",
      "url": "https://eassistent.at/mobileapp?tenant_id=6763800&school=wolfsburger-oberschule",
      "iconName": "pa-eassistent-logo",
      "type": "APP",
      "appId": "com.eassistent.untis",
      "hideBrowserControls": true,
      "reloadDetailsOnResume": false
    },
    {
      "id": 36,
      "name": "Notfallhilfe",
      "url": "https://notfallhilfe.app.webuntis.com/untis?tenant_id=6763800&school=wolfsburger-oberschule",
      "iconName": null,
      "type": "WEB",
      "appId": "",
      "hideBrowserControls": true,
      "reloadDetailsOnResume": false
    }
  ],
  "isEmailUpdateRequired": false
}
```

`integrationsSection` entries are often templated with `tenant_id`/`school` (and, elsewhere, lesson/period
context) query params for deep-linking into the target app/site.
