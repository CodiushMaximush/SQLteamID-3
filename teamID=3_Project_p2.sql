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

--ADD SAMPLE DATA BELOW
GO