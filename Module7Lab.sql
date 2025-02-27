--Create and Execute Stored Procedure that calculates the total amountfor an order
--Our stored procedure accepts two parameter as input
--Accepts the order ID and total amount, then return  the update total amount as output
CREATE OR ALTER PROCEDURE CalculateOrderTotal
    @OrderID INT,
    @TotalAmount MONEY OUTPUT
AS
BEGIN
SET NOCOUNT ON;

    -- Calculate the total amount for the given order
    SELECT @TotalAmount = SUM(UnitPrice * Quantity * (1 - Discount))
    FROM [Order Details]
    WHERE OrderID = @OrderID;

    -- Check if the order exists - handle the error condition
    -- If the order ID doesn't match any items in the Order Details table 
    IF @TotalAmount IS NULL
    BEGIN
        SET @TotalAmount = 0;
        PRINT 'Order ' + CAST(@OrderID AS NVARCHAR(10)) + ' not found.';
        --Exits the stored procedure
        RETURN;
    END

    --Output the total amount for the order
    PRINT 'The total amount for Order ' + CAST(@OrderID AS NVARCHAR(10)) + ' is $' + CAST(@TotalAmount AS NVARCHAR(20));
END
--Go causes stored procedure to run after it's altered or created
GO

-- Test the stored procedure with a valid order
-- First declare the variables 
DECLARE @OrderID INT = 10248;
DECLARE @TotalAmount MONEY;

-- Call the stored procedure
EXEC CalculateOrderTotal 
    @OrderID = @OrderID, 
    @TotalAmount = @TotalAmount OUTPUT;

--Print the results of the stored procedure(output the results)
PRINT 'Returned total amount: $' + CAST(@TotalAmount AS NVARCHAR(20));

-- Test with an invalid order
SET @OrderID = 99999;
SET @TotalAmount = NULL;

EXEC CalculateOrderTotal 
    @OrderID = @OrderID, 
    @TotalAmount = @TotalAmount OUTPUT;

PRINT 'Returned total amount: $' + CAST(ISNULL(@TotalAmount, 0) AS NVARCHAR(20));
GO