USE RVPark

--Stored Procedures (5 needed)
-- SP #1 (Austin Wagstaff)
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
/*(Cody)Sp_reset_security_answers: Accepts a resident id and clears their security answers from the
database so they can be reinserted*/
IF OBJECT_ID('sp_reset_security_answers', 'P') IS NOT NULL
DROP PROC sp_reset_security_answers
GO
CREATE PROC sp_reset_security_answers
@residentID int
AS
BEGIN
DELETE FROM SecurityAnswer WHERE SecurityAnswer.residentID = @residentID
END

--This Stored Procedure is used to update any fees
GO
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



GO
-- UDF #5 (Austin Wagstaff)
GO
IF object_id(N'fn_get_reservations', N'FN') IS NOT NULL
    DROP FUNCTION fn_get_reservations
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


/*fn_get_empty_lots. A function that takes a date range and returns lots that are empty in that
date range. Could be nested within the new reservation function.*/
GO
IF object_id(N'fn_get_empty_lots', N'FN') IS NOT NULL
    DROP FUNCTION fn_get_empty_lots
GO
CREATE FUNCTION fn_get_empty_lots(@startDate date, @endDate date)
RETURNS TABLE
AS
RETURN

SELECT Lot.lotName, Lot.lotLength,  LotCategory.catName 
FROM LOT 
	JOIN LotCategory 
		ON Lot.categoryID = LotCategory.categoryID		
WHERE NOT EXISTS ( SELECT * FROM fn_get_reservations(@startDate, @endDate) as reservations WHERE reservations.lotID = Lot.lotID )


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

-- TR #3 (Austin Wagstaff)
GO
CREATE TRIGGER tr_reservation_limit ON Reservation
AFTER INSERT, UPDATE AS
BEGIN
	-- If reservation is bewteen October 15th and April 15th, then limit reservations to 15 days, otherwise don't.
	IF EXISTS (SELECT * FROM inserted i WHERE
										((
											(MONTH(i.resStartDate) BETWEEN 11 AND 12) 
										OR  (MONTH(i.resStartDate) BETWEEN 1 AND 3) -- dates between november and march, no specific dates 
										OR  (MONTH(i.resStartDate) = 10 AND DAY(i.resStartDate) >= 15) 
										OR  (MONTH(i.resStartDate) = 4  AND DAY(i.resStartDate) <= 15)
										) 
										AND (
										   (MONTH(i.resEndDate) BETWEEN 11 AND 12) 
										OR (MONTH(i.resEndDate) BETWEEN 1 AND 3) -- dates between november and march, no specific dates 
										OR (MONTH(i.resEndDate) = 10 AND DAY(i.resEndDate) >= 15) 
										OR (MONTH(i.resEndDate) = 4 AND DAY(i.resEndDate) <= 15)
										    ) AND DATEDIFF(DAY,i.resStartDate, i.resEndDate) > 15)
										)
		BEGIN
			SELECT * FROM inserted i
			RAISERROR ('Reservation limited to 15 days beteen Oct 15th and April 15th', 16, 1)
			ROLLBACK
		END
END

/*After Insert on special events calls a stored procedure that uses a
cursor to crawl through reservations that fall within the date range of a newly added event and
adds a processing fee to the reservation.*/
GO
IF (OBJECT_ID(N'tr_add_special_event') IS NOT NULL)
BEGIN
      DROP TRIGGER tr_add_special_event;
END
GO
CREATE TRIGGER tr_add_special_event ON SpecialEvent
AFTER INSERT AS
BEGIN
/*Cursor_add_special_event: used by a trigger to crawl through new events row by row to
update fees.*/


DECLARE @startDate date
DECLARE @endDate date

DECLARE cursor_add_special_event CURSOR
FOR SELECT eventStartDate, eventEndDate FROM INSERTED
OPEN cursor_add_special_event

FETCH NEXT FROM cursor_add_special_event INTO @startDate, @endDate
WHILE @@FETCH_STATUS = 0
BEGIN

	DECLARE cursor_affected_reservations CURSOR
	FOR SELECT reservationID FROM Reservation WHERE reservationDate BETWEEN @startDate AND @endDate
	OPEN cursor_affected_reservations

	DECLARE @resID int
	FETCH NEXT FROM cursor_affected_reservations INTO  @resID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Payment (amountPaid, datePaid, paymentReason, paymentTypeID, reservationID) 
		VALUES (20.00, GETDATE(), 'Special Event Fee', 1, @resID)
		FETCH NEXT FROM cursor_affected_reservations INTO @resID
	END

FETCH NEXT FROM cursor_add_special_event INTO @startDate, @endDate
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



-- TEST CASES
-- Austin Wagstaff
-- tr_reservation_limit
INSERT INTO Reservation VALUES ('12-05-2021', '12-25-2021', '05-14-2021', 2, 3, '653 A4C', 0, 23, 0, 0, 1, 1, 1, 1)
SELECT DATEDIFF(DAY, '11-05-2021', '11-10-2021')

-- fn_get_reservations
SELECT * FROM dbo.fn_get_reservations('07-05-2021', '09-24-2021')
-- sp_cancel_reservation
DECLARE @refundAmount money -- declare variable to store output
EXEC sp_cancel_reservation
	@reservationID = 2,
	@refund = @refundAmount OUTPUT
PRINT 'Refund  ' + CAST(@refundAmount as varchar(10)) -- printing empcount