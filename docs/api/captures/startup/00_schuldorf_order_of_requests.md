# schuldorf — request order during startup / login (SSO / key-based)

schuldorf has SSO login enabled, with password login disabled server-side. The app's login UI instead accepts
a manually-entered key (or the equivalent QR code); that key is used directly as the app-shared-secret to
compute the OTP, so `getAppSharedSecret` is never called for this school.

Observed call order:

1. app-info
2. getAuthToken
3. getUserData2017
4. mobile/data
5. push register
6. user-email
7. getTimetable2017
8. getAuthToken
9. timetable/grid
10. mobile/data (called again)
11. messages/status
12. getMessagesOfDay2017
13. refresh-device-presence (`PATCH https://push.webuntis.com/api/refresh-device-presence/{deviceId}`, bearer
    auth — purpose unconfirmed, see `../../spec/NOTES.md`)
14. messages/status (called again)
15. trigger/startup
16. usage-statistics
