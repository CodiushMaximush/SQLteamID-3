--hey look, an SQL assignment
USE Master
GO
IF EXISTS (SELECT * FROM sysdatabases WHERE name='RVPark')
	DROP DATABASE RVPark
--Ensure that the database does not exsist
GO

CREATE DATABASE RVPark

--I'm pretty sure this part is optional and hard to maintain across multiple machines
/*
ON PRIMARY
(
	NAME = 'RVPark',
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\RVPark.mdf', --The path may need to be changed
	SIZE = 50MB,
	MAXSIZE = 500MB,
	FILEGROWTH = 10%
)

LOG ON 
(
	NAME = 'RVPark_Log',
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\RVPark.ldf', --The path may need to be changed
	SIZE = 5MB,
	MAXSIZE = 50MB,
	FILEGROWTH = 10% --smaller size assuming assignments are not constantly created and changed
)
*/
GO
USE RVPark

CREATE TABLE ServiceStatus
(
statusID		tinyint		NOT NULL	IDENTITY,
statusDesc		varchar(50)	NOT NULL
)

CREATE TABLE SecurityQuestion
(
questionID		tinyint		NOT NULL	IDENTITY,
question		varchar(50)	NOT NULL
)

CREATE TABLE DODAffiliation
(
DODaffID		tinyint		NOT NULL	IDENTITY,
affiliationDesc	varchar(50)	NOT NULL
)

CREATE TABLE Answer
(
questionID		tinyint		NOT NULL,
residentID		int			NOT NULL,
answer			varchar(20)	NOT NULL
)

CREATE TABLE Resident
(
residentID		int			NOT NULL	IDENTITY,
firstName		varchar(20)	NOT NULL,
lastName		varchar(20)	NOT NULL,
phone			varchar(15)	NOT NULL,
email			varchar(25)	NOT NULL,
login			varchar(25)	NOT NULL,
password		varchar(25)	NOT NULL,
serviceStatusID	tinyint		NOT NULL,
DODaffID		tinyint		NOT NULL
)

CREATE TABLE Payment
(
paymentID		int				NOT NULL	IDENTITY,
amountPaid		decimal(15,2)	NOT NULL,
datePaid		datetime		NOT NULL,
paymentReason	varchar(25)		NOT NULL,
paymentTypeID	tinyint			NOT NULL,
reservationID	int
)

CREATE TABLE PaymentType
(
typeID			tinyint		NOT NULL	IDENTITY,
typeName		varchar(15)	NOT NULL
)

CREATE TABLE Reservation
(
reservationID		int			NOT NULL	IDENTITY,
startDate			datetime	NOT NULL,
endDate				datetime	NOT NULL,
reservationDate		datetime	NOT NULL,
numAdults			tinyint		NOT NULL,
numChildren			tinyint		NOT NULL,
licensePlate		varchar(10)	NOT NULL,
vehicleType			varchar(20)	NOT NULL,
vehicleLength		tinyint		NOT NULL,
restrictedPets		bit			NOT NULL,
numPets				tinyint		NOT NULL,
reservationStatusID	tinyint		NOT NULL,
lotID				tinyint		NOT NULL,
primaryResidentID	int			NOT NULL,
vehicleID			int			NOT NULL
)

CREATE TABLE SpecialEvent
(
eventID			int				NOT NULL	IDENTITY,
eventName		varChar(20)		NOT NULL,
eventStartDate	dateTime		NOT NULL,
eventEndDate	dateTime		NOT NULL,
locID			tinyint			NOT NULL
)

CREATE TABLE Location
(
locID			tinyint			NOT NULL	IDENTITY,
locationName	varChar(15)		NOT NULL,
locationAddress	varChar(40)		NOT NULL,
locZIP			varChar(10)		NOT NULL,
locCity			varChar(30)		NOT NULL,
locState		varChar(15)		NOT NULL,
)

CREATE TABLE Lot
(
lotID		tinyint			NOT NULL	IDENTITY,
lotName		varChar(5)		NOT NULL,
lotLength	tinyint			NOT NULL,
categoryID	tinyint			NOT NULL,
locId		tinyint			NOT NULL,
)

CREATE TABLE LotCategory
(
categoryID	tinyint			NOT NULL	IDENTITY,
catName		varChar(15)		NOT NULL,
rateID		tinyint			NOT NULL,
)

CREATE TABLE RateCategory(
rateID			tinyInt			NOT NULL	IDENTITY,
rate			smallMoney		NOT NULL,
rateStartDate	dateTime		NOT NULL, 
rateEndDate		dateTime		NOT NULL
)

CREATE TABLE ReservationStatus(
reservationStatusID			tinyInt			NOT NULL	IDENTITY,
statusName			varChar(15)		NOT NULL,
statusDescription	varChar(max)	NOT NULL	
)

CREATE TABLE VehicleType(
vehicleID			int				NOT NULL	IDENTITY,
vehicleDescription  varChar(50)		NOT NULL
)

--CONSTRAINTS BELOW HERE

GO
-- Primary Key Constraints
ALTER TABLE SpecialEvent
	ADD CONSTRAINT PK_eventID
	PRIMARY KEY (eventID)

ALTER TABLE Location
	ADD CONSTRAINT PK_locID
	PRIMARY KEY (locID)

ALTER TABLE Lot
	ADD CONSTRAINT PK_lotID
	PRIMARY KEY (lotID)

ALTER TABLE LotCategory
	ADD CONSTRAINT PK_categoryID
	PRIMARY KEY (categoryID)

ALTER TABLE ServiceStatus
	ADD CONSTRAINT PK_statusID
	PRIMARY KEY (statusID)

ALTER TABLE SecurityQuestion
	ADD CONSTRAINT PK_questionID
	PRIMARY KEY	(questionID)

ALTER TABLE DODAffiliation
	ADD CONSTRAINT PK_DODaffID
	PRIMARY KEY (DODaffID)

ALTER TABLE Resident
	ADD CONSTRAINT PK_residentID
	PRIMARY KEY (residentID)

ALTER TABLE Answer
	ADD CONSTRAINT PK_answer
	PRIMARY KEY (questionID, residentID)

ALTER TABLE RateCategory
	ADD CONSTRAINT PK_rateCategory 
	PRIMARY KEY(rateID)

ALTER TABLE ReservationStatus
	ADD CONSTRAINT PK_reservationStatus 
	PRIMARY KEY(reservationStatusID)

ALTER TABLE PaymentType
	ADD CONSTRAINT PK_typeID
	PRIMARY KEY (typeID)

ALTER TABLE Payment
	ADD CONSTRAINT PK_paymentID
	PRIMARY KEY (paymentID)

ALTER TABLE Reservation
	ADD CONSTRAINT PK_reservationID
	PRIMARY KEY (reservationID)


--Add Foreign Key Constraints

ALTER TABLE Answer
	ADD CONSTRAINT FK_questionID
	FOREIGN KEY (questionID) REFERENCES SecurityQuestion (questionID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Answer
	ADD CONSTRAINT FK_residentID
	FOREIGN KEY (residentID) REFERENCES Resident (residentID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE SpecialEvent
	ADD CONSTRAINT FK_locID
	FOREIGN KEY (locID) REFERENCES Location (locID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE LotCategory
	ADD CONSTRAINT FK_rateID
	FOREIGN KEY (rateID) REFERENCES RateCategory (rateID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Lot
	ADD CONSTRAINT FK_categoryID
	FOREIGN KEY (categoryID) REFERENCES LotCategory (categoryID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Lot
	ADD CONSTRAINT FK_locID
	FOREIGN KEY (locID) REFERENCES Location (locID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Resident
	ADD CONSTRAINT FK_serviceStatusID
	FOREIGN KEY (serviceStatusID) REFERENCES ServiceStatus (statusID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Resident
	ADD CONSTRAINT FK_DODaffID
	FOREIGN KEY (DODaffID) REFERENCES DODAffiliation (DODaffID)
	ON UPDATE CASCADE
	ON DELETE CASCADE




ALTER TABLE Payment
	ADD CONSTRAINT FK_paymentTypeID
	FOREIGN KEY (paymentTypeID) REFERENCES PaymentType (typeID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION


ALTER TABLE Reservation
	ADD CONSTRAINT FK_reservationStatusID
	FOREIGN KEY (reservationStatusID) REFERENCES ReservationStatus (reservationStatusID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION

ALTER TABLE Reservation
	ADD CONSTRAINT FK_lotID
	FOREIGN KEY (lotID) REFERENCES Lot (lotID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION

ALTER TABLE Reservation
	ADD CONSTRAINT FK_primaryResidentID
	FOREIGN KEY (primaryResidentID) REFERENCES Resident (residentID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION

--TODO: This FK constraint is broken and I don't know why
/*
ALTER TABLE Reservation
	ADD CONSTRAINT FK_vehicleID
	FOREIGN KEY (vehicleID) REFERENCES VehicleType (vehicleID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION
*/


-- Add CK's
ALTER TABLE Reservation 
	ADD CONSTRAINT CK_vehicleLength
	CHECK (vehicleLength BETWEEN 0 AND 50)

ALTER TABLE Reservation 
	ADD CONSTRAINT CK_numPets
	CHECK (numPets BETWEEN 0 AND 2)

-- Add DK's



ALTER TABLE Reservation
	ADD CONSTRAINT DK_reservationDate
	DEFAULT GETDATE() FOR reservationDate



--ADD SAMPLE DATA BELOW
GO