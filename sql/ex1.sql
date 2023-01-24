WITH d_cte
     AS (SELECT employeeid,
                employeename,
                employeetitle,
                employeeid                         AS managerid,
                employeename                       AS managername,
                employeename                       AS directorname,
                Cast(employeename AS NVARCHAR(max)) positionbreadcrumbs
         FROM   employeelist
         WHERE  managerid IS NULL),
     e_cte
     AS (SELECT DISTINCT e. employeeid,
                         e. employeename,
                         e.employeetitle,
                         Isnull(m.employeeid, e.employeeid)      AS managerid,
                         Isnull(m. employeename, e.employeename) AS managername
         FROM   employeelist e
                INNER JOIN employeelist m
                        ON m. employeeid = e. managerid),
     r_cte
     AS (SELECT *
         FROM   d_cte
         UNION ALL
         SELECT a.*,
                b.directorname                                      AS
                directorname,
                Concat(b.positionbreadcrumbs, '| ', a.employeename) AS
                positionbreadcrumbs
         FROM   e_cte a
                INNER JOIN r_cte b
                        ON a.managerid = b.employeeid)

SELECT   EmployeeId,
         EmployeeName,
         EmployeeTitle,
         ManagerId,
         ManagerName,
         DirectorName,
         PositionBreadcrumbs
FROM     r_cte
ORDER BY EmployeeId
