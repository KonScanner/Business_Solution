ALTER DATABASE AssignmentPart1 
SET  COMPATIBILITY_LEVEL=130
GO


--BEGIN TRANSACTION TransformDataBase
--       WITH MARK N'Creating the tables of the data base in 3NF and deleting the old tables';  
USE AssignmentPart1;  


-------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	   ProductCode,
	   CASE 
	       WHEN Features IS NULL THEN ''
		   ELSE Features
	   END AS Features
INTO temptable1
FROM Product
GROUP BY ProductCode, Features;

SELECT 
	   t.ProductCode,
	   t.Features AS Feat
	   ,RTRIM(LTRIM(v1.value)) AS Features
INTO tempFeatures 
FROM temptable1 AS t CROSS APPLY STRING_SPLIT(Features, '|') AS v1;


SELECT ProductCode,
       Features,
       CASE 
           WHEN Features LIKE '%lining%' OR Features LIKE '%lined%' OR Features LIKE '%[%]%' THEN Features
		   ELSE NULL
	   END AS compositionFeature,
	   CASE
	       WHEN Features LIKE '%Available in%' AND Features NOT LIKE '%size%' AND Features NOT LIKE '%online%' AND Features NOT LIKE '%also%' THEN Features
		   WHEN Features LIKE '%colour%' AND Features NOT LIKE '%sale%' AND Features NOT LIKE '%photo%' THEN Features
		   WHEN Features like '%Choose from Burgundy%' THEN Features
		   WHEN Features like '%Choose from either blue or pink%' THEN Features
		   WHEN Features like '%Denim Marl.%' THEN Features
		   WHEN Features LIKE '%Hot Pink.%' THEN Features
		   WHEN Features = 'Navy.' THEN Features
		   WHEN Features LIKE '%Pink.%' OR Features LIKE '%Pale Pink/%' THEN Features
		   ELSE NULL
	  END AS colourFeature,
	  CASE
	      WHEN (Features LIKE '%age%' OR Features LIKE '%months%' OR Features LIKE '%mths%' 
		       OR Features LIKE '%birth%' OR Features LIKE '%years%' OR Features LIKE '%month%')
		       AND Features NOT LIKE '%page%' AND Features NOT LIKE '%luggage%' 
			   AND Features NOT LIKE '%colour%' AND Features NOT LIKE '%storage%' 
			   AND Features NOT LIKE '%pregnancy%' THEN Features
		  ELSE NULL
	  END AS ageFeature,
	  CASE 
	      WHEN Features LIKE '%minutes%' OR Features LIKE '%mins%' THEN Features
		  ELSE NULL
	  END AS timeFeature,
	  CASE
	      WHEN Features LIKE '%kg%' AND Features LIKE '%weigh%' THEN Features
		  ELSE NULL
	  END AS weightFeature,
	  CASE
	      WHEN (Features LIKE '%cm%' OR Features LIKE '%quot%' OR Features LIKE '%square%' OR Features LIKE '%size%' OR Features LIKE '%metres%' OR Features LIKE '%mm%') 
		  AND Features NOT LIKE '%fit%' AND Features NOT LIKE '%love%' AND Features NOT LIKE '%Toy%' AND Features NOT LIKE '%trimester%' THEN Features
		  ELSE NULL
	  END AS lengthSizeFeature
INTO tempFeatures2
FROM tempFeatures;


SELECT 
	   ProductCode,
	   STRING_AGG(compositionFeature, ' ') AS compositionFeature,
	   STRING_AGG(colourFeature, ' ') AS colourFeature,
	   STRING_AGG(ageFeature, ' ') AS ageFeature,
	   STRING_AGG(timeFeature, ' ') AS timeFeature,
	   STRING_AGG(weightFeature, ' ') AS weightFeature,
	   STRING_AGG(lengthSizeFeature, ' ') AS lengthSizeFeature,
	   STRING_AGG(CASE
	       WHEN Features = compositionFeature THEN NULL
		   WHEN Features = colourFeature THEN NULL
		   WHEN Features = ageFeature THEN NULL
		   WHEN Features = timeFeature THEN NULL
		   WHEN Features = weightFeature THEN NULL
		   WHEN Features = lengthSizeFeature THEN NULL
		   WHEN Features = '' THEN NULL
           ELSE Features
	   END, ' ') AS descriptionFeature
INTO tempFeatures3 
FROM tempFeatures2
GROUP BY ProductCode;

SELECT p.ProductGroup,
	   p.ProductCode,
	   p.VariantCode,
	   p.Name,
	   CASE 
	       WHEN p.Cup = '' THEN NULL 
		   ELSE p.Cup
	   END AS Cup,
	   CASE 
	       WHEN p.Size = '' THEN NULL 
		   WHEN p.Size = '0' THEN '00'
		   ELSE p.Size
	   END AS Size,
	   CASE
	       WHEN p.LegLength = '' THEN NULL 
		   ELSE p.LegLength
	   END AS LegLength,
	   CASE
	       WHEN p.Colour = '' THEN NULL
		   ELSE p.Colour
	   END AS Colour,
	   p.Price,
	   p.Description,
	   t3.compositionFeature,
	   t3.colourFeature,
	   t3.ageFeature,
	   t3.timeFeature,
	   t3.weightFeature,
	   t3.lengthSizeFeature,
	   t3.descriptionFeature
INTO Product_Temp
FROM Product AS p
JOIN tempFeatures3 AS t3 ON p.ProductCode = t3.ProductCode; 
DROP TABLE IF EXISTS temptable1;
DROP TABLE IF EXISTS tempFeatures;
DROP TABLE IF EXISTS tempFeatures2;
DROP TABLE IF EXISTS tempFeatures3;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


BEGIN TRANSACTION Product3NF
       WITH MARK N'Creating the temporary tables of the Product Table in 3NF';
PRINT N'Product3NF'

BEGIN TRY

IF NOT (SELECT count(*) FROM Product) = (SELECT count(*) FROM Product_Temp)
THROW 50001, 'Tables seem not to have the same amount of columns after Feature Transformation', 1


SELECT VariantCode,
       ProductCode,
	   Cup,
	   Size,
	   LegLength,
	   Colour,
	   Price
INTO ProductDetail_Temp 
FROM Product_Temp 
GROUP BY VariantCode,
       ProductCode,
	   Cup,
	   Size,
	   LegLength,
	   Colour,
	   Price;

SELECT ProductCode,
       Name,
	   Description,
	   compositionFeature,
	   colourFeature,
	   ageFeature,
	   timeFeature,
	   weightFeature,
	   lengthSizeFeature,
	   descriptionFeature
INTO ProductInfo_Temp 
FROM Product_Temp 
GROUP BY ProductCode,
       Name,
	   Description,
	   compositionFeature,
	   colourFeature,
	   ageFeature,
	   timeFeature,
	   weightFeature,
	   lengthSizeFeature,
	   descriptionFeature;



DROP TABLE Product_Temp;
COMMIT TRANSACTION Product3NF
END TRY

BEGIN CATCH
PRINT N'Something went wrong with the 3NF of Product:'
PRINT ERROR_MESSAGE()
ROLLBACK TRANSACTION Product3NF
END CATCH;
GO

BEGIN TRANSACTION OtherTables3NF
       WITH MARK N'Creating the temporary tables of the Customercity and OrderItem Table in 3NF';
PRINT N'OtherTables3NF'


BEGIN TRY
SELECT a.OrderNumber, 
       a.OrderCreateDate,
   	   a.OrderStatusCode,
	   a.BillingCurrency,
	   a.CustomerCityId,
	   b.TotalLineItems,
	   b.SavedTotal
INTO OrderGroup_Temp
FROM (SELECT OrderNumber, OrderCreateDate, OrderStatusCode, BillingCurrency, CustomerCityId FROM OrderItem GROUP BY OrderNumber, OrderCreateDate, OrderStatusCode, BillingCurrency, CustomerCityId) AS a
JOIN (SELECT OrderNumber, SUM(Quantity) AS TotalLineItems, SUM(LineItemTotal) AS SavedTotal FROM OrderItem GROUP BY OrderNumber) AS b ON a.OrderNumber = b.OrderNumber;

SELECT OrderItemNumber,
       OrderNumber,
	   ProductGroup,
	   VariantCode,
	   Quantity,
	   LineItemTotal
INTO NewOrderItem_Temp
FROM OrderItem 
GROUP BY OrderItemNumber,
         OrderNumber,
		 ProductGroup,
		 VariantCode,
		 Quantity,
		 LineItemTotal;

SELECT Id AS CustomerCityId,
       Gender,
	   FirstName,
	   LastName,
	   DateRegistered,
	   City
INTO Customer_Temp
FROM CustomerCity
GROUP BY Id,
         Gender,
		 FirstName,
		 LastName,
		 DateRegistered,
		 City;

SELECT City,
       County
INTO LocationCity_Temp
FROM CustomerCity
GROUP BY City,
         County;

SELECT County,
       Region
INTO LocationCounty_Temp
FROM CustomerCity
GROUP BY County,
         Region;

SELECT Region,
       Country
INTO LocationRegion_Temp
FROM CustomerCity
GROUP BY Region,
         Country;

SELECT ProductGroup,
       VariantCode
INTO ProductGroup_Temp
FROM Product
GROUP BY ProductGroup,
         VariantCode;

COMMIT TRANSACTION OtherTables3NF
END TRY

BEGIN CATCH
PRINT N'Something went wrong with the 3NF of the CustomerCity and OrderItem tables:'
PRINT ERROR_MESSAGE()
ROLLBACK TRANSACTION OtherTables3NF
END CATCH;
GO


BEGIN TRANSACTION CreateTables
       WITH MARK N'Creating the final tables of the data base in 3NF';
PRINT N'CreateTables'


USE [AssignmentPart1]
GO

/****** Object:  Table [dbo].[Location]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LocationRegion](
	[Region] [varchar](32) NOT NULL,
	[Country] [varchar](32) NOT NULL
CONSTRAINT [PK_LocationRegion] PRIMARY KEY CLUSTERED 
(
	[Region]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[Location]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LocationCounty](
	[County] [varchar](32) NOT NULL,
	[Region] [varchar](32) NOT NULL FOREIGN KEY REFERENCES LocationRegion(Region)
CONSTRAINT [PK_LocationCounty] PRIMARY KEY CLUSTERED 
(
	[County]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Location]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LocationCity](
	[City] [varchar](32) NOT NULL,
	[County] [varchar](32) NOT NULL FOREIGN KEY REFERENCES LocationCounty(County)
CONSTRAINT [PK_LocationCity] PRIMARY KEY CLUSTERED 
(
	[City]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Customer]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Customer](
	[CustomerCityId] INTEGER NOT NULL,
	[Gender] [varchar](32) NOT NULL,
	[FirstName] [varchar](64) NOT NULL,
	[LastName] [varchar](64) NOT NULL,
	[DateRegistered] DATETIME NOT NULL,
	[City] [varchar](32) NOT NULL FOREIGN KEY REFERENCES LocationCity(City)
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustomerCityId]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[OrderGroup]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OrderGroup](
	[OrderNumber] [nvarchar](32) NOT NULL,
	[OrderCreateDate] DATETIME NOT NULL,
	[OrderStatusCode] INTEGER NOT NULL,
	[BillingCurrency] [varchar](32) NOT NULL,
	[CustomerCityId] INTEGER NOT NULL FOREIGN KEY REFERENCES Customer(CustomerCityId),
	[TotalLineItems] INTEGER NOT NULL,
	[SavedTotal] MONEY NOT NULL
 CONSTRAINT [PK_OrderGroup] PRIMARY KEY CLUSTERED 
(
	[OrderNumber]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE OrderGroup  
ADD CONSTRAINT check_PKSchemaGroup CHECK (Ordernumber LIKE '%OR\%' AND substring(LTRIM(RTRIM(OrderNumber)),12,1) = '\'  AND LEN(LTRIM(RTRIM(OrderNumber))) = 14);  

/****** Object:  Table [dbo].[ProductInfo]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProductInfo](
	[ProductCode] [nvarchar](255) NOT NULL,
	[Name] [varchar](64) NOT NULL,
	[Description] [varchar](4000) NULL,
	[compositionFeature] [varchar](4000) NULL,
	[colourFeature] [varchar](4000) NULL,
	[ageFeature] [varchar](4000) NULL,
	[timeFeature] [varchar](4000) NULL,
	[weightFeature] [varchar](4000) NULL,
	[lengthSizeFeature] [varchar](4000) NULL,
	[descriptionFeature] [varchar](4000) NULL
 CONSTRAINT [PK_ProductInfo] PRIMARY KEY CLUSTERED 
(
	[ProductCode]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[ProductDetail]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProductDetail](
	[VariantCode] [nvarchar](255) NOT NULL,
	[ProductCode] [nvarchar](255) NOT NULL FOREIGN KEY REFERENCES ProductInfo(ProductCode),
	[Cup] [varchar](255) NULL,
	[Size] [varchar](255) NULL,
	[LegLength] [varchar](255) NULL,
	[Colour] [varchar](255) NULL,
	[Price] MONEY NOT NULL
CONSTRAINT [PK_ProductDetail] PRIMARY KEY CLUSTERED 
(
	[VariantCode]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[ProductGroup]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProductGroup](
	[ProductGroup] [nvarchar](128) NOT NULL,
	[VariantCode] [nvarchar](255) NOT NULL FOREIGN KEY REFERENCES ProductDetail(VariantCode)
CONSTRAINT [PK_ProductGroup] PRIMARY KEY CLUSTERED 
(
	[ProductGroup], [VariantCode]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[OrderItem]   ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OrderItem_new](
	[OrderItemNumber] [nvarchar](32) NOT NULL,
	[OrderNumber] [nvarchar](32) NOT NULL FOREIGN KEY REFERENCES OrderGroup(OrderNumber),
	[ProductGroup] [nvarchar](128),
	[VariantCode] [nvarchar](255),
	[Quantity] INTEGER NOT NULL,
	[LineItemTotal] MONEY NOT NULL,
FOREIGN KEY (ProductGroup, VariantCode) REFERENCES ProductGroup(ProductGroup, VariantCode),
CONSTRAINT [PK_OrderItem] PRIMARY KEY CLUSTERED 
(
	[OrderItemNumber]
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE OrderItem_new
ADD CONSTRAINT check_PKSchemaItem CHECK (OrderItemNumber LIKE CONCAT('%',RTRIM(LTRIM(OrderNumber)),'%'));  
GO

COMMIT TRANSACTION CreateTables
GO


BEGIN TRANSACTION InsertData 
        WITH MARK N'Inserting the data into our new tables'
PRINT N'InsertData'

BEGIN TRY
INSERT INTO LocationRegion
SELECT * FROM LocationRegion_Temp;

INSERT INTO LocationCounty
SELECT * FROM LocationCounty_Temp;

INSERT INTO LocationCity
SELECT * FROM LocationCity_Temp;

INSERT INTO Customer
SELECT * FROM Customer_Temp;

INSERT INTO OrderGroup
SELECT * FROM OrderGroup_Temp;

INSERT INTO ProductInfo
SELECT * FROM ProductInfo_Temp;

INSERT INTO ProductDetail
SELECT * FROM ProductDetail_Temp;

INSERT INTO ProductGroup
SELECT * FROM ProductGroup_Temp;

INSERT INTO OrderItem_new
SELECT * FROM NewOrderItem_Temp;

COMMIT TRANSACTION InsertData
END TRY

BEGIN CATCH 
PRINT N'Something went wrong with the data insertion'
PRINT ERROR_MESSAGE()
ROLLBACK TRANSACTION InsertData
END CATCH;
GO

--EVTL. TESTING

BEGIN TRANSACTION DropOldTables
        WITH MARK N'Dropping the old tables and temporary tables';
		PRINT N'DropOldTables'

DROP TABLE CustomerCity;
DROP TABLE OrderItem;
DROP TABLE Product;

EXEC sp_rename OrderItem_new, OrderItem;

DROP TABLE IF EXISTS Customer_Temp;
DROP TABLE IF EXISTS LocationCity_Temp;
DROP TABLE IF EXISTS LocationCounty_Temp;
DROP TABLE IF EXISTS LocationRegion_Temp;
DROP TABLE IF EXISTS OrderGroup_Temp;
DROP TABLE IF EXISTS NewOrderItem_Temp;
DROP TABLE IF EXISTS ProductDetail_Temp;
DROP TABLE IF EXISTS ProductInfo_Temp;
DROP TABLE IF EXISTS ProductGroup_Temp;

COMMIT TRANSACTION DropOldTables
GO