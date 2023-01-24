-- CREATE TABLE Dimension.Employee (
--     EmployeeId INT PRIMARY KEY,
--     EmployeeName NVARCHAR(255) NOT NULL,
--     EmployeeTitle NVARCHAR(255) NOT NULL,
--     ManagerId INT NOT NULL,
--     SalaryNumber INT NOT NULL,
--     EffectiveStartDate DATE NOT NULL,
--     EffectiveEndDate DATE NULL,
--     CurrentRecord BIT NOT NULL DEFAULT(1)
-- );

-- This a learing curve for me, I havent used TSQL(I coud have done in plain SQL but wanted to explore). 
-- I have not checked if this will work or not syntactically, also have taken insparation from internet
-- The Idea here is to find the existing record and apply SDC logic to to it
--  When we say SDC 1, Then we need to find if the name has changed if yes we need to update all the historical records
-- In  case of SDC2, We need to add new rows and mark them to current row and previous row must be retired 
DECLARE @CurrentDateTime DATETIME= Cast(Getdate() AS DATETIME2);

MERGE Dimension.Employee AS [target]
USING Staging.Employee AS [source]
ON ( [source].[EmployeeId] = [target].[Employeeid] )

-- SDC 1 Keep only the last value for all historical records (SCD Type I) Employee Name  
WHEN MATCHED AND (
    ([source].[employeename] <> [target].[employeename])
                        OR 
    ([source].[employeename] IS NULL  AND [target].[employeename] IS NOT NULL) 
                        OR 
    ([source].[employeename] IS NOT NULL AND [target].[employeename] IS NULL)
) 
THEN UPDATE 
SET [target].[employeename] = [source].[employeename],
    
--SDC 2
insert into Dimension.Employee 
( --Table and columns in which to insert the data
  EmployeeId,
  EmployeeName,
  EmployeeTitle,
  ManagerId,
  EffectiveStartDate
)
-- Select the rows/columns to insert that are output from this merge statement 
-- In this example, the rows to be inserted are the rows that have changed (UPDATE).
select    
  EmployeeId,
  EmployeeName,
  EmployeeTitle,
  ManagerId,
  EffectiveStartDate
from
(
  -- This is the beginning of the merge statement.
  -- The target must be defined, in this example it is our slowly changing
  -- dimension table
MERGE Dimension.Employee AS [target]
USING Staging.Employee AS [source]
ON ( [source].[EmployeeId] = [target].[Employeeid] 



)
  -- If the ID's match 
  -- therefore, update the existing record in the target, end dating the record 
  -- and set the CurrentRecord flag to N
  WHEN MATCHED and (
        ([target].[EmployeeTitle] <> [source].[EmployeeTitle] )
                OR 
        ([target].[EmployeeTitle] IS NULL AND [source].[EmployeeTitle] IS NOT NULL) 
                OR 
        ([target].[EmployeeTitle] IS NOT NULL AND [source].[EmployeeTitle] IS NULL)
    ) or (
        ([target].[ManagerId] <> [source].[ManagerId])
                OR 
        ([target].[ManagerId] IS NULL AND [source].[ManagerId] IS NOT NULL) 
                 OR 
        ([target].[ManagerId] IS NOT NULL AND [source].[ManagerId] IS NULL)
    )
  THEN 
  UPDATE SET 
    EffectiveEndDate=getdate()-1, 
    CurrentRecord=0
  -- If the ID's do not match, then the record is new;
  -- therefore, insert the new record into the target using the values from the source.
  WHEN NOT MATCHED THEN  
  INSERT 
  (
    EmployeeId,
    EmployeeName,
    EmployeeTitle,
    ManagerId,
    EffectiveStartDate
    CurrentRecord
  )
  VALUES 
  (
    source.EmployeeId,
    source.EmployeeName,
    source.EmployeeTitle,
    source.ManagerId,
    getdate(),
    1
  )
  OUTPUT $action, 
    source.EmployeeId,
    source.EmployeeName,
    source.EmployeeTitle,
    source.ManagerId,
    getdate(),
    1
) -- the end of the merge statement
--The changes output below are the records that have changed and will need
--to be inserted into the slowly changing dimension.
as changes 
(
  action, 
  EmployeeId,
  EmployeeName,
  EmployeeTitle,
  ManagerId,
  EffectiveStartDate
  CurrentRecord
)
where action='UPDATE';

