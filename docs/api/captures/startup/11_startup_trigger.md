# GET /WebUntis/api/rest/view/v1/trigger/startup

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/trigger/startup?school=cjd-koewi
GET https://bs-gfv.webuntis.com/WebUntis/api/rest/view/v1/trigger/startup?school=bs-gfv
```

**Auth:** Bearer token, as on every other REST call in this capture set (including for the bs-gfv anonymous
account — see `../../spec/NOTES.md` §2b for the open question of whether anonymous sessions get a real bearer
token here or use the `anonymous-school-base64` header instead).

Fetches pending "startup actions" (e.g. forced onboarding/consent dialogs).

## Response

```json
{
  "startupActions": []
}
```

Always empty across all four schools in this capture set — item shape unconfirmed.
