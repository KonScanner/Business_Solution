USE [AssignmentPart1]
GO

/****** Object:  StoredProcedure [dbo].[prCreateOrderGroup] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[prCreateOrderGroup](@ON varchar(255),@OCD datetime, @CCI varchar(255))
AS BEGIN SET NOCOUNT ON;

BEGIN TRANSACTION CreateOrderGroup;

BEGIN TRY
INSERT INTO OrderGroup
SELECT @ON, @OCD, 0, 'GBP', @CCI, 0, 0.0

COMMIT TRANSACTION CreateOrderGroup
END TRY

BEGIN CATCH
ROLLBACK TRANSACTION CreateOrderGroup
IF ERROR_MESSAGE() LIKE '%PRIMARY KEY%'
PRINT N'This OrderNumber already exists.'
IF ERROR_MESSAGE() LIKE '%FOREIGN KEY%'
PRINT N'This Customer does not exist.'
IF ERROR_MESSAGE() LIKE '%CHECK%' AND ERROR_MESSAGE() LIKE '%OrderNumber%'
PRINT N'This is not a valid OrderNumber'

ELSE
PRINT ERROR_MESSAGE()
END CATCH;

END

GO

