--DML_script_task_1
--Alexey Kolesnikov
--03-11-2015
--SQL courses, task_1, DML Script, version 1.
-- Filling DateDim table by dates.

-- Найдем первую субботу в году
USE SQL_Courses_AKolesnikov
GO
DECLARE @StartYear DATE = '01-01-2002',
	@FirstSaturday DATE,
	@FifthSaturday DATE,
	@StartFiscalYear DATE,
	@EndFiscalYear DATE,
	--
	@Offset   INT, --счетчик primary key
	@Basedate DATE, -- дата
	@DayOfTheWeek nvarchar(10), --название недели на англ
	@CalendarDayInMonthNumber INT, --календарный день в месяце, числа 1-31
	@CalendarDayInYearNumber INT, --календарный день в месяце, числа 1-366
	@CalendarWeekInYearNumber INT, --календарная неделя в году, числа 1-53
	@CalendarMonthNumber INT; -- номер месяца в году, 1-12

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

SET @StartYear = 
			CASE -- Назначим стартовый день года в зависимости от  <  > 29го дня года
				WHEN DATEDIFF (day, @StartYear, @FifthSaturday) <= 29 THEN DATEADD(day,28,@FirstSaturday)
				ELSE DATEADD(day,35,@FirstSaturday)
			END		
SELECT @StartYear;
--проверки начальные
--SELECT @FirstSaturday;
--CalendarWeekInYearNumberSELECT @FifthSaturday;
--SELECT @StartYear;

---------------------Заполнение календаря------------------------------

SELECT
  --@Basedate = '01-01-2002',  -- Стартовый день (тест)
  @Basedate = @StartYear,
  @offset = 1			  -- Счетчик цикла

-- Тест
--	SET @DayOfTheWeek =	 DATENAME(weekday, @Basedate)
--	SET @DayOfTheWeek =	 DATENAME(weekday, convert(datetime, @Basedate, 110))
--	SELECT @DayOfTheWeek

WHILE (@Basedate <= '2014-01-31') -- добавление порядковых номеров и дат
BEGIN
	SET @DayOfTheWeek = DATENAME(weekday, @Basedate);	
	SET @CalendarDayInMonthNumber = 1; -- TODO
	SET @CalendarDayInYearNumber = 1; -- TODO
	SET @CalendarWeekInYearNumber = 1; --TODO
	SET @CalendarMonthNumber = 1; --TODO
	INSERT INTO dbo.DateDim (
					CalendarDate, 
					DayOfTheWeek, 
					CalendarDayInMonthNumber, 
					CalendarDayInYearNumber, 
					CalendarWeekInYearNumber, 
					CalendarMonthNumber)
	VALUES (
					@Basedate, 
					@DayOfTheWeek,
					@CalendarDayInMonthNumber,
					@CalendarDayInYearNumber,
					@CalendarWeekInYearNumber,
					@CalendarMonthNumber);
	
	SET @Offset = @Offset + 1
	SET @Basedate = DATEADD(DAY, 1, @Basedate)
END
PRINT 'Table DateDim is Filled'


--Служебные
--SELECT * from dbo.DateDim


