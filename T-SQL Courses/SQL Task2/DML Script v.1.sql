-- DML Script for T-SQL Courses Task 2
-- 23-03-2015 A Kolesnikov Initial Creation
-- Insert persons FullName and department from AdventureWorks to SQL_Courses_AKolesnikov database, table DepartmentEmployees

USE SQL_Courses_AKolesnikov
DECLARE @DepartmentIDs DepartmentIds; -- use our Declare Type to Table type function

--Fill Department IDs
INSERT INTO @DepartmentIDs
SELECT D.DepartmentID FROM AdventureWorks2008R2.HumanResources.Department D

--Fill dbo.DepartmentEmployees Table
INSERT INTO dbo.DepartmentEmployees
SELECT * FROM dbo.udfGetPersonsFromDepartmentByDepartmentID(@DepartmentIDs)
GO

--TRUNCATE TABLE dbo.DepartmentEmployees
--SELECT * FROM dbo.DepartmentEmployees

--