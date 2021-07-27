USE RVPark

--Stored Procedures (5 needed)
-- SP #1
GO
CREATE PROC sp_cancel_reservation
@reservationID int,
@refund money OUTPUT
AS
BEGIN
	-- Calculate reservation fees
	SET @refund = (SELECT amountPaid FROM Payment p JOIN Reservation r ON p.reservationID = r.reservationID WHERE p.reservationID = @reservationID)
	DECLARE @startDate date
	SET @startDate = (SELECT resStartDate FROM Reservation r WHERE reservationID = @reservationID)
	SELECT @refund = CASE
						WHEN DATEDIFF(DAY, @startDate, GETDATE()) > 7 THEN (@refund - 5.00)
						WHEN (DATEDIFF(DAY, @startDate, GETDATE())>= 3) AND (DATEDIFF(DAY, @startDate, GETDATE()) <= 6) THEN (@refund - 10.00)
						WHEN (DATEDIFF(DAY, @startDate, GETDATE()) >= 1) AND (DATEDIFF(DAY, @startDate, GETDATE()) <= 2) THEN (@refund - 20)
						WHEN EXISTS (SELECT * FROM Reservation r
										JOIN Lot l ON r.lotID = l.lotID
										JOIN LotCategory lc ON l.categoryID = lc.categoryID
										JOIN RateCategory rc ON rc.rateID = lc.rateID
										JOIN Location loc ON loc.locID = rc.locID
										JOIN SpecialEvent se ON se.locID = loc.locID
										WHERE (r.resStartDate BETWEEN se.eventStartDate AND se.eventEndDate) 
										AND (r.resEndDate BETWEEN se.eventStartDate AND se.eventEndDate))
										THEN (@refund - 20)
						ELSE @refund
						END
	-- Remove reservation from reservation table
	DELETE FROM Reservation WHERE reservationID = @reservationID;
END
GO


GO--This Stored Procedure is used to update any fees
CREATE PROC sp_update_reservation_fee
@reservationID	int,
@fee			decimal(15,2)
AS
BEGIN
	UPDATE Payment
	SET amountPaid = @fee
	WHERE reservationID = @reservationID
END

--User Defined Functions (5 needed)
-- UDF #5
GO
CREATE FUNCTION fn_get_reservations (
@startDate date,
@endDate date
)
RETURNS TABLE
AS
RETURN
	SELECT * FROM Reservation r
		WHERE (r.resStartDate BETWEEN @startDate AND @endDate) AND (r.resEndDate BETWEEN @startDate AND @endDate)
GO



GO--This function returns the active campsites during a given timeframe. 
CREATE FUNCTION fn_active_campsite (
@beginDate	date,
@endDate	date)
RETURNS TABLE
AS
RETURN
	SELECT firstName, lastName, vehicleType, lotName
	FROM Reservation AS r
		INNER JOIN Resident AS res ON r.primaryResidentID = res.residentID
		INNER JOIN Lot AS l ON r.lotID = l.lotID
		WHERE r.resStartDate BETWEEN @beginDate AND @endDate AND r.resEndDate BETWEEN @beginDate AND @endDate


--Triggers (5 needed)
GO--On an update or insert, this will check for any reservation conflicts
CREATE TRIGGER Tr_check_reservation ON Reservation
AFTER INSERT, UPDATE AS
BEGIN
	IF EXISTS ( SELECT *
				FROM inserted i
				LEFT JOIN Reservation r ON i.primaryResidentID = r.primaryResidentID)
		BEGIN
			RAISERROR ('This reservation slot is already assigned', 16, 1)
			ROLLBACK
		END
	END

-- TR #3
GO
CREATE TRIGGER tr_reservation_limit ON Reservation
AFTER INSERT, UPDATE AS
BEGIN
	-- If reservation is bewteen October 15th and April 15th, then limit reservations to 15 days, otherwise don't.
	IF EXISTS (SELECT * FROM inserted i WHERE
										((MONTH(i.resStartDate) BETWEEN 11 AND 12) 
										OR (MONTH(i.resStartDate) BETWEEN 1 AND 3) -- dates between november and march, no specific dates 
										OR (MONTH(i.resStartDate) = 10 AND DAY(i.resStartDate) >= 15) 
										OR (MONTH(i.resStartDate) = 4 AND DAY(i.resStartDate) <= 15)) 
										AND ((MONTH(i.resEndDate) BETWEEN 11 AND 12) 
										OR (MONTH(i.resEndDate) BETWEEN 1 AND 3) -- dates between november and march, no specific dates 
										OR (MONTH(i.resEndDate) = 10 AND DAY(i.resEndDate) >= 15) 
										OR (MONTH(i.resEndDate) = 4 AND DAY(i.resEndDate) <= 15)
										))
		BEGIN
			RAISERROR ('Reservation limited to 15 days beteen Oct 15th and April 15th', 16, 1)
			ROLLBACK
		END
END


--Non-Clustered Indexes (2 needed)
GO--This index will be used to count the number of reservation a give day has.
CREATE NONCLUSTERED INDEX ix_reservation_dates
	ON Reservation (resStartDate)
GO
CREATE NONCLUSTERED INDEX ix_resident_affiliation
	ON Resident (DODaffID)
GO
--Cursor (1 needed)
