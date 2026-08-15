# GET /WebUntis/api/rest/view/v1/messages/{messageId}/attachmentstorageurl

```
GET https://cjd-koewi.webuntis.com/WebUntis/api/rest/view/v1/messages/68d39a3f-7a7d-4aaa-b597-641d6cf121c1/attachmentstorageurl?school=cjd-koewi
```

**Auth:** Bearer token required.

Resolves a `storageAttachments[].id` from a message detail response into a short-lived, pre-signed download
URL for Untis's S3-compatible storage.

## Response

```json
{
  "additionalHeaders": [
    {
      "key": "x-amz-server-side-encryption-customer-key",
      "value": "<redacted-sse-c-key>"
    },
    {
      "key": "x-amz-server-side-encryption-customer-key-md5",
      "value": "<redacted-sse-c-key-md5>"
    },
    {
      "key": "host",
      "value": "storage.webuntis.com"
    },
    {
      "key": "x-amz-server-side-encryption-customer-algorithm",
      "value": "AES256"
    }
  ],
  "downloadUrl": "https://storage.webuntis.com/untis-sts-prod/<tenantId>/<objectId>?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=<redacted>&X-Amz-SignedHeaders=host%3Bx-amz-server-side-encryption-customer-algorithm%3Bx-amz-server-side-encryption-customer-key%3Bx-amz-server-side-encryption-customer-key-md5&X-Amz-Credential=<redacted>&X-Amz-Expires=600&X-Amz-Signature=<redacted>"
}
```

The `downloadUrl` is a pre-signed S3 URL (server-side encryption with a customer-supplied key, SSE-C) that
**only works if the three `x-amz-server-side-encryption-customer-*` headers from `additionalHeaders` are
replayed verbatim** on the follow-up `GET` to that URL — a plain `GET downloadUrl` without those headers
fails. The URL itself expires quickly (`X-Amz-Expires=600`, i.e. 10 minutes).
