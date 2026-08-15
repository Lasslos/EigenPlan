# GET /WebUntis/api/rest/view/v1/profile/user-email

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/profile/user-email?school=cjd-koewi
GET https://schuldorf.webuntis.com/WebUntis/api/rest/view/v1/profile/user-email?school=schuldorf
```

**Auth:** Bearer token required.

## Responses

cjd-koewi — no email on file (empty string, not `null`):

```json
{ "email": "" }
```

schuldorf:

```json
{ "email": "musterschueler@example.invalid" }
```
