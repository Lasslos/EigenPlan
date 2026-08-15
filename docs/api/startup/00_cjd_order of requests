# cjd-koewi — request order during startup / login

Observed call order for a normal username + password login on this school.

1. schoolsearch
2. login-meta
3. app-info
4. authentication
5. app-shared-secret
6. getUserData2017
7. mobile/data
8. push register
9. user-email
10. getTimetable2017
11. getAuthToken
12. mobile/data (called a second time)
13. getMessagesOfDay2017
14. messages/status
15. trigger/startup
16. usage-statistics (not exercised in this capture, listed for completeness)
