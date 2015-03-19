--DDL_script_task_1
--Alexey Kolesnikov
--03-11-2015
--SQL courses, task_1, DDL Script, version 1.
-- Adding database, adding table or truncate it
-- Adding Executable functions:
-- 1) for searching start fiscal year
-- 2) for searching end fiscal year

IF (NOT EXISTS (SELECT name 
					FROM master.dbo.sysdatabases 
					WHERE ('[' + name + ']' = 'SQL_Courses_AKolesnikov'
					OR name = 'SQL_Courses_AKolesnikov')))
BEGIN
	CREATE DATABASE SQL_Courses_AKolesnikov
	PRINT 'Database Created';
END
GO

USE SQL_Courses_AKolesnikov
IF (NOT EXISTS (SELECT * 
					FROM INFORMATION_SCHEMA.TABLES
					WHERE TABLE_SCHEMA = 'dbo' 
					AND  TABLE_NAME = 'DateDim'))
BEGIN
    CREATE TABLE dbo.DateDim(
    DateKey INT NOT NULL PRIMARY KEY,
    CalendarDate DATE NOT NULL UNIQUE, 
	DayOfTheWeek NVARCHAR(10), --название недели на англ
	CalendarDayInMonthNumber INT NOT NULL, --календарный день в месяце, числа 1-31
	CalendarDayInYearNumber INT NOT NULL, --календарный день в месяце, числа 1-366
	CalendarWeekInYearNumber INT NOT NULL, --календарная неделя в году, числа 1-53
	CalendarMonthNumber INT NOT NULL, -- номер месяца в году, 1-12
	CalendarQuarter INT NOT NULL, -- порядковый номер квартала в календарном году. Допустимые значения 1-5 
	CalendarYear INT NOT NULL, -- календарный год
	CalendarMonthStartFlag BIT NOT NULL, -- битовое поле. 1, если день приходится на начало календарного месяца, иначе 0.
	CalendarMonthEndFlag BIT NOT NULL, -- битовое поле. 1, если день приходится на конец календарного месяца, иначе 0. 
	CalendarMonthStartDate DATE NOT NULL, -- дата начала календарного месяца, к которому принадлежит текущая дата. 
	CalendarMonthEndDate DATE NOT NULL, -- дата окончания календарного месяца, к которому принадлежит текущая дата. 
	FiscalDayInYearNumber INT NOT NULL, -- целочисленное поле. Порядковый номер дня в фискальном году. Допустимые значения - 1-371 
	FiscalWeekInYearNumber INT NOT NULL, -- порядковый номер недели в фискальном месяце. Допустимые значения 1-53
	FiscalMonthNumber INT NOT NULL, -- порядковый номер месяца в фискальном году. Допустимые значения 1-12 
	FiscalQuarter INT NOT NULL, -- порядковый номер квартала в фискальном году. Допустимые значения 1-5 
	FiscalYear INT NOT NULL, -- фискальный год
	FiscalMonthStartFlag BIT NOT NULL, -- битовое поле. 1, если день приходится на начало фискального месяца, иначе 0.
	FiscalMonthEndFlag BIT NOT NULL, -- битовое поле. 1, если день приходится на конец фискального месяца, иначе 0. 
	FiscalMonthStartDate DATE NOT NULL, -- поле типа DATE. Дата начала фискального месяца, к которому принадлежит текущая дата. 
	FiscalMonthEndDate DATE NOT NULL, -- поле типа DATE. Дата окончания фискального месяца, к которому принадлежит текущая дата. 
	RelativeDay INT NOT NULL, -- целочисленное поле. количество дней от\до сегодняшней даты. 0 для сегодняшнего дня, отрицательное значение для прошлых дат, положительное - для будущих.
	RelativeWeek INT NOT NULL -- целочисленное поле. количество недель от\до сегодняшней даты. 0 для текущей недели, отрицательное значение для прошлых дат, положительное - для будущих.
	
)
	PRINT 'Table DateDim Created';
	
END
ELSE
BEGIN
	TRUNCATE TABLE dbo.DateDim
	PRINT 'Table DateDim Truncated';
END
GO

-- Если индекс создан - удалить\пересоздать.
IF EXISTS (SELECT name FROM sysindexes WHERE name = 'index_Date_key') 
	BEGIN
	DROP INDEX [dbo].[DateDim].index_Date_key
	PRINT 'Index index_Date_key is droped';
	END
CREATE INDEX [index_Date_key] ON dbo.DateDim(DateKey);
PRINT 'New Index on dbo.DateDim for DateKey is created'
GO

--Special
--DROP TABLE dbo.DateDim
--SELECT * FROM dbo.DateDim

--------------------------------------------
-- 1) Create function which find start fiscal year date and returns it.
IF EXISTS ( SELECT  1
					FROM    Information_schema.Routines
					WHERE   Specific_schema = 'dbo'
                    AND specific_name = 'FindFiscalStartYearByBaseDate'
                    AND Routine_Type = 'FUNCTION' ) 
	DROP FUNCTION dbo.FindFiscalStartYear
GO        
   --Search Start fiscal year on current year based on BaseDate
CREATE FUNCTION dbo.FindFiscalStartYearByBaseDate(@BaseDate DATE)
RETURNS DATE
AS
BEGIN
	DECLARE 	
		@StartYear Date,
		@FirstSaturday DATE,
		@FifthSaturday DATE,
		@StartFiscalYear DATE;
	
	SET @StartYear = CAST('01-01-' + CONVERT(VARCHAR, DATEPART(year,@BaseDate))AS DATE);
	
	WITH num(n) AS --с помощью рекурсивного CTE создаем таблицу со столбцом n и значениями от 0 до 6
	(
	SELECT 0 
	UNION ALL 
	SELECT n+1 FROM num 
	WHERE n < 6
	),
	dates AS -- создаем таблицу с датами от 1 до 7 января 2002 года
	(
	SELECT DATEADD(day,  n,  @StartYear) AS day 
	FROM num
	)
	SELECT @FirstSaturday = day FROM dates  WHERE DATENAME(weekday, day) = 'saturday'; -- выбираем день, соответствующий первой субботе в году, записываем
	
	SET @FifthSaturday = DATEADD(day,28,@FirstSaturday); -- выбираем 5ю субботу в году

	SET @StartFiscalYear = 
			CASE -- Назначим стартовый день года в зависимости от  <  > 29го дня года
				WHEN DATEDIFF (day, @StartYear, @FifthSaturday) <= 29 THEN DATEADD(day,28,@FirstSaturday)
				ELSE DATEADD(day,35,@FirstSaturday)
			END	
	RETURN 	@StartFiscalYear;
END
GO
	PRINT 'FUNCTION FindFiscalStartYearByBaseDate Added';
--------------------------------------------
-- 2) Create function which find fiscal year end date and returns it.
IF EXISTS ( SELECT  1
					FROM    Information_schema.Routines
					WHERE   Specific_schema = 'dbo'
                    AND specific_name = 'FindFiscalEndYearByBaseDate'
                    AND Routine_Type = 'FUNCTION' ) 
	DROP FUNCTION dbo.FindFiscalEndYearByStartFiscalYear
GO        
   
CREATE FUNCTION dbo.FindFiscalEndYearByBaseDate(@BaseDate DATE)
RETURNS DATE
AS
BEGIN
	DECLARE 
		@NextYear DATE,		
		@FirstSaturday DATE,
		@FifthSaturday DATE,
		@StartNextFiscalYear DATE,
		@EndFiscalYear DATE;
	
	SET @NextYear = CAST('01-01-' + CONVERT(VARCHAR, DATEPART(year,DATEADD(year,1,@BaseDate)))AS DATE); --выбираем 1 января следующего года
	
	WITH num(n) AS --с помощью рекурсивного CTE создаем таблицу со столбцом n и значениями от 0 до 6
	(
	SELECT 0 
	UNION ALL 
	SELECT n+1 FROM num 
	WHERE n < 6
	),
	dates AS -- создаем таблицу с датами от 1 до 7 января 2002 года
	(
	SELECT DATEADD(day,  n,  @NextYear) AS day 
	FROM num
	)
	SELECT @FirstSaturday = day FROM dates  WHERE DATENAME(weekday, day) = 'saturday'; -- выбираем день, соответствующий первой субботе в году, записываем
	
	SET @FifthSaturday = DATEADD(day,28,@FirstSaturday); -- выбираем 5ю субботу в году

	SET @StartNextFiscalYear = 
			CASE -- Назначим стартовый день года в зависимости от  <  > 29го дня года
				WHEN DATEDIFF (day, @NextYear, @FifthSaturday) <= 29 THEN DATEADD(day,28,@FirstSaturday)
				ELSE DATEADD(day,35,@FirstSaturday)
			END	
	SET @EndFiscalYear = DATEADD(day,-1,@StartNextFiscalYear); -- Предыдущий фискальный год заканчивается на 1 день раньше начала следующего финансового года, в пятницу
	RETURN @EndFiscalYear;
END		
GO
	PRINT 'FUNCTION FindFiscalEndYearByBaseDate Added';
-- 	
IF EXISTS ( SELECT  1
					FROM    Information_schema.Routines
					WHERE   Specific_schema = 'dbo'
                    AND specific_name = 'FormDateKey'
                    AND Routine_Type = 'FUNCTION' ) 
	DROP FUNCTION dbo.FormDateKey
GO        
  
   
CREATE FUNCTION dbo.FormDateKey(@BaseDate DATE)
RETURNS INT
AS 
BEGIN 
	DECLARE @FormDateKey VARCHAR(10)= '';

	SET @FormDateKey = @FormDateKey + CONVERT(VARCHAR, DATEPART(MONTH,@BaseDate))
	
	IF (DATEPART(DAY, @BaseDate) < 10) 
		BEGIN
			SET @FormDateKey =  @FormDateKey + '0' + CONVERT(VARCHAR, DATEPART(DAY,@BaseDate))
		END
	ELSE	SET @FormDateKey = @FormDateKey + CONVERT(VARCHAR, DATEPART(DAY,@BaseDate))
	
	SET @FormDateKey = @FormDateKey + CONVERT(VARCHAR, DATEPART(YEAR,@BaseDate))
	
	RETURN CONVERT(INT, @FormDateKey);
END
GO
	PRINT 'FUNCTION FormDateKey Added';