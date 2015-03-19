--DML_script_task_1
--Alexey Kolesnikov
--03-11-2015
--SQL courses, task_1, DML Script, version 1.
-- Filling DateDim table by dates.

USE SQL_Courses_AKolesnikov
GO
DECLARE 
	@FirstSaturday DATE,
	@FifthSaturday DATE,
	@StartFiscalYear DATE,
	@EndFiscalYear DATE,
	@StartNextFiscalYear DATE,
	--
	@Offset   INT, --счетчик primary key
	@Basedate DATE = '01-01-2002', -- дата
	@DayOfTheWeek nvarchar(10), --название недели на англ
	@CalendarDayInMonthNumber INT, --календарный день в месяце, числа 1-31
	@CalendarDayInYearNumber INT, --календарный день в месяце, числа 1-366
	@CalendarWeekInYearNumber INT, --календарная неделя в году, числа 1-53
	@CalendarMonthNumber INT, -- номер месяца в году, 1-12
	@DateKey INT;
--проверки начальные
--SELECT @FirstSaturday;
--CalendarWeekInYearNumberSELECT @FifthSaturday;
--SELECT @StartYear;

---------------------Заполнение календаря------------------------------
WHILE (@Basedate <= '12-31-2014')
BEGIN
	--Находим начало фискального года
	SELECT @StartFiscalYear = dbo.FindFiscalStartYear(@Basedate);
	--Находим конец фискального года
	SELECT @EndFiscalYear = dbo.FindFiscalEndYearByStartFiscalYear(@StartFiscalYear);

WHILE (@Basedate <= @EndFiscalYear)
BEGIN
	SET @DateKey = CAST(CONVERT(VARCHAR, DATEPART(month,@BaseDate)) + CONVERT(VARCHAR, DATEPART(day,@BaseDate)) + CONVERT(VARCHAR, DATEPART(year,@BaseDate))AS INT);
	
	SET @DayOfTheWeek = DATENAME(weekday, @Basedate);	

	SET @CalendarDayInYearNumber = 
								CASE
									WHEN DATEDIFF(day,@StartFiscalYear,@Basedate) < 0 THEN 
											--Найти начало предыдущего фискального года и посчитать кол-во дней от его начала
											DATEDIFF(day,dbo.FindFiscalStartYear(DATEADD(year,-1,@StartFiscalYear)),@Basedate) + 1
									--Подсчитать кол-во дней от начала текущего фискального года
									ELSE DATEDIFF(day,@StartFiscalYear,@Basedate) + 1
								END
	SET @CalendarMonthNumber = 
								CASE 
									WHEN 	@CalendarDayInYearNumber <= 28	THEN 1
									WHEN	@CalendarDayInYearNumber <= 63 AND @CalendarDayInYearNumber >= 28 THEN 2
									WHEN	@CalendarDayInYearNumber <= 91 AND @CalendarDayInYearNumber >= 63 THEN 3
									WHEN	@CalendarDayInYearNumber <= 119 AND @CalendarDayInYearNumber >= 91 THEN 4
									WHEN	@CalendarDayInYearNumber <= 154 AND @CalendarDayInYearNumber >= 119 THEN 5
									WHEN	@CalendarDayInYearNumber <= 182 AND @CalendarDayInYearNumber >= 154 THEN 6
									WHEN	@CalendarDayInYearNumber <= 210 AND @CalendarDayInYearNumber >= 182 THEN 7
									WHEN	@CalendarDayInYearNumber <= 245 AND @CalendarDayInYearNumber >= 210 THEN 8
									WHEN	@CalendarDayInYearNumber <= 273 AND @CalendarDayInYearNumber >= 245 THEN 9
									WHEN	@CalendarDayInYearNumber <= 301 AND @CalendarDayInYearNumber >= 273 THEN 10
									WHEN	@CalendarDayInYearNumber <= 336 AND @CalendarDayInYearNumber >= 301 THEN 11
									WHEN	@CalendarDayInYearNumber <= 371 AND @CalendarDayInYearNumber >= 336 THEN 12
								END
														
								
	SET @CalendarWeekInYearNumber = @CalendarDayInYearNumber/7+1; -- Посчитываем неделю 
	--SET @CalendarDayInMonthNumber = 1; --TODO
	
	SET @CalendarDayInMonthNumber = 
								CASE 
									WHEN 	@CalendarDayInYearNumber <= 28	THEN @CalendarDayInYearNumber
									WHEN	@CalendarDayInYearNumber <= 63 AND @CalendarDayInYearNumber >= 28 THEN @CalendarDayInYearNumber - 28
									WHEN	@CalendarDayInYearNumber <= 91 AND @CalendarDayInYearNumber >= 63 THEN @CalendarDayInYearNumber - 63
									WHEN	@CalendarDayInYearNumber <= 119 AND @CalendarDayInYearNumber >= 91 THEN @CalendarDayInYearNumber - 91
									WHEN	@CalendarDayInYearNumber <= 154 AND @CalendarDayInYearNumber >= 119 THEN @CalendarDayInYearNumber - 119
									WHEN	@CalendarDayInYearNumber <= 182 AND @CalendarDayInYearNumber >= 154 THEN @CalendarDayInYearNumber - 154
									WHEN	@CalendarDayInYearNumber <= 210 AND @CalendarDayInYearNumber >= 182 THEN @CalendarDayInYearNumber - 182
									WHEN	@CalendarDayInYearNumber <= 245 AND @CalendarDayInYearNumber >= 210 THEN @CalendarDayInYearNumber - 210
									WHEN	@CalendarDayInYearNumber <= 273 AND @CalendarDayInYearNumber >= 245 THEN @CalendarDayInYearNumber - 245
									WHEN	@CalendarDayInYearNumber <= 301 AND @CalendarDayInYearNumber >= 273 THEN @CalendarDayInYearNumber - 273
									WHEN	@CalendarDayInYearNumber <= 336 AND @CalendarDayInYearNumber >= 301 THEN @CalendarDayInYearNumber - 301
									WHEN	@CalendarDayInYearNumber <= 371 AND @CalendarDayInYearNumber >= 336 THEN @CalendarDayInYearNumber - 336
								END
	
	INSERT INTO dbo.DateDim (
					DateKey,
					CalendarDate, 
					DayOfTheWeek, 
					CalendarDayInMonthNumber, 
					CalendarDayInYearNumber, 
					CalendarWeekInYearNumber, 
					CalendarMonthNumber)
	VALUES (
					@DateKey,
					@Basedate, 
					@DayOfTheWeek,
					@CalendarDayInMonthNumber,
					@CalendarDayInYearNumber,
					@CalendarWeekInYearNumber,
					@CalendarMonthNumber);
					
	SET @Basedate = DATEADD(day, 1, @Basedate);
END

END
PRINT 'Table DateDim is Filled'
GO

--Служебные
--SELECT * from dbo.DateDim ORDER BY CalendarDate
--TRUNCATE TABLE dbo.DateDim
----------------------------------------------------------------------
