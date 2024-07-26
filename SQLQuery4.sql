CREATE DATABASE StationeryDB;
USE StationeryDB;

CREATE TABLE Categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    name VARCHAR(100),
    contact_info VARCHAR(255)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255),
    category_id INT,
    supplier_id INT,
    price DECIMAL(10, 2),
    stock INT,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    contact_info VARCHAR(255),
    join_date DATE
);

CREATE TABLE SalesRecords (
    sale_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    sale_date DATE,
    quantity INT,
    total_price DECIMAL(10, 2),
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);


-- Insert data into Categories
INSERT INTO Categories VALUES (1, 'Buku');
INSERT INTO Categories VALUES (2, 'AlatTulis');
INSERT INTO Categories VALUES (3, 'AlatGambar');
INSERT INTO Categories VALUES (4, 'Fotocopy');
INSERT INTO Categories VALUES (5, 'Kertas');

-- Insert data into Suppliers
INSERT INTO Suppliers VALUES (1, 'Mamat Supply', '089-456-7890');
INSERT INTO Suppliers VALUES (2, 'Agus Saputra', '087-654-3210');
INSERT INTO Suppliers VALUES (3, 'Bambang Putra', '088-555-5555');
INSERT INTO Suppliers VALUES (4, 'Putra Pradana', '087-652-1235');
INSERT INTO Suppliers VALUES (5, 'Agung Bagus', '088-553-9765');

-- Insert data into Products
INSERT INTO Products VALUES (1, 'Buku Tulis', 1, 1, 5000, 50);
INSERT INTO Products VALUES (2, 'Kuas', 3, 2, 7000, 30);
INSERT INTO Products VALUES (3, 'Pulpen', 2, 3, 2500, 200);
INSERT INTO Products VALUES (4, 'Kertas HVS', 5, 4, 250, 100);
INSERT INTO Products VALUES (5, 'Map', 4, 5, 3000, 300);

-- Insert data into Customers
INSERT INTO Customers VALUES (1, 'Putri Adelia', '087-111-1111', '2023-01-01');
INSERT INTO Customers VALUES (2, 'Anugrah Nur', '089-222-2222', '2023-02-15');
INSERT INTO Customers VALUES (3, 'Alif Satyo', '088-333-3333', '2023-03-10');
INSERT INTO Customers VALUES (4, 'Vina Hayati', '083-444-4444', '2023-04-20');
INSERT INTO Customers VALUES (5, 'Fadil Jaidi', '085-555-5555', '2023-05-05');

-- Insert data into SalesRecords
INSERT INTO SalesRecords VALUES (1, 1, 1, '2023-06-01', 2, 200);
INSERT INTO SalesRecords VALUES (2, 2, 2, '2023-06-05', 1, 150);
INSERT INTO SalesRecords VALUES (3, 3, 3, '2023-06-08', 10, 50);
INSERT INTO SalesRecords VALUES (4, 4, 4, '2023-06-10', 5, 100);
INSERT INTO SalesRecords VALUES (5, 5, 5, '2023-06-15', 20, 60);

SELECT * FROM Products;
SELECT * FROM Categories;
SELECT * FROM Suppliers;
SELECT * FROM Customers;
SELECT * FROM SalesRecords;


--A--
CREATE FUNCTION TotalProducts()
RETURNS INT
AS
BEGIN 
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM Products;
    RETURN @total;
END;

SELECT dbo.TotalProducts();


CREATE FUNCTION TotalSales(@customer INT, @product INT) 
RETURNS DECIMAL(10, 2)
AS
BEGIN 
    DECLARE @total DECIMAL(10, 2);
    SELECT @total = SUM(total_price) 
    FROM SalesRecords 
    WHERE customer_id = @customer AND product_id = @product;
    RETURN @total;
END;

SELECT dbo.TotalSales(1, 1);

SELECT name 
FROM sys.objects 
WHERE type = 'FN';


--B--
CREATE PROCEDURE GetTotalProducts
AS
BEGIN
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM Products;
    PRINT 'Total number of products: ' + CAST(@total AS VARCHAR(10));
END;

EXEC GetTotalProducts;

CREATE PROCEDURE GetTotalSales
    @customer INT,
    @product INT
AS
BEGIN
    DECLARE @total DECIMAL(10, 2);
    SELECT @total = SUM(total_price) 
    FROM SalesRecords 
    WHERE customer_id = @customer AND product_id = @product;

    IF @total IS NULL
    BEGIN
        PRINT 'No sales found for the given customer and product.';
    END
    ELSE
    BEGIN
        PRINT 'Total sales: ' + CAST(@total AS VARCHAR(20));
    END
END;

EXEC GetTotalSales @customer = 1, @product = 1;

SELECT name 
FROM sys.objects 
WHERE type = 'P';


--C--
CREATE TABLE ProductLog (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    log_action VARCHAR(50),
    product_id INT,
    old_name VARCHAR(255),
    new_name VARCHAR(255),
    old_price DECIMAL(10, 2),
    new_price DECIMAL(10, 2),
    log_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER BeforeInsertProduct
ON Products
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO ProductLog (log_action, product_id, new_name, new_price)
    SELECT 'BEFORE INSERT', i.product_id, i.name, i.price
    FROM inserted i;

    -- Continue with the insert
    INSERT INTO Products (name, category_id, supplier_id, price, stock)
    SELECT name, category_id, supplier_id, price, stock
    FROM inserted;
END;
CREATE TRIGGER BeforeUpdateProduct
ON Products
INSTEAD OF UPDATE
AS
BEGIN
    INSERT INTO ProductLog (log_action, product_id, old_name, new_name, old_price, new_price)
    SELECT 'BEFORE UPDATE', d.product_id, d.name, i.name, d.price, i.price
    FROM deleted d
    JOIN inserted i ON d.product_id = i.product_id;

    -- Continue with the update
    UPDATE Products
    SET name = i.name, category_id = i.category_id, supplier_id = i.supplier_id, price = i.price, stock = i.stock
    FROM inserted i
    WHERE Products.product_id = i.product_id;
END;
CREATE TRIGGER BeforeDeleteProduct
ON Products
INSTEAD OF DELETE
AS
BEGIN
    INSERT INTO ProductLog (log_action, product_id, old_name, old_price)
    SELECT 'BEFORE DELETE', d.product_id, d.name, d.price
    FROM deleted d;

    -- Continue with the delete
    DELETE FROM Products
    WHERE product_id IN (SELECT product_id FROM deleted);
END;
CREATE TRIGGER AfterInsertProduct
ON Products
AFTER INSERT
AS
BEGIN
    INSERT INTO ProductLog (log_action, product_id, new_name, new_price)
    SELECT 'AFTER INSERT', i.product_id, i.name, i.price
    FROM inserted i;
END;
CREATE TRIGGER AfterUpdateProduct
ON Products
AFTER UPDATE
AS
BEGIN
    INSERT INTO ProductLog (log_action, product_id, old_name, new_name, old_price, new_price)
    SELECT 'AFTER UPDATE', d.product_id, d.name, i.name, d.price, i.price
    FROM deleted d
    JOIN inserted i ON d.product_id = i.product_id;
END;
CREATE TRIGGER AfterDeleteProduct
ON Products
AFTER DELETE
AS
BEGIN
    INSERT INTO ProductLog (log_action, product_id, old_name, old_price)
    SELECT 'AFTER DELETE', d.product_id, d.name, d.price
    FROM deleted d;
END;

INSERT INTO Products (name, category_id, supplier_id, price, stock)
VALUES ('New Book', 1, 1, 100.00, 10);

 UPDATE Products
SET category_id = 3
WHERE product_id = 2;

DELETE FROM Products
WHERE product_id = 1;

SELECT name 
FROM sys.triggers;
