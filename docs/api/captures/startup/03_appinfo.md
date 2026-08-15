# getAppInfo

```
POST https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi&m=getAppInfo&a=false&s=cjd-koewi.webuntis.com&v=a6.7.0
```

JSON-RPC 2.0, method `getAppInfo`. No authentication. Called right after `login-meta`, before any credentials
are collected — likely a version/compatibility sanity check.

## Request

```json
{
  "id": "untis-mobile-android-6.7.0",
  "jsonrpc": "2.0",
  "method": "getAppInfo",
  "params": []
}
```

## Response

```json
{
  "jsonrpc": "2.0",
  "id": "untis-mobile-android-6.7.0",
  "result": {
    "wuVersion": "2027.0.2",
    "mobileApiVersion": "2.26.0",
    "wuMobileApiVersion": 103
  }
}
```
