USE [AssignmentPart1]
GO

/****** Object:  StoredProcedure [dbo].[prCreateOrderItem]    Script Date: 12/14/2019 5:37:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[prCreateOrderItem]
(@ON varchar(255), @OIN varchar(50), @PGroup varchar(255), @PCode varchar(50), @VCode varchar(50), @Quantity INT, @UPrice money)

AS BEGIN
SET NOCOUNT ON;

BEGIN TRANSACTION CreateOrderItem

BEGIN TRY

IF (EXISTS(SELECT VariantCode, ProductCode, Price FROM ProductDetail WHERE VariantCode = @VCode AND ProductCode = @PCode AND Price = @UPrice))
INSERT INTO OrderItem
SELECT @OIN, @ON, @PGroup, @VCode, @Quantity, @Quantity * @UPrice

UPDATE OrderGroup
SET TotalLineItems = (SELECT sum(Quantity) FROM OrderItem WHERE OrderNumber = @ON GROUP BY OrderNumber), 
SavedTotal = (SELECT sum(LineItemTotal) FROM OrderItem WHERE OrderNumber = @ON GROUP BY OrderNumber)
WHERE OrderNumber = @ON;

IF (NOT EXISTS(SELECT VariantCode, ProductCode, Price FROM ProductDetail WHERE VariantCode = @VCode AND ProductCode = @PCode AND Price = @UPrice))
THROW 50001, 'This Product does not exist. (The Combination of VariantCode, ProductCode and Price is not known to the database)', 1

COMMIT TRANSACTION CreateOrderItem
END TRY

BEGIN CATCH
ROLLBACK TRANSACTION CreateOrderItem
IF ERROR_MESSAGE() LIKE '%PRIMARY KEY%'
PRINT N'This OrderItemNumber already exists.'
IF ERROR_MESSAGE() LIKE '%FOREIGN KEY%'
PRINT N'This ProductGroup, VariantCode combination does not exist.'
IF ERROR_MESSAGE() LIKE '%CHECK%' AND ERROR_MESSAGE() LIKE '%PKSchemaItem%'
PRINT N'This is not a valid OrderItemNumber'
ELSE
PRINT ERROR_MESSAGE()
END CATCH;


END
GO




