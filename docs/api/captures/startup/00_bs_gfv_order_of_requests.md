# bs-gfv — request order during startup / login (anonymous)

Observed call order for an anonymous login on this school (no credentials collected).

1. schoolsearch
2. login-meta
3. app-info
4. getUserData2017
5. mobile/data (called twice)
6. getMessagesOfDay2017
7. trigger/startup
8. usage-statistics (not exercised in this capture, listed for completeness)
