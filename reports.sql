SELECT
'FirstName'
, 'LastName'
, 'LastLogin'
, 'LastStatusChange'
, 'DaySinceLastLogin'
, 'DaysSinceLastStatusChange'
UNION ALL
SELECT
a.FirstName
, a.LastName
, a.LastLogin
, a.LastStatusChange
, a.DaySinceLastLogin
, a.DaysSinceLastStatusChange
FROM (
SELECT
users.firstName AS FirstName
, users.lastName AS LastName
, users.lastLogin AS LastLogin
, MAX(pS.created_at) AS LastStatusChange
, DATEDIFF(NOW(), users.lastLogin) AS DaySinceLastLogin
, DATEDIFF(NOW(), MAX(pS.created_at)) AS DaysSinceLastStatusChange
FROM users
INNER JOIN fellows
ON users.id = fellows.user_id
INNER JOIN placementStatuses AS pS
ON fellows.id = pS.fellow_id
GROUP BY
users.firstName
, users.lastName
, users.lastLogin
ORDER BY
LastStatusChange ASC) AS a
INTO OUTFILE '/tmp/Fellow_20140602.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
