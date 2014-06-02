#1. Most recent status change and login Fellows
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

#2. Last login for hiring managers
SELECT
'FirstName'
, 'LastName'
, 'Company'
, 'LastLogin'
UNION ALL
SELECT
a.FirstName
, a.LastName
, a.Company
, a.LastLogin
FROM (
SELECT
users.firstName AS FirstName
, users.lastNAme AS LastName
, companies.name AS Company
, users.lastLogin AS LastLogin
FROM users
INNER JOIN hiringManagers AS hM
ON users.id = hM.user_id
INNER JOIN companies
ON hM.company_id = companies.id
WHERE
users.role = 'Hiring Manager'
ORDER BY
LastLogin DESC) AS a
INTO OUTFILE '/tmp/HiringManager_20140602.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

#3. On-site completes/pendings in the last week
SELECT
'FirstName'
, 'LastName'
, 'Company'
, 'Opportunity'
, 'Status'
, 'Date'
, 'Fellow_Score'
, 'Fellow_Message'
, 'Company_Score'
, 'Company_Message'
UNION ALL
SELECT
a.FirstName
, a.LastName
, a.Company
, a.Opportunity
, a.Status
, a.Date
, a.Fellow_Score
, a.Fellow_Message
, a.Company_Score
, a.Company_Message
FROM (
SELECT
users.firstName AS FirstName
, users.lastName AS LastName
, companies.name AS Company
, opp.title AS Opportunity
, pS_Fellow.status AS Status
, pS_Fellow.created_at AS Date
, pS_Fellow.score AS Fellow_Score
, pS_Fellow.message AS Fellow_Message 
, pS_Company.score AS Company_Score
, pS_Company.message AS Company_Message
FROM users
INNER JOIN fellows
ON users.id = fellows.user_id
LEFT JOIN placementStatuses AS pS_Fellow
ON fellows.id = pS_Fellow.fellow_id
AND pS_Fellow.status IN ('On-site Interview Pending', 'On-site Interview Complete')
AND pS_Fellow.fromRole = 'Fellow'
LEFT JOIN placementStatuses AS pS_Company
ON pS_Fellow.fellow_id = pS_Company.fellow_id
AND pS_Fellow.opportunity_id = pS_Company.opportunity_id
AND pS_Fellow.status = pS_Company.status
AND pS_Company.fromRole = 'Hiring Manager'
LEFT JOIN opportunities AS opp
ON pS_Fellow.opportunity_id = opp.id
LEFT JOIN companies
ON opp.company_id = companies.id
WHERE
pS_Fellow.created_at >= DATE_ADD(CURDATE(), INTERVAL -1 WEEK)
ORDER BY
Status DESC
, Date DESC) AS a
INTO OUTFILE '/tmp/OnSite_20140602.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

#4. Opportunity history by Fellow
SELECT
'FirstName'
, 'LastName'
, 'Opportunity'
, 'Company'
, 'City'
, 'Status'
, 'Date'
, 'StatusRank'
UNION ALL
SELECT
a.FirstName
, a.LastName
, a.Opportunity
, a.Company
, a.City
, a.Status
, a.Date
, a.StatusRank
FROM (
SELECT
e.firstName AS FirstName 
, e.lastName AS LastName 
, b.title AS Opportunity
, a.name AS Company
, CASE
WHEN a.city LIKE '%Baltimore%' OR a.city LIKE '%Fulton%' OR a.city LIKE '%Jessup%' THEN 'Baltimore'
WHEN a.city LIKE '%Cincinnati%' THEN 'Cincinnati'
WHEN a.city LIKE '%Cleveland%' OR a.city LIKE '%Beachwood%' THEN 'Cleveland'
WHEN a.city LIKE '%Columbus%' OR a.city LIKE '%Dublin%' THEN 'Columbus'
WHEN (a.city LIKE '%Detroit%' OR a.city LIKE '%Ann Arbor%') AND name <> 'U3 Advisors' THEN 'Detroit'
WHEN a.city LIKE '%Las Vegas%' THEN 'Las Vegas'
WHEN a.city LIKE '%Miami%' THEN 'Miami'
WHEN a.city LIKE '%New Orleans%' THEN 'New Orleans'
WHEN (a.city LIKE '%Philadelphia%' or a.city LIKE '%Ambler%') AND name <> 'U3 Advisors' THEN 'Philadelphia'
WHEN a.city LIKE '%Providence%' THEN 'Providence'
WHEN a.city LIKE '%San Antonio%' THEN 'San Antonio'
WHEN a.city LIKE '%St. Louis%' OR a.city LIKE '%Saint Louis%' THEN 'St. Louis'
WHEN a.city LIKE '%New York City%' THEN 'New York City'
ELSE 'Uncategorized'
END AS City 
, c.status AS Status 
, c.created_at AS Date
, CASE
WHEN c.status = 'Introduced' THEN 1
WHEN c.status = 'Contacted' THEN 2
WHEN c.status = 'Phone Interview Pending' THEN 3
WHEN c.status = 'Phone Interview Complete' THEN 4
WHEN c.status = 'On-site Interview Pending' THEN 5
WHEN c.status = 'On-site Interview Complete' THEN 6
WHEN c.status = 'Conversation Closed' THEN 7
WHEN c.status = 'Offer Extended' THEN 8
WHEN c.status = 'Offer Accepted' THEN 9
ELSE NULL
END AS StatusRank
FROM companies AS a
INNER JOIN opportunities AS b
ON a.id = b.company_id
INNER JOIN placementStatuses AS c
ON b.id = c.opportunity_id
INNER JOIN fellows AS d
ON c.fellow_id = d.id
INNER JOIN users AS e
ON d.user_id = e.id
ORDER BY
LastName ASC
, StatusRank DESC
, Date DESC) AS a
INTO OUTFILE '/tmp/FellowOppHistory_20140602.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

#5. Opportunity history by company
SELECT
'City'
, 'Company'
, 'Opportunity'
, 'FirstName'
, 'LastName'
, 'Status'
, 'Date'
UNION ALL
SELECT
a.City
, a.Company
, a.Opportunity
, a.FirstName
, a.LastName
, a.Status
, a.Date
FROM (
SELECT
CASE
WHEN a.city LIKE '%Baltimore%' OR a.city LIKE '%Fulton%' OR a.city LIKE '%Jessup%' THEN 'Baltimore'
WHEN a.city LIKE '%Cincinnati%' THEN 'Cincinnati'
WHEN a.city LIKE '%Cleveland%' OR a.city LIKE '%Beachwood%' THEN 'Cleveland'
WHEN a.city LIKE '%Columbus%' OR a.city LIKE '%Dublin%' THEN 'Columbus'
WHEN (a.city LIKE '%Detroit%' OR a.city LIKE '%Ann Arbor%') AND name <> 'U3 Advisors' THEN 'Detroit'
WHEN a.city LIKE '%Las Vegas%' THEN 'Las Vegas'
WHEN a.city LIKE '%Miami%' THEN 'Miami'
WHEN a.city LIKE '%New Orleans%' THEN 'New Orleans'
WHEN (a.city LIKE '%Philadelphia%' or a.city LIKE '%Ambler%') AND name <> 'U3 Advisors' THEN 'Philadelphia'
WHEN a.city LIKE '%Providence%' THEN 'Providence'
WHEN a.city LIKE '%San Antonio%' THEN 'San Antonio'
WHEN a.city LIKE '%St. Louis%' OR a.city LIKE '%Saint Louis%' THEN 'St. Louis'
WHEN a.city LIKE '%New York City%' THEN 'New York City'
ELSE 'Uncategorized'
END AS City 
, a.name AS Company
, b.title AS Opportunity 
, e.firstName AS FirstName 
, e.lastName AS LastName 
, c.status AS Status 
, c.created_at AS Date 
FROM companies AS a
INNER JOIN opportunities AS b
ON a.id = b.company_id
INNER JOIN placementStatuses AS c
ON b.id = c.opportunity_id
INNER JOIN fellows AS d
ON c.fellow_id = d.id
INNER JOIN users AS e
ON d.user_id = e.id
ORDER BY
City ASC
, Company ASC
, Opportunity ASC
, Date DESC) AS a
INTO OUTFILE '/tmp/CompanyOppHistory_20140602.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
