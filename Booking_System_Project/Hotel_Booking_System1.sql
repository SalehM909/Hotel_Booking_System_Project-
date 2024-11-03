create database Hotel_Booking_System1

use Hotel_Booking_System1


Create Table Hotels (
   Hotel_ID int identity primary key,
   H_Name Varchar(30)  Unique,
   Location Varchar(255) ,
   Contact_Number Varchar(15) ,
   Rating decimal (2, 1) Check (Rating between 1 and 5)
);
Create Table Rooms (
   Room_ID int identity primary key,
   Room_Number Varchar(10)  Unique,
   Room_Type Varchar(20)  Check (Room_Type in ('Single', 'Double' , 'Suite')),
   Price_Per_Night decimal(10, 2)  Check (Price_Per_Night > 0),
   Availability_Status bit not null default 1,
   Hotel_ID int,
   Foreign key (Hotel_ID) References Hotels (Hotel_ID) 
);
Create Table Guests (
   Guest_ID int identity primary key,
   G_Name Varchar(30),
   Contact_Number Varchar(50),
   ID_Proof_Tyep Varchar (50) ,
   ID_Proof_Number Varchar(50) 
);
Create Table Bookings (
   Booking_ID int identity primary key,
   Booking_Date Date,
   Check_In_Date Date,
   Check_Out_Date Date,
   Status Varchar(20) Check (Status in ('Pending' , 'Confirmed' , 'Canceled'  , 'Check-in' , 'Check-out')),
   Total_Cost decimal (10, 2) ,
   Room_ID int,
   Guest_ID int,
   Foreign key (Room_ID) References Rooms (Room_ID) ,
   Foreign key (Guest_ID) References Guests (Guest_ID) 
);
Create Table Payments (

   Payment_ID int identity Primary key,
   Payment_Date Date ,
   Amount decimal (10 ,2)  Check (Amount > 0),
   Payment_Method Varchar(50) ,
   Booking_ID int,
   Foreign key (Booking_ID) References Bookings (Booking_ID) 
);
Create Table Staff (
   Staff_ID int identity primary key,
   S_Name Varchar(30) ,
   Position Varchar(100) ,
   Contact_Number Varchar(15),
   Hotel_ID int,
   Foreign key (Hotel_ID) References Hotels (Hotel_ID) 
);
Create Table Reviews (
   Review_ID int identity primary key,
   R_Rating int not null Check (R_Rating Between 1 and 5),
   Comments Varchar(1000),
   Review_Date Date,
   Hotel_ID int,
   Guest_ID int,
   Foreign key (Hotel_ID) References Hotels (Hotel_ID) ,
   Foreign key (Guest_ID) References Guests (Guest_ID) 
);
