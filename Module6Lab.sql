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