-- DDL Script for T-SQL Courses task.2
-- 23-03-2015 A Kolesnikov Initial Creation
--
--1) Create db
--2) Create Table DepartmentEmployees
--3) Create UDF for parse data from AdventureWorks to DepartmentEmployees.
--		AdventureWorks2008R2.HumanResources.Department, колонка Name
--		Employees. Список всех работников отдела(фамилия и имя через пробел) через запятую в алфавитном порядке.


--1)
IF (NOT EXISTS (SELECT name 
					FROM master.dbo.sysdatabases 
					WHERE ('[' + name + ']' = 'SQL_Courses_AKolesnikov'
					OR name = 'SQL_Courses_AKolesnikov')))
BEGIN
	CREATE DATABASE LightPoint
	PRINT 'SQL_Courses_AKolesnikov Database Created';
END
GO

--2)
USE SQL_Courses_AKolesnikov
IF (NOT EXISTS (SELECT * 
					FROM INFORMATION_SCHEMA.TABLES
					WHERE TABLE_SCHEMA = 'dbo' 
					AND  TABLE_NAME = 'DepartmentEmployees'))
BEGIN
	CREATE TABLE dbo.DepartmentEmployees
	(
		DepartmentName NVARCHAR(100) NOT NULL,
		Employees NVARCHAR(200) NOT NULL
	)	
	PRINT 'DepartmentEmployees Created'; 
END
ELSE
BEGIN
	TRUNCATE TABLE dbo.DepartmentEmployees
	PRINT 'DepartmentEmployees Truncated';
END
GO

--3)
IF EXISTS ( SELECT  1
					FROM    Information_schema.Routines
					WHERE   Specific_schema = 'dbo'
                    AND specific_name = 'udfGetPersonsFromDepartmentByDepartmentID'
                    AND Routine_Type = 'FUNCTION' ) 
    BEGIN
	DROP FUNCTION dbo.udfGetPersonsFromDepartmentByDepartmentID
	PRINT 'udfGetPersonsFromDepartmentByDepartmentID is Droped'
	END
GO   

IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'DepartmentIds')
	BEGIN
	DROP TYPE DepartmentIds
	PRINT 'TYPE DepartmentIds is Droped'
	END
	
CREATE TYPE DepartmentIds AS TABLE
(
 DepartmentId INT NOT NULL
)
GO

CREATE FUNCTION dbo.udfGetPersonsFromDepartmentByDepartmentID( @DepartmentIds DepartmentIds READONLY)
RETURNS @DepartmentPersons TABLE
(
	DepartmentName NVARCHAR(100) NOT NULL,
	PersonFullName NVARCHAR(100) NOT NULL 
)
AS
BEGIN
	INSERT INTO @DepartmentPersons
	SELECT D.Name AS DepartmentName, P.LastName + ',' + P.FirstName as Employee
	FROM AdventureWorks2008R2.Person.Person P
	JOIN AdventureWorks2008R2.HumanResources.EmployeeDepartmentHistory EDH  ON EDH.BusinessEntityID = P.BusinessEntityID
	JOIN AdventureWorks2008R2.HumanResources.Department D ON D.DepartmentID = EDH.DepartmentID
	WHERE D.DepartmentID IN (SELECT DIds.DepartmentId FROM @DepartmentIds DIds)
	ORDER BY Employee ASC
	RETURN
END
GO
PRINT 'Function GetPersonsFromDepartmentByDepartmentID is created'
