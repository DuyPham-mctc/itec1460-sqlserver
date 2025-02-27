-- Create an authors table
CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Birthday DATE
);

-- Create a books table
 CREATE TABLE Books(
    BookID INT PRIMARY KEY,
    Title VARCHAR(100),
    AuthorID INT,
    PublicationYear INT,
    Price DECIMAL(10,2),
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
 );

 -- Insert data into Authors table
 INSERT INTO Authors (AuthorID, FirstName, LastName, Birthday) 
VALUES 
(1, 'Jane', 'Austen', '1775-12-16'), 
(2, 'George', 'Orwell', '1903-06-25'), 
(3, 'J.K.', 'Rowling', '1965-07-31'), 
(4, 'Ernest', 'Hemingway', '1899-07-21'), 
(5, 'Virginia', 'Woolf', '1882-01-25')

INSERT INTO Books (BookID, Title, AuthorID, PublicationYear, Price) 
VALUES 
(1, 'Pride and Prejudice', 1, 1813, 12.99),
(2, '1984', 2, 1949, 10.99),
(3, 'Harry Potter and the Philosopher''s Stone', 3, 1997, 15.99),
(4, 'The Old Man and the Sea', 4, 1952, 11.99),
(5, 'To the Lighthouse', 5, 1927, 13.99)

-- Create a view that pulls data from the Authors and the Books tables
CREATE VIEW RecentBooks AS
SELECT 
    BookID,
    Title,
    PublicationYear,
    Price
FROM 
    Books
WHERE 
    PublicationYear > 1990;

--Create a view named BookDetails that combines information from both tables.
CREATE VIEW BookDetails AS
SELECT 
    b.BookID,
    b.Title,
    a.FirstName + ' ' + a.LastName AS AuthorName,
    b.PublicationYear,
    b.Price
FROM 
    Books b
JOIN 
    Authors a ON b.AuthorID = a.AuthorID;    

-- Create a view that shows the number of books and the average price of books
CREATE VIEW AuthorStats AS
SELECT a.AuthorID, a.FirstName + ' ' + a.LastName AS AuthorName,
COUNT(b.BookID) AS BookCount,
AVG(b.Price) AS AverageBookPrice
FROM Authors a LEFT JOIN Books b ON a.AuthorID = b.AuthorID
GROUP BY a.AuthorID, a.FirstName, a.LastName;

-- Retrieve all records from the BookDetails view
SELECT Title, Price FROM BookDetails;

-- List all books from the RecentBooks view
SELECT * FROM RecentBooks;

-- Show statistics for authors
SELECT * FROM AuthorStats;

-- Create an updateable view named AuthorContactInfo that allows updating the author's first name and last name.
CREATE VIEW AuthorContactInfo AS
SELECT 
    AuthorID,
    FirstName,
    LastName
FROM 
    Authors;

-- Try updating an author's name through this view:
UPDATE AuthorContactInfo
SET FirstName = 'Joanne'
WHERE AuthorID = 3;

-- Query the view:
SELECT * FROM AuthorContactInfo;

-- create the audit table:
CREATE TABLE BookPriceAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT,
    OldPrice DECIMAL(10,2),
    NewPrice DECIMAL(10,2),
    ChangeDate DATETIME DEFAULT GETDATE()
);

-- create the trigger:
CREATE TRIGGER trg_BookPriceChange
ON Books
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Price)
    BEGIN
        INSERT INTO BookPriceAudit (BookID, OldPrice, NewPrice)
        SELECT 
            i.BookID,
            d.Price,
            i.Price
        FROM inserted i
        JOIN deleted d ON i.BookID = d.BookID
    END
END;

-- Update a book's price
UPDATE Books
SET Price = 14.99
WHERE BookID = 1;

-- Check the audit table
SELECT * FROM BookPriceAudit;

-- create a BookReviews table
CREATE TABLE BookReviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    BookID INT,
    CustomerID NCHAR(5),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    ReviewText NVARCHAR(MAX),
    ReviewDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

--Create a view named vw_BookReviewStats
CREATE VIEW vw_BookReviewStats AS
SELECT 
    b.Title AS BookTitle,
    COUNT(br.ReviewID) AS TotalReviews,
    AVG(CAST(br.Rating AS DECIMAL(3,2))) AS AverageRating,
    MAX(br.ReviewDate) AS MostRecentReviewDate
FROM Books b LEFT JOIN BookReviews br ON b.BookID = br.BookID
GROUP BY b.Title;

--a) Create a trigger named tr_ValidateReviewDate
CREATE TRIGGER tr_ValidateReviewDate
ON BookReviews
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE ReviewDate > GETDATE())
    BEGIN
        RAISERROR ('Review date cannot be in the future.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

--b) Create a trigger named tr_UpdateBookRating

--add an AverageRating column (DECIMAL(3,2)) to the Books table
ALTER TABLE Books ADD AverageRating DECIMAL(3,2) NULL;

--Create a trigger named tr_UpdateBookRating
CREATE TRIGGER tr_UpdateBookRating
ON BookReviews
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE Books
    SET AverageRating = (
        SELECT AVG(CAST(Rating AS DECIMAL(3,2)))
        FROM BookReviews
        WHERE BookReviews.BookID = Books.BookID
    )
    WHERE EXISTS (SELECT 1 FROM BookReviews WHERE BookReviews.BookID = Books.BookID);
END;

--Test

--Insert at least 3 reviews for different books
INSERT INTO BookReviews (BookID, CustomerID, Rating, ReviewText, ReviewDate) 
VALUES 
(1, 'ALFKI', 5, 'Amazing book.', '2024-02-01'),
(2, 'BOLID', 3, 'Decent read.', '2024-02-15'),
(3, 'FISSA', 4, 'Very informative.', '2024-02-20');

--Try to insert a review with a future date (should fail)
INSERT INTO BookReviews (BookID, CustomerID, Rating, ReviewText, ReviewDate) 
VALUES (1, 'ALFKI', 4, 'Great book.', '2025-03-25');

--Checking the statistics view
SELECT * FROM vw_BookReviewStats;

--Update a review's rating 
UPDATE BookReviews
SET Rating = 2
WHERE ReviewID = 2;

--Verify the book's average rating updates automatically
SELECT BookID, AverageRating FROM Books;