# GET /WebUntis/api/rest/view/v1/dashboard/cards

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/dashboard/cards?school=cjd-koewi
```

**Auth:** Bearer token, or `anonymous-school-base64` header for anonymous-login schools:

```
GET https://bs-gfv.webuntis.com/WebUntis/api/rest/view/v1/dashboard/cards?school=bs-gfv
anonymous-school-base64: YnMtZ2Z2
```

Dashboard "cards" — announcements pinned to the home screen.

## Responses

bs-gfv — no cards:

```json
{
  "dashboardCards": []
}
```

schuldorf — one card:

```json
{
  "dashboardCards": [
    {
      "id": 146,
      "title": "Login zu WebUntis und UntisMobile",
      "subtitle": "Hier findet ihr die Anleitung um euch bei WebUntis und UntisMobile (App) anzumelden.",
      "hasAttachments": true,
      "headerColor": "ffa94d",
      "orderNo": 10,
      "status": "READ",
      "icon": "megaphone"
    }
  ]
}
```
