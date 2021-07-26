USE RVPark

--Stored Procedures (5 needed)
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




--Non-Clustered Indexes (2 needed)
GO--This index will be used to count the number of reservation a give day has.
CREATE NONCLUSTERED INDEX ix_reservation_dates
	ON Reservation (resStartDate)
GO

--Cursor (1 needed)

