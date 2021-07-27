USE RVPark
-------------------
--Stored Procedures
-------------------

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
-- SP #2
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

-- SP #3
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

-- SP #4
--(Austin West) Accepts a payment id then adds another payment with the same amount but negative and changing the comments to 'refund'
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'sp_refund_payment')
	DROP PROCEDURE sp_refund_payment;

GO
CREATE PROCEDURE sp_refund_payment
	@paymentid	int
AS 
BEGIN
	DECLARE @amountPaid money, @reservationID int, @paymentTypeID int
	SET @amountPaid = (SELECT amountPaid FROM Payment WHERE paymentID = @paymentid)
	SET @reservationID = (SELECT reservationID FROM Payment WHERE paymentID = @paymentid)
	SET @paymentTypeID = (SELECT paymentTypeID FROM Payment WHERE paymentID = @paymentid)

	INSERT INTO Payment VALUES ((@amountPaid * -1), GETDATE(), 'Refund Reservation', @paymentTypeID, @reservationID)
END
GO

-- SP #5 (still needed)



------------------------
--User Defined Functions
------------------------

GO
-- UDF #1
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

-- UDF #2
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


GO
-- UDF #3
--This function returns the active campsites during a given timeframe. 
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

-- UDF #4
-- (Austin West) Accepts an input of DODAffiliationID and returns a table containing residents with that affiliation
IF EXISTS (SELECT * FROM sys.objects WHERE 
object_id = OBJECT_ID('dbo.fn_affiliation_stats') 
AND type in (N'FN', N'IF',N'TF', N'FS', N'FT'))
DROP FUNCTION dbo.fn_affiliation_stats;
GO
CREATE FUNCTION dbo.fn_affiliation_stats
(
@affiliationID		int
) 
RETURNS TABLE
AS 
RETURN
	(SELECT affiliationDesc, firstname, lastname, ResidentID, phone, email, serviceStatusID FROM DODAffiliation d
	JOIN Resident r on d.DODaffID = r.DODaffID
	WHERE r.DODaffID = @affiliationID)
GO

-- UDF #5 (still needed)



----------
--Triggers
----------
GO
-- Trigger #1
--On an update or insert, this will check for any reservation conflicts
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

-- TR #2
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

-- Trigger #3
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

-- Trigger #4
-- (Austin West) Insert/Update trigger that listens for updates to Reservation and identifies when a reservation has been made during a special event period
GO
DROP TRIGGER IF EXISTS dbo.tr_check_specialevent
GO
CREATE TRIGGER tr_check_specialevent ON Reservation
AFTER INSERT, UPDATE
AS
DECLARE @reservationStartDate datetime, @reservationEndDate datetime
SET @reservationStartDate = (SELECT resStartDate FROM inserted)
SET @reservationEndDate = (SELECT resEndDate FROM inserted)
-- handle invalid reservation startDate
IF EXISTS (select 1 from SpecialEvent where @reservationStartDate between eventStartDate and eventEndDate)
BEGIN
	RAISERROR ('This date range falls into a special event date range. Special event rate may apply. Another procedure could be called here to handle this event.',10,1,999)
	ROLLBACK 
END
-- handle invalid reservation endDate
IF EXISTS (select 1 from SpecialEvent where @reservationEndDate between eventStartDate and eventEndDate)
BEGIN
	RAISERROR ('This date range falls into a special event date range. Special event rate may apply. Another procedure could be called here to handle this event.',10,1,999)
	ROLLBACK 
END


--Trigger #5 (still needed)


-----------------------
--Non-Clustered Indexes
-----------------------
GO
-- Index #1
--This index will be used to count the number of reservation a give day has.
CREATE NONCLUSTERED INDEX ix_reservation_dates
	ON Reservation (resStartDate)
GO
-- Index #2
CREATE NONCLUSTERED INDEX ix_resident_affiliation
	ON Resident (DODaffID)
GO

--------
--Cursor 
--------
--Defined above in Trigger #3