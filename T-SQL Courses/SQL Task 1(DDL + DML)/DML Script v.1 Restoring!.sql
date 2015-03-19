--DML_script_task_1
--Alexey Kolesnikov
--03-11-2015
--SQL courses, task_1, DML Script, version 1.
-- Filling DateDim table by dates.

USE SQL_Courses_AKolesnikov
GO
DECLARE 
	@StartCalendarYear DATE, -- Начало календарного года
	@FirstSaturday DATE, -- Первая суббота (возможно больше не нужна)
	@FifthSaturday DATE, -- Пятая суббота
	@StartFiscalYear DATE, -- Начало фискального года
	@EndFiscalYear DATE, -- Конец фискального года
	@StartNextFiscalYear DATE, -- Начало следующего фискального года (нужно для подсчета конца фискального года)
	--
	@DateKey INT,
	@DateKeyForm VARCHAR,
	@Basedate DATE = '01-01-2002', -- дата
	@DayOfTheWeek NVARCHAR(10), --название недели на англ
	@CalendarDayInMonthNumber INT, --календарный день в месяце, числа 1-31
	@CalendarDayInYearNumber INT, --календарный день в месяце, числа 1-366
	@CalendarWeekInYearNumber INT, --календарная неделя в году, числа 1-53
	@CalendarMonthNumber INT, -- номер месяца в году, 1-12
	@CalendarQuarter INT, -- порядковый номер квартала в календарном году. Допустимые значения 1-5 
	@CalendarYear INT, -- календарный год
	@CalendarMonthStartFlag BIT, -- битовое поле. 1, если день приходится на начало календарного месяца, иначе 0.
	@CalendarMonthEndFlag BIT, -- битовое поле. 1, если день приходится на конец календарного месяца, иначе 0. 
	@CalendarMonthStartDate DATE, -- дата начала календарного месяца, к которому принадлежит текущая дата. 
	@CalendarMonthEndDate DATE, -- дата окончания календарного месяца, к которому принадлежит текущая дата. 
	@FiscalDayInYearNumber INT, -- целочисленное поле. Порядковый номер дня в фискальном году. Допустимые значения - 1-371 
	@FiscalWeekInYearNumber INT, -- порядковый номер недели в фискальном месяце. Допустимые значения 1-53
	@FiscalMonthNumber INT, -- порядковый номер месяца в фискальном году. Допустимые значения 1-12 
	@FiscalQuarter INT, -- порядковый номер квартала в фискальном году. Допустимые значения 1-5 
	@FiscalYear INT, -- фискальный год
	@FiscalMonthStartFlag BIT, -- битовое поле. 1, если день приходится на начало фискального месяца, иначе 0.
	@FiscalMonthEndFlag BIT, -- битовое поле. 1, если день приходится на конец фискального месяца, иначе 0. 
	@FiscalMonthStartDate DATE, -- поле типа DATE. Дата начала фискального месяца, к которому принадлежит текущая дата. 
	@FiscalMonthEndDate DATE, -- поле типа DATE. Дата окончания фискального месяца, к которому принадлежит текущая дата. 
	@RelativeDay INT, -- целочисленное поле. количество дней от\до сегодняшней даты. 0 для сегодняшнего дня, отрицательное значение для прошлых дат, положительное - для будущих.
	@RelativeWeek INT -- целочисленное поле. количество недель от\до сегодняшней даты. 0 для текущей недели, отрицательное значение для прошлых дат, положительное - для будущих.
	
--проверки начальные
--SELECT @FirstSaturday;
--CalendarWeekInYearNumberSELECT @FifthSaturday;
--SELECT @StartYear;

---------------------Заполнение календаря------------------------------
WHILE (@Basedate <= '12-31-2014')
BEGIN
	--Находим начало фискального года
	SELECT @StartFiscalYear = dbo.FindFiscalStartYearByBaseDate(@Basedate);
	
	-- Если наша дата не входит в период найденного фискального года (а бывает это с 01-01-2002 по начало фискального года и входит он в период предыдущего фискального года)

	
	IF (@Basedate >= @StartFiscalYear)
		BEGIN
			--Находим конец фискального года
			SELECT @EndFiscalYear = dbo.FindFiscalEndYearByBaseDate(@Basedate);
		END
	ELSE
		BEGIN
			-- То надо найти начало и конец предыдущего фискального года, в который входит наша текущая дата.
			-- Конец пред фиск года на 1 день раньше начала нового фискального года.
			SELECT @EndFiscalYear = DATEADD(DAY,-1,@StartFiscalYear);
			SELECT @StartFiscalYear = dbo.FindFiscalStartYearByBaseDate(DATEADD(YEAR,-1,@Basedate));
			
		END

WHILE (@Basedate <= @EndFiscalYear)
BEGIN
	SET @DateKey = dbo.FormDateKey(@Basedate); 
	
	SET @DayOfTheWeek = DATENAME(weekday, @Basedate);	
	
	SET @StartCalendarYear = CAST('01-01-' + CONVERT(VARCHAR, DATEPART(year,@BaseDate))AS DATE);
	
	--Calendar dates
	SET @CalendarDayInMonthNumber = DATEPART(DAY,@Basedate);

	SET @CalendarDayInYearNumber = DATEDIFF(DAY, @StartCalendarYear,@Basedate) + 1;

	SET @CalendarWeekInYearNumber = @CalendarDayInYearNumber / 7 + 1; -- Посчитываем неделю 
	
	SET @CalendarMonthNumber = DATEPART(MONTH,@Basedate);

	SET @CalendarQuarter = DATEPART(QUARTER,@Basedate);
	
	SET @CalendarYear = DATEPART(YEAR,@Basedate);

	SET @CalendarMonthStartDate = CAST(CONVERT(VARCHAR, DATEPART(MONTH,@BaseDate)) + '-01-' + CONVERT(VARCHAR, DATEPART(YEAR,@BaseDate))AS DATE);
	
	SET @CalendarMonthEndDate = DATEADD(day,-1,DATEADD(MONTH,1,@CalendarMonthStartDate)); -- прибавляем месяц к старту месяца и вычитаем 1 день
	
	SET @CalendarMonthStartFlag = 
								CASE
									WHEN @CalendarMonthStartDate = @BaseDate THEN 1
									ELSE 0
								END;
	
	SET @CalendarMonthEndFlag = 
								CASE 
									WHEN @CalendarMonthEndDate = @BaseDate THEN 1
									ELSE 0
								END;
								
	--Fiscal dates
	SET @FiscalDayInYearNumber = 
								CASE
									WHEN DATEDIFF(day,@StartFiscalYear,@Basedate) < 0 THEN 
											--Найти начало предыдущего фискального года и посчитать кол-во дней от его начала
											DATEDIFF(day,dbo.FindFiscalStartYear(DATEADD(year,-1,@StartFiscalYear)),@Basedate) + 1
									--Подсчитать кол-во дней от начала текущего фискального года
									ELSE DATEDIFF(day,@StartFiscalYear,@Basedate) + 1
								END
	
	SET @FiscalWeekInYearNumber = @FiscalDayInYearNumber / 7 + 1;
	
	SET @FiscalMonthNumber = 
								CASE 
									WHEN 	@FiscalDayInYearNumber <= 28	THEN 1
									WHEN	@FiscalDayInYearNumber <= 63 AND @FiscalDayInYearNumber >= 28 THEN 2
									WHEN	@FiscalDayInYearNumber <= 91 AND @FiscalDayInYearNumber >= 63 THEN 3
									WHEN	@FiscalDayInYearNumber <= 119 AND @FiscalDayInYearNumber >= 91 THEN 4
									WHEN	@FiscalDayInYearNumber <= 154 AND @FiscalDayInYearNumber >= 119 THEN 5
									WHEN	@FiscalDayInYearNumber <= 182 AND @FiscalDayInYearNumber >= 154 THEN 6
									WHEN	@FiscalDayInYearNumber <= 210 AND @FiscalDayInYearNumber >= 182 THEN 7
									WHEN	@FiscalDayInYearNumber <= 245 AND @FiscalDayInYearNumber >= 210 THEN 8
									WHEN	@FiscalDayInYearNumber <= 273 AND @FiscalDayInYearNumber >= 245 THEN 9
									WHEN	@FiscalDayInYearNumber <= 301 AND @FiscalDayInYearNumber >= 273 THEN 10
									WHEN	@FiscalDayInYearNumber <= 336 AND @FiscalDayInYearNumber >= 301 THEN 11
									WHEN	@FiscalDayInYearNumber <= 371 AND @FiscalDayInYearNumber >= 336 THEN 12
								END
														
	SET @FiscalQuarter	= 
								CASE
									WHEN	@FiscalDayInYearNumber < 91 THEN 1
									WHEN	@FiscalDayInYearNumber >= 91 AND @FiscalDayInYearNumber < 182 THEN 2
									WHEN	@FiscalDayInYearNumber >= 182 AND @FiscalDayInYearNumber < 273 THEN 3
									WHEN	@FiscalDayInYearNumber >= 273 AND @FiscalDayInYearNumber < 371 THEN 4
								END

	SET @FiscalYear =	DATEPART(YEAR,@StartFiscalYear);

	SET @FiscalMonthStartFlag = 
								CASE
									WHEN 	
									@FiscalDayInYearNumber = 1
									OR @FiscalDayInYearNumber = 29	
									OR	@FiscalDayInYearNumber = 64 
									OR	@FiscalDayInYearNumber = 92 
									OR	@FiscalDayInYearNumber = 120 
									OR	@FiscalDayInYearNumber = 155 
									OR	@FiscalDayInYearNumber = 182 
									OR	@FiscalDayInYearNumber = 211 
									OR	@FiscalDayInYearNumber = 246 
									OR	@FiscalDayInYearNumber = 274 
									OR	@FiscalDayInYearNumber = 302 
									OR	@FiscalDayInYearNumber = 337 
									THEN 1
									ELSE 0
								END;
	
	SET @FiscalMonthEndFlag = 
								CASE 
									WHEN 	@FiscalDayInYearNumber = 28	
									OR	@FiscalDayInYearNumber = 63 
									OR	@FiscalDayInYearNumber = 91 
									OR	@FiscalDayInYearNumber = 119 
									OR	@FiscalDayInYearNumber = 154 
									OR	@FiscalDayInYearNumber = 182 
									OR	@FiscalDayInYearNumber = 210 
									OR	@FiscalDayInYearNumber = 245 
									OR	@FiscalDayInYearNumber = 273 
									OR	@FiscalDayInYearNumber = 301 
									OR	@FiscalDayInYearNumber = 336 
									OR	(@FiscalDayInYearNumber = 364 AND DATEDIFF(DAY,@StartFiscalYear, @EndFiscalYear) = 364)
									OR	(@FiscalDayInYearNumber = 371 AND DATEDIFF(DAY,@StartFiscalYear, @EndFiscalYear) = 371)
									THEN 1
									ELSE 0
								END
	
	SET @FiscalMonthStartDate = 
	CASE 
									WHEN 	@FiscalDayInYearNumber <= 28	THEN @StartFiscalYear
									WHEN	@FiscalDayInYearNumber <= 63 AND @FiscalDayInYearNumber >= 28 THEN DATEADD(DAY, 28, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 91 AND @FiscalDayInYearNumber >= 63 THEN DATEADD(DAY, 63, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 119 AND @FiscalDayInYearNumber >= 91 THEN DATEADD(DAY, 91, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 154 AND @FiscalDayInYearNumber >= 119 THEN DATEADD(DAY, 119, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 182 AND @FiscalDayInYearNumber >= 154 THEN DATEADD(DAY, 154, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 210 AND @FiscalDayInYearNumber >= 182 THEN DATEADD(DAY, 182, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 245 AND @FiscalDayInYearNumber >= 210 THEN DATEADD(DAY, 210, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 273 AND @FiscalDayInYearNumber >= 245 THEN DATEADD(DAY, 245, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 301 AND @FiscalDayInYearNumber >= 273 THEN DATEADD(DAY, 273, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 336 AND @FiscalDayInYearNumber >= 301 THEN DATEADD(DAY, 301, @StartFiscalYear) 
									WHEN	@FiscalDayInYearNumber <= 371 AND @FiscalDayInYearNumber >= 336 THEN DATEADD(DAY, 336, @StartFiscalYear) 
								END
	
	SET @FiscalMonthEndDate = '01-01-2002'
								--CASE 
								--	WHEN 	@FiscalDayInYearNumber <= 28	THEN DATEADD(DAY,27,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 63 AND @FiscalDayInYearNumber >= 28 THEN DATEADD(DAY,62,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 91 AND @FiscalDayInYearNumber >= 63 THEN DATEADD(DAY,90,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 119 AND @FiscalDayInYearNumber >= 91 THEN DATEADD(DAY,118,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 154 AND @FiscalDayInYearNumber >= 119 THEN DATEADD(DAY,153,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 182 AND @FiscalDayInYearNumber >= 154 THEN DATEADD(DAY,181,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 210 AND @FiscalDayInYearNumber >= 182 THEN DATEADD(DAY,209,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 245 AND @FiscalDayInYearNumber >= 210 THEN DATEADD(DAY,244,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 273 AND @FiscalDayInYearNumber >= 245 THEN DATEADD(DAY,272,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 301 AND @FiscalDayInYearNumber >= 273 THEN DATEADD(DAY,300,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 336 AND @FiscalDayInYearNumber >= 301 THEN DATEADD(DAY,335,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 364 AND @FiscalDayInYearNumber >= 336 AND (DATEDIFF(DAY,@StartFiscalYear,@EndFiscalYear) = 364) THEN DATEADD(DAY,363,@StartFiscalYear) 
								--	WHEN	@FiscalDayInYearNumber <= 371 AND @FiscalDayInYearNumber >= 336 AND (DATEDIFF(DAY,@StartFiscalYear,@EndFiscalYear) = 371) THEN DATEADD(DAY,370,@StartFiscalYear) 
								--END
	
	SET @RelativeDay = 
						CASE
							WHEN @Basedate > GETDATE() THEN -DATEDIFF(DAY, @Basedate, GETDATE())
							ELSE DATEDIFF(DAY, @Basedate, GETDATE())
						END;
	
	SET @RelativeWeek =  @RelativeDay / 7;
	
	INSERT INTO dbo.DateDim 
	(
	DateKey,
    CalendarDate, 
	DayOfTheWeek, --название недели на англ
	CalendarDayInMonthNumber, --календарный день в месяце, числа 1-31
	CalendarDayInYearNumber, --календарный день в месяце, числа 1-366
	CalendarWeekInYearNumber, --календарная неделя в году, числа 1-53
	CalendarMonthNumber, -- номер месяца в году, 1-12
	CalendarQuarter, -- порядковый номер квартала в календарном году. Допустимые значения 1-5 
	CalendarYear, -- календарный год
	CalendarMonthStartFlag, -- битовое поле. 1, если день приходится на начало календарного месяца, иначе 0.
	CalendarMonthEndFlag, -- битовое поле. 1, если день приходится на конец календарного месяца, иначе 0. 
	CalendarMonthStartDate, -- дата начала календарного месяца, к которому принадлежит текущая дата. 
	CalendarMonthEndDate, -- дата окончания календарного месяца, к которому принадлежит текущая дата. 
	FiscalDayInYearNumber, -- целочисленное поле. Порядковый номер дня в фискальном году. Допустимые значения - 1-371 
	FiscalWeekInYearNumber, -- порядковый номер недели в фискальном месяце. Допустимые значения 1-53
	FiscalMonthNumber, -- порядковый номер месяца в фискальном году. Допустимые значения 1-12 
	FiscalQuarter, -- порядковый номер квартала в фискальном году. Допустимые значения 1-5 
	FiscalYear, -- фискальный год
	FiscalMonthStartFlag, -- битовое поле. 1, если день приходится на начало фискального месяца, иначе 0.
	FiscalMonthEndFlag, -- битовое поле. 1, если день приходится на конец фискального месяца, иначе 0. 
	FiscalMonthStartDate, -- поле типа DATE. Дата начала фискального месяца, к которому принадлежит текущая дата. 
	FiscalMonthEndDate, -- поле типа DATE. Дата окончания фискального месяца, к которому принадлежит текущая дата. 
	RelativeDay, -- целочисленное поле. количество дней от\до сегодняшней даты. 0 для сегодняшнего дня, отрицательное значение для прошлых дат, положительное - для будущих.
	RelativeWeek -- целочисленное поле. количество недель от\до сегодняшней даты. 0 для текущей недели, отрицательное значение для прошлых дат, положительное - для будущих.
	)
	VALUES 
	(
	@DateKey,
	@Basedate, -- дата
	@DayOfTheWeek, --название недели на англ
	@CalendarDayInMonthNumber, --календарный день в месяце, числа 1-31
	@CalendarDayInYearNumber, --календарный день в месяце, числа 1-366
	@CalendarWeekInYearNumber, --календарная неделя в году, числа 1-53
	@CalendarMonthNumber, -- номер месяца в году, 1-12
	@CalendarQuarter, -- порядковый номер квартала в календарном году. Допустимые значения 1-5 
	@CalendarYear, -- календарный год
	@CalendarMonthStartFlag, -- битовое поле. 1, если день приходится на начало календарного месяца, иначе 0.
	@CalendarMonthEndFlag, -- битовое поле. 1, если день приходится на конец календарного месяца, иначе 0. 
	@CalendarMonthStartDate, -- дата начала календарного месяца, к которому принадлежит текущая дата. 
	@CalendarMonthEndDate, -- дата окончания календарного месяца, к которому принадлежит текущая дата. 
	@FiscalDayInYearNumber, -- целочисленное поле. Порядковый номер дня в фискальном году. Допустимые значения - 1-371 
	@FiscalWeekInYearNumber, -- порядковый номер недели в фискальном месяце. Допустимые значения 1-53
	@FiscalMonthNumber, -- порядковый номер месяца в фискальном году. Допустимые значения 1-12 
	@FiscalQuarter, -- порядковый номер квартала в фискальном году. Допустимые значения 1-5 
	@FiscalYear, -- фискальный год
	@FiscalMonthStartFlag, -- битовое поле. 1, если день приходится на начало фискального месяца, иначе 0.
	@FiscalMonthEndFlag, -- битовое поле. 1, если день приходится на конец фискального месяца, иначе 0. 
	@FiscalMonthStartDate, -- поле типа DATE. Дата начала фискального месяца, к которому принадлежит текущая дата. 
	@FiscalMonthEndDate, -- поле типа DATE. Дата окончания фискального месяца, к которому принадлежит текущая дата. 
	@RelativeDay, -- целочисленное поле. количество дней от\до сегодняшней даты. 0 для сегодняшнего дня, отрицательное значение для прошлых дат, положительное - для будущих.
	@RelativeWeek -- целочисленное поле. количество недель от\до сегодняшней даты. 0 для текущей недели, отрицательное значение для прошлых дат, положительное - для будущих.
	);
					
	SET @Basedate = DATEADD(day, 1, @Basedate);
END

END
PRINT 'Table DateDim is Filled'
GO

--Служебные
--SELECT * from dbo.DateDim ORDER BY CalendarDate
--TRUNCATE TABLE dbo.DateDim
----------------------------------------------------------------------
