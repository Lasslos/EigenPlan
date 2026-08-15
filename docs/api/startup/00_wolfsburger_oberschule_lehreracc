# wolfsburger-oberschule — request order during startup / login (teacher account)

Observed call order for a normal username + password login, captured against a teacher account (as opposed to
a student/class account — useful for seeing role-dependent fields elsewhere in this documentation).

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
12. timetable/grid
13. mobile/data (called again)
14. getMessagesOfDay2017
15. messages/status
16. dashboard/cards/status
17. trigger/startup
18. usage-statistics (not exercised in this capture, listed for completeness)
