--Looking at electric consumption and charges for buildings in New york City from 2012-2020. I tried different technqiues to analyze 
--the data in different ways. 


USE sql_practice
GO

SELECT *
FROM Electric_Consumption
;


--Looking at Total Charges for Each Location Per Year.


SELECT 
        Account_Name
       ,Location
	   ,DATEPART(YEAR, Service_End_Date) AS Year 
	   ,ROUND(SUM(Current_Charges),2) AS Total_Charges
FROM dbo.Electric_Consumption
WHERE location IS NOT NULL
GROUP BY Account_Name, Location, DATEPART(YEAR, Service_End_Date)
ORDER BY Account_name, Location, DATEPART(YEAR, Service_End_Date)
;


--Looking at Total Charges for Each Account per Year.



WITH Filter_1
AS
  (SELECT 
	     Account_Name
	    ,DATEPART(YEAR, Service_End_Date) As Year
	    ,ROUND(SUM(Current_Charges),2) AS Yearly_Total
  FROM dbo.Electric_Consumption
  WHERE location IS NOT NULL
    AND Current_Charges > 0
    AND DATENAME(YEAR, Service_End_Date) != 2021
  GROUP BY Account_Name, DATEPART(YEAR, Service_End_Date)
)

SELECT 
      Account_Name
	 ,Year
	 ,Yearly_Total
	 ,ROUND(SUM(Yearly_Total) OVER (PARTITION BY Account_Name),2) AS Account_Total
FROM Filter_1
ORDER BY Account_Name, Year
;


--Looking at Kilowatt Hours Used By Each LOCATION per Year


WITH Filter_1
AS
  (SELECT 
	     Account_Name
	    ,Location
	    ,DATEPART(YEAR, Service_End_Date) As Year
	    ,DATEPART(MONTH, Service_End_Date) As Month
	    ,SUM(Consumption_KWH) AS Monthly_Consumption_KWH
  FROM dbo.Electric_Consumption
  WHERE location IS NOT NULL
    AND Current_Charges > 0
    AND DATENAME(YEAR, Service_End_Date) != 2021
  GROUP BY Account_name, Location, DATEPART(YEAR, Service_End_Date), DATEPART(MONTH, Service_End_Date)
)

SELECT 
      Account_Name
	 ,Location
	 ,Year
	 ,Month
	 ,Monthly_Consumption_KWH
	 ,SUM(Monthly_Consumption_KWH) OVER (PARTITION BY Account_Name, Location, Year) AS Yearly_Consumption_KWH
FROM Filter_1
ORDER BY Account_Name, Location, Year, Month
;


--Looking at Kilowatt Hours Used By Each LOCATION per Month per Year


WITH Filter_1
AS
  (SELECT 
	     Account_Name
	    ,Location
	    ,DATEPART(YEAR, Service_End_Date) As Year
	    ,DATEPART(MONTH, Service_End_Date) As Month
	    ,SUM(Consumption_KWH) AS Monthly_Consumption_KWH
  FROM dbo.Electric_Consumption
  WHERE location IS NOT NULL
    AND Current_Charges > 0
    AND DATENAME(YEAR, Service_End_Date) != 2021
  GROUP BY Account_name, Location, DATEPART(YEAR, Service_End_Date), DATEPART(MONTH, Service_End_Date)
)

SELECT 
      Account_Name
	 ,Location
	 ,Year
	 ,Month
	 ,Monthly_Consumption_KWH
	 ,SUM(Monthly_Consumption_KWH) OVER (PARTITION BY Account_Name, Location, Year) AS Yearly_Consumption_KWH
FROM Filter_1
ORDER BY Account_name, Location, Year, Month
;


--Showing Total_Charges For Each Year as Well as the Average Cost per Month Through Out Year.


SELECT 
       Account_Name,
       Location, 
	   DATEPART(YEAR, Service_End_Date) AS Year, 
	   ROUND(SUM(Current_Charges), 2) AS Total_Charges,
	   ROUND(AVG(Current_Charges), 2) AS Avg_Per_Month
FROM dbo.Electric_Consumption
WHERE location IS NOT NULL
  AND Current_Charges > 0
  AND DATENAME(YEAR, Service_End_Date) != 2021
GROUP BY Account_Name, Location, DATEPART(YEAR, Service_End_Date)
ORDER BY Account_name, Location, DATEPART(YEAR, Service_End_Date)
;

--Find Percentage Difference Per Year for Each Building.


SELECT 
       Account_Name,
       Location, 
	   DATEPART(YEAR, Service_End_Date) AS Year, 
	   SUM(Current_Charges) AS Total_Charges,
       ROUND((SUM(Current_Charges) - LAG(SUM(Current_Charges), 1)
        OVER (PARTITION BY account_name ORDER BY location))
	     / LAG(SUM(Current_Charges), 1)
	       OVER (PARTITION BY account_name ORDER BY location)
	     * 100, 2) AS Pct_diff
FROM dbo.Electric_Consumption
WHERE location IS NOT NULL
  AND Current_Charges > 0
GROUP BY Account_Name, Location, DATEPART(YEAR, Service_End_Date)
ORDER BY Account_name, Location, DATEPART(YEAR, Service_End_Date)
;


--Using CTE to Make Previous Query More Legible.


WITH 
Filter_1 AS
  (SELECT 
         Account_Name
	    ,Location
	    ,DATENAME(YEAR, Service_End_Date) AS Year
	    ,ROUND(SUM(Current_Charges),2) AS Total_Charges
   FROM Electric_Consumption
   WHERE Location IS NOT NULL
     AND Current_Charges > 0
     AND DATENAME(YEAR, Service_End_Date) != 2021
   GROUP BY Account_Name, Location, DATENAME(YEAR, Service_End_Date)
  )
SELECT
      Account_Name
	  ,Location
	  ,Year
	  ,Total_Charges
	  ,ROUND(((Total_Charges - LAG(Total_Charges,1) OVER( PARTITION BY Account_Name, Location ORDER BY Location, Year))
	     / LAG(Total_Charges,1) OVER (PARTITION BY Account_Name, Location ORDER BY Location, Year)) 
		 * 100,2) as Pct_Diff
FROM Filter_1
ORDER BY Account_Name, Location, Year
;


--Comparing Data Consistency Using DATENAME vs. SUBSTRING
--Originally Used DATENAME to Get Date. When Looking Through Data, Some of the Data in [Service_Start_Date] Started in the Previous 
--Year, so SUBSTRING Used to Compare if Data was Consistent Through an Alternative Method.


WITH 
Filter_1 AS
  (SELECT 
         Account_Name AS A_Name_1
	    ,Location AS Location_1
	    ,DATENAME(YEAR, Service_End_Date) AS Year_1
	    ,ROUND(SUM(Current_Charges),2) AS Total_Charges_1 
   FROM Electric_Consumption
   WHERE Location IS NOT NULL
    AND Current_Charges > 0
    AND DATENAME(YEAR, Service_End_Date) != 2021
   GROUP BY Account_Name, Location, DATENAME(YEAR, Service_End_Date)
  ),

Filter_2 AS
  (SELECT 
         Account_Name as A_Name_2
	    ,Location AS Location_2
	    ,SUBSTRING(Revenue_Month,1,4) AS Year_2
	    ,ROUND(SUM(Current_Charges),2) AS Total_Charges_2
   FROM Electric_Consumption
   WHERE Location IS NOT NULL
     AND Current_Charges > 0
     AND SUBSTRING(Revenue_Month,1,4) != 2021
   GROUP BY Account_Name, Location, SUBSTRING(Revenue_Month,1,4)
  )
SELECT A_Name_1 AS Account_name
      ,Location_1 AS Location
	  ,Year_1 AS Year
	  ,Total_Charges_2 AS Total_Charges
	  ,ROUND(((Total_Charges_1 - LAG(Total_Charges_1,1) OVER( PARTITION BY A_Name_1, Location_1 ORDER BY Location_1, Year_1))
	     / LAG(Total_Charges_1,1) OVER (PARTITION BY A_Name_1, Location_1 ORDER BY Location_1, Year_1)) 
		 * 100,2) AS Pct_Diff_1
	  ,ROUND(((Total_Charges_2 - LAG(Total_Charges_2,1) OVER( PARTITION BY A_Name_2, Location_2 ORDER BY Location_2, Year_2))
	     / LAG(Total_Charges_2,1) OVER (PARTITION BY A_Name_2, Location_2 ORDER BY Location_2, Year_2)) 
		 * 100,2) AS Pct_Diff_2
FROM Filter_1
  INNER JOIN Filter_2
  ON A_Name_1 = A_Name_2 AND
  Location_1 = Location_2 AND
  Year_1 = Year_2
ORDER BY A_Name_1, Location, Year_1
;


--Stored Procedure For Report Builder and Tableau.


Drop procedure if exists Pct_Diff_Yearly
go

CREATE PROCEDURE Pct_Diff_Yearly
AS
BEGIN
WITH 
Filter_1 AS
  (SELECT 
         Account_Name as A_Name_1
	    ,Location 
	    ,DATENAME(YEAR, Service_End_Date) AS S_Year_1
	    ,ROUND(SUM(Current_Charges),2) AS Total_Charges_1
   FROM Electric_Consumption
   WHERE Location IS NOT NULL
     AND Current_Charges > 0
     AND SUBSTRING(Revenue_Month,1,4) != 2021
   GROUP BY Account_Name, Location, DATENAME(YEAR, Service_End_Date)
  ),

Filter_2 AS
  (SELECT 
         Account_Name as A_Name_2
	    ,Location AS Location_2
	    ,SUBSTRING(Revenue_Month,1,4) AS S_Year_2
	    ,ROUND(SUM(Current_Charges),2) AS Total_Charges_2
   FROM Electric_Consumption
   WHERE Location IS NOT NULL
     AND Current_Charges > 0
     AND SUBSTRING(Revenue_Month,1,4) != 2021
   GROUP BY Account_Name, Location, SUBSTRING(Revenue_Month,1,4)
  )
SELECT A_Name_1 as Account_name
      ,Location
	  ,S_Year_1 as Year
	  ,Total_Charges_2 as Total_Charges
	  ,((Total_Charges_1 - LAG(Total_Charges_1,1) OVER( PARTITION BY A_Name_1, Location ORDER BY Location, S_Year_1))
	     / LAG(Total_Charges_1,1) OVER (PARTITION BY A_Name_1, Location ORDER BY Location, S_Year_1)) 
		 * 100 as Pct_Diff_1
	  ,((Total_Charges_2 - LAG(Total_Charges_2,1) OVER( PARTITION BY A_Name_2, Location_2 ORDER BY Location_2, S_Year_2))
	     / LAG(Total_Charges_2,1) OVER (PARTITION BY A_Name_2, Location_2 ORDER BY Location_2, S_Year_2)) 
		 * 100 as Pct_Diff_2
FROM Filter_1
  INNER JOIN Filter_2
  ON A_Name_1 = A_Name_2 AND
  Location = Location_2 AND
  S_Year_1 = S_Year_2
ORDER BY A_Name_1, Location, S_Year_1
;
END
;
