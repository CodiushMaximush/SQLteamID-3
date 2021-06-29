--hey look, an SQL assignment
USE Master
GO
IF EXISTS (SELECT * FROM sysdatabases WHERE name='RVPark')
	DROP DATABASE RVPark
--Ensure that the database does not exsist
GO

CREATE DATABASE RVPark

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

CREATE TABLE Residents
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
primaryResdientID	int			NOT NULL,
vehicleID			int			NOT NULL
)

--CONSTRAINTS BELOW HERE

GO
ALTER TABLE ServiceStatus
	ADD CONSTRAINT PK_statusID
	PRIMARY KEY (statusID)

ALTER TABLE SecurityQuestion
	ADD CONSTRAINT PK_questionID
	PRIMARY KEY	(questionID)

ALTER TABLE DODAffiliation
	ADD CONSTRAINT PK_DODaffID
	PRIMARY KEY (DODaffID)

ALTER TABLE Residents
	ADD CONSTRAINT PK_residentID
	PRIMARY KEY (residentID)

ALTER TABLE Residents
	ADD CONSTRAINT FK_serviceStatusID
	FOREIGN KEY (serviceStatusID) REFERENCES ServiceStatus (statusID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Residents
	ADD CONSTRAINT FK_DODaffID
	FOREIGN KEY (DODaffID) REFERENCES DODAffiliation (DODaffID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Answer
	ADD CONSTRAINT PK_questionID_residentID
	PRIMARY KEY (questionID, residentID)

ALTER TABLE Answer
	ADD CONSTRAINT FK_questionID
	FOREIGN KEY (questionID) REFERENCES SecurityQuestion (questionID)
	ON UPDATE CASCADE
	ON DELETE CASCADE

ALTER TABLE Answer
	ADD CONSTRAINT FK_residentID
	FOREIGN KEY (residentID) REFERENCES Residents (residentID)

ALTER TABLE PaymentType
	ADD CONSTRAINT PK_typeID
	PRIMARY KEY (typeID)

ALTER TABLE Payment
	ADD CONSTRAINT PK_paymentID
	PRIMARY KEY (paymentID)

ALTER TABLE Payment
	ADD CONSTRAINT FK_paymentTypeID
	FOREIGN KEY (paymentTypeID) REFERENCES PaymentType (typeID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION

ALTER TABLE Reservation
	ADD CONSTRAINT PK_reservationID
	PRIMARY KEY (reservationID)

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

ALTER TABLE Reservation
	ADD CONSTRAINT FK_vehicleID
	FOREIGN KEY (FK_vehicleID) REFERENCES VehicleType (vehicleID)
	ON UPDATE CASCADE
	ON DELETE NO ACTION

ALTER TABLE Reservation 
	ADD CONSTRAINT CK_vehicleLength
	CHECK (vehicleLength BETWEEN 0 AND 50)

ALTER TABLE Reservation 
	ADD CONSTRAINT CK_numPets
	CHECK (numPets BETWEEN 0 AND 2)

ALTER TABLE Reservation
	ADD CONSTRAINT DK_reservationDate
	DEFAULT GETDATE() FOR reservationDate

--ADD SAMPLE DATA BELOW
GO