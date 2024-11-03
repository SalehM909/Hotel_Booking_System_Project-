use Hotel_Booking_System1

-- Indexes:


-- For hotels Table
Create nonclustered index IND_Hotel_Name on Hotels(H_Name);

Create nonclustered index IND_Hotels_Rating on Hotels(Rating);


-- For Rooms Table

Create nonclustered index IND_Room_HotelID_RoomNumber on Rooms(Hotel_ID, Room_Number);

Create nonclustered index IND_Room_RoomType on Rooms (Room_Type);


-- For Bookings Table

Create nonclustered index IND_Booking_GuestID on Bookings (Guest_ID);

Create nonclustered index IND_Booking_Status on Bookings (Status);

Create nonclustered index IND_Bookings_Room_CheckIn_CheckOut on Bookings (Room_ID, Check_In_Date, Check_Out_Date);


--- Views ---



-- View for top-rated Hotels


Create view ViewTopRatedHotels as
   Select H.Hotel_ID, H.H_Name,
   Count(R.Room_ID) as TotalRooms,
   AVG(R.Price_Per_Night) as AvarageRoomPrice
   From Hotels H
   Join Rooms R on H.Hotel_ID = R.Hotel_ID
   WHere H.Rating > 4.5
   Group by H.Hotel_ID, H.H_Name;


-- View for Guests Bookings

Create View ViewGuestsBookings as
  Select G.Guest_ID, G.G_Name,
  Count (B.Booking_ID) as TotalBookings,
  Sum (B.Total_Cost) as TotalSpent
  From Guests G
  Left Join Bookings B on G.Guest_ID = B.Guest_ID
  Group by G.Guest_ID, G.G_Name;



-- View for Available Rooms
Create View ViewAvailableRooms as
  Select
     H.Hotel_ID,
	 H.H_Name as HotelName,
	 R.Room_Type,
	 R.Room_Number,
	 R.Price_Per_Night
  From Rooms R
  Join Hotels H on R.Hotel_ID = H.Hotel_ID
  Where R. Availability_Status = 1
  
-- View for Bookings Summery


Create View ViewBookingSummery as
  Select
    H.Hotel_ID,
	H.H_Name as HotelName,
  Count (B.Booking_ID) as TotalBookings,
  Sum (Case when B.Status = 'Confirmed' then 1 else 0 end) as ConfirmedBookings,
  Sum (Case when B.Status = 'Pending' then 1 else 0 end) as PendingBookings,
  Sum (Case when B.Status = 'Canceled' then 1 else 0 end) as CanceledBookings
  From Hotels H
  Left Join Bookings B on H.Hotel_ID = B.Room_ID
  Group by H.Hotel_ID, H.H_Name;


-- View for Payment History

Create View ViewPaymentHistory as
  Select
    P.Payment_ID,
	G.G_Name as GuestName,
	H.H_Name as HotelName,
	B.Status as BookingStatus,
	P.Amount as totalPayment
  From Payments P
  Join Bookings B on P.Booking_ID = B.Booking_ID
  Join Guests G on B.Guest_ID = G.Guest_ID
  Join Hotels H on B.Room_ID = H.Hotel_ID;

   --- Functions ---
-- Function for average rating for hotels
Create Function GetHotelAverageRating (@HotelID int)
  Returns decimal (3, 2) as
  Begin
    Declare @AvgRating decimal (3, 2);
	Select @AvgRating = AVG(R_Rating)
	From Reviews
	Where Hotel_ID = @HotelID;
	Return @AvgRating;
End;
-- Function to get the next available room of a specific type within a hotel
Create Function GetNextAvailableRoom (@Hotel_ID int, @Room_Type Varchar(50))
   Returns int as
 Begin
   Declare @Room_ID int;
   Select top 1 @Room_ID = @Room_ID
   From Rooms
   Where Hotel_ID = @Hotel_ID and Room_Type = @Room_Type and  Availability_Status = 1;
   Return @Room_ID;
End;
-- Function to calculate occupancy rate for a hotel
Create Function CalculateOccupancyRate (@Hotel_ID int)
   Returns decimal (5, 2) as
   Begin
      Declare @OccupancyRate decimal (5, 2);
	  Declare @TotalRooms int;
	  Declare @OccupiedRooms int;
	 
	  Select @TotalRooms = Count(*) from Rooms
	  Where Hotel_ID = @Hotel_ID;
	  Select @OccupiedRooms = Count(*) from Bookings B
	  Where B.Room_ID in (Select Room_ID from Rooms Where Hotel_ID = @Hotel_ID)
	  And b.Check_In_Date <= GetDate() and B.Check_Out_Date <= GetDate();
	  If @TotalRooms = 0
	    Set @OccupancyRate = 0;
	  Else
	    Set @OccupancyRate = (@OccupiedRooms * 100.0 / @TotalRooms);
		Return @OccupancyRate;
End;

--- Stored Procedures ---
-- Stored Procedure to mark room as unavailable
Create Proc sp_MarkRoomUnavailable @RoomID int as
Begin
  Update Rooms
  Set  Availability_Status = 0
  Where Room_ID = @RoomID;
End;
-- Stored Procedure to update booking status
Create Proc sp_UpdateBookingStatus @BookingID int, @NewStatus Varchar(50) as
  Begin
    Update Bookings
	Set Status = @NewStatus
	Where Booking_ID = @BookingID
End;
-- Stored Procedure to rank guests by total spending
Create Proc sp_RankGuestsBySpending as
  Begin
  Select G.Guest_ID, G.G_Name,
  Sum(B.Total_Cost) as TotalSpent,
  Rank() Over (Order by Sum(B.Total_Cost) Desc) as Rank
  From Guests G
  Left Join Bookings B on G.Guest_ID = B.Guest_ID
  Group by G.Guest_ID, G.G_Name;
End;




--- Triggers ---



-- Trigger to update room availability


Create Trigger UpdateRoomAvailability
   On Bookings
   After insert
   as
   Begin
     Update Rooms
	 Set  Availability_Status = 0
	 Where Room_ID in (Select Room_ID from inserted);
End;
-- Trigger to calculate total revenue for a hotel
Create Trigger CalculateTotalRevenue
  On Payments
  After insert
  as
  Begin
    Declare @HotelID int;
	Declare @TotalRevenue decimal(10, 2);
	Select @HotelID = B.Booking_ID
	From Bookings B
	Join inserted I on B.Booking_ID = I.Booking_ID;
	Select @TotalRevenue = Sum(Amount)
	From Payments
	Where Booking_ID in (Select Booking_ID from Bookings where Booking_ID = @HotelID);
End;
-- Trigger to check booking date validation
Create Trigger CheckInDateValidation
  On Bookings
  Instead of insert
  as
  Begin
    If exists (Select 1 from inserted where Check_In_Date > Check_Out_Date)
	Begin
	  Raiserror ('Check-in date must be less than or equal to Check-out date.', 16, 1);
	  Rollback transaction;
	End;
	Else
	Begin
	  Insert into Bookings (Booking_Date, Check_In_Date, Booking_Date, Status, Total_Cost, Room_ID, Guest_ID)
	  Select
	    Booking_Date,
		Check_In_Date,
		Check_Out_Date,
		Status,
		Total_Cost,
		Room_ID,
		Guest_ID
	  From inserted;
	  End
End;


