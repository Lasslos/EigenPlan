# GET /WebUntis/api/public/v1/login-meta

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/public/v1/login-meta?school=cjd-koewi
```

No authentication. Called right after a school is selected, before any credentials are entered, to decide
which login UI to show.

## Example responses

cjd-koewi — normal password login + SSO offered, no anonymous login:

```json
{
  "anonymousLoginEnabled": false,
  "ssoLoginEnabled": true
}
```

bs-gfv — anonymous login enabled, no SSO:

```json
{
  "anonymousLoginEnabled": true,
  "ssoLoginEnabled": false
}
```
