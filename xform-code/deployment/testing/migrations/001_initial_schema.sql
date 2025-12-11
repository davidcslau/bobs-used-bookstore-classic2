-- =============================================
-- Bob's Used Bookstore - PostgreSQL Schema
-- Initial Database Schema for .NET 8.0 Application
-- =============================================

-- Create database (run as superuser if needed)
-- CREATE DATABASE bookstore;
-- \c bookstore;

-- =============================================
-- Reference Data Table
-- =============================================
CREATE TABLE IF NOT EXISTS "ReferenceData" (
    "Id" SERIAL PRIMARY KEY,
    "Type" VARCHAR(50) NOT NULL,
    "Value" VARCHAR(100) NOT NULL,
    "Active" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS "IX_ReferenceData_Type" ON "ReferenceData" ("Type");
CREATE INDEX IF NOT EXISTS "IX_ReferenceData_Active" ON "ReferenceData" ("Active");

-- =============================================
-- Customer Table
-- =============================================
CREATE TABLE IF NOT EXISTS "Customer" (
    "Id" SERIAL PRIMARY KEY,
    "Sub" VARCHAR(450) NOT NULL,
    "FirstName" VARCHAR(100) NOT NULL,
    "LastName" VARCHAR(100) NOT NULL,
    "EmailAddress" VARCHAR(255) NOT NULL,
    "PhoneNumber" VARCHAR(20) NULL,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_Customer_Sub" ON "Customer" ("Sub");
CREATE INDEX IF NOT EXISTS "IX_Customer_EmailAddress" ON "Customer" ("EmailAddress");

-- =============================================
-- Address Table
-- =============================================
CREATE TABLE IF NOT EXISTS "Address" (
    "Id" SERIAL PRIMARY KEY,
    "CustomerId" INTEGER NOT NULL,
    "AddressLine1" VARCHAR(255) NOT NULL,
    "AddressLine2" VARCHAR(255) NULL,
    "City" VARCHAR(100) NOT NULL,
    "State" VARCHAR(2) NOT NULL,
    "PostalCode" VARCHAR(10) NOT NULL,
    "Country" VARCHAR(50) NOT NULL DEFAULT 'USA',
    "IsDefault" BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "FK_Address_Customer" FOREIGN KEY ("CustomerId") 
        REFERENCES "Customer" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_Address_CustomerId" ON "Address" ("CustomerId");

-- =============================================
-- Book Table
-- =============================================
CREATE TABLE IF NOT EXISTS "Book" (
    "Id" SERIAL PRIMARY KEY,
    "Title" VARCHAR(255) NOT NULL,
    "Author" VARCHAR(255) NOT NULL,
    "ISBN" VARCHAR(20) NULL,
    "PublisherId" INTEGER NOT NULL,
    "BookTypeId" INTEGER NOT NULL,
    "GenreId" INTEGER NOT NULL,
    "ConditionId" INTEGER NOT NULL,
    "Price" DECIMAL(18,2) NOT NULL,
    "QuantityOnHand" INTEGER NOT NULL DEFAULT 0,
    "Description" TEXT NULL,
    "PublicationDate" DATE NULL,
    "CoverImageUrl" VARCHAR(500) NULL,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "FK_Book_Publisher" FOREIGN KEY ("PublisherId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Book_BookType" FOREIGN KEY ("BookTypeId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Book_Genre" FOREIGN KEY ("GenreId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Book_Condition" FOREIGN KEY ("ConditionId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_Book_Title" ON "Book" ("Title");
CREATE INDEX IF NOT EXISTS "IX_Book_Author" ON "Book" ("Author");
CREATE INDEX IF NOT EXISTS "IX_Book_ISBN" ON "Book" ("ISBN");
CREATE INDEX IF NOT EXISTS "IX_Book_PublisherId" ON "Book" ("PublisherId");
CREATE INDEX IF NOT EXISTS "IX_Book_GenreId" ON "Book" ("GenreId");
CREATE INDEX IF NOT EXISTS "IX_Book_ConditionId" ON "Book" ("ConditionId");

-- =============================================
-- Order Table
-- =============================================
CREATE TABLE IF NOT EXISTS "Order" (
    "Id" SERIAL PRIMARY KEY,
    "CustomerId" INTEGER NOT NULL,
    "OrderDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "TotalAmount" DECIMAL(18,2) NOT NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Pending',
    "ShippingAddressLine1" VARCHAR(255) NOT NULL,
    "ShippingAddressLine2" VARCHAR(255) NULL,
    "ShippingCity" VARCHAR(100) NOT NULL,
    "ShippingState" VARCHAR(2) NOT NULL,
    "ShippingPostalCode" VARCHAR(10) NOT NULL,
    "ShippingCountry" VARCHAR(50) NOT NULL DEFAULT 'USA',
    "BillingAddressLine1" VARCHAR(255) NOT NULL,
    "BillingAddressLine2" VARCHAR(255) NULL,
    "BillingCity" VARCHAR(100) NOT NULL,
    "BillingState" VARCHAR(2) NOT NULL,
    "BillingPostalCode" VARCHAR(10) NOT NULL,
    "BillingCountry" VARCHAR(50) NOT NULL DEFAULT 'USA',
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "FK_Order_Customer" FOREIGN KEY ("CustomerId") 
        REFERENCES "Customer" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_Order_CustomerId" ON "Order" ("CustomerId");
CREATE INDEX IF NOT EXISTS "IX_Order_OrderDate" ON "Order" ("OrderDate");
CREATE INDEX IF NOT EXISTS "IX_Order_Status" ON "Order" ("Status");

-- =============================================
-- OrderItem Table
-- =============================================
CREATE TABLE IF NOT EXISTS "OrderItem" (
    "Id" SERIAL PRIMARY KEY,
    "OrderId" INTEGER NOT NULL,
    "BookId" INTEGER NOT NULL,
    "Quantity" INTEGER NOT NULL,
    "UnitPrice" DECIMAL(18,2) NOT NULL,
    "TotalPrice" DECIMAL(18,2) NOT NULL,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "FK_OrderItem_Order" FOREIGN KEY ("OrderId") 
        REFERENCES "Order" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_OrderItem_Book" FOREIGN KEY ("BookId") 
        REFERENCES "Book" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_OrderItem_OrderId" ON "OrderItem" ("OrderId");
CREATE INDEX IF NOT EXISTS "IX_OrderItem_BookId" ON "OrderItem" ("BookId");

-- =============================================
-- ShoppingCart Table
-- =============================================
CREATE TABLE IF NOT EXISTS "ShoppingCart" (
    "Id" SERIAL PRIMARY KEY,
    "CustomerId" INTEGER NOT NULL,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "FK_ShoppingCart_Customer" FOREIGN KEY ("CustomerId") 
        REFERENCES "Customer" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_ShoppingCart_CustomerId" ON "ShoppingCart" ("CustomerId");

-- =============================================
-- ShoppingCartItem Table
-- =============================================
CREATE TABLE IF NOT EXISTS "ShoppingCartItem" (
    "Id" INTEGER NOT NULL,
    "ShoppingCartId" INTEGER NOT NULL,
    "BookId" INTEGER NOT NULL,
    "Quantity" INTEGER NOT NULL,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "PK_ShoppingCartItem" PRIMARY KEY ("Id", "ShoppingCartId"),
    CONSTRAINT "FK_ShoppingCartItem_ShoppingCart" FOREIGN KEY ("ShoppingCartId") 
        REFERENCES "ShoppingCart" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_ShoppingCartItem_Book" FOREIGN KEY ("BookId") 
        REFERENCES "Book" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_ShoppingCartItem_BookId" ON "ShoppingCartItem" ("BookId");

-- =============================================
-- Offer Table (Resale offers from customers)
-- =============================================
CREATE TABLE IF NOT EXISTS "Offer" (
    "Id" SERIAL PRIMARY KEY,
    "CustomerId" INTEGER NOT NULL,
    "Title" VARCHAR(255) NOT NULL,
    "Author" VARCHAR(255) NOT NULL,
    "ISBN" VARCHAR(20) NULL,
    "PublisherId" INTEGER NOT NULL,
    "BookTypeId" INTEGER NOT NULL,
    "GenreId" INTEGER NOT NULL,
    "ConditionId" INTEGER NOT NULL,
    "RequestedPrice" DECIMAL(18,2) NOT NULL,
    "Description" TEXT NULL,
    "ImageUrl" VARCHAR(500) NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Pending',
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP NULL,
    CONSTRAINT "FK_Offer_Customer" FOREIGN KEY ("CustomerId") 
        REFERENCES "Customer" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Offer_Publisher" FOREIGN KEY ("PublisherId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Offer_BookType" FOREIGN KEY ("BookTypeId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Offer_Genre" FOREIGN KEY ("GenreId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Offer_Condition" FOREIGN KEY ("ConditionId") 
        REFERENCES "ReferenceData" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_Offer_CustomerId" ON "Offer" ("CustomerId");
CREATE INDEX IF NOT EXISTS "IX_Offer_Status" ON "Offer" ("Status");

-- =============================================
-- Wishlist Table (Many-to-Many between Customer and Book)
-- =============================================
CREATE TABLE IF NOT EXISTS "Wishlist" (
    "CustomerId" INTEGER NOT NULL,
    "BookId" INTEGER NOT NULL,
    "CreatedDate" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_Wishlist" PRIMARY KEY ("CustomerId", "BookId"),
    CONSTRAINT "FK_Wishlist_Customer" FOREIGN KEY ("CustomerId") 
        REFERENCES "Customer" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Wishlist_Book" FOREIGN KEY ("BookId") 
        REFERENCES "Book" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_Wishlist_BookId" ON "Wishlist" ("BookId");

-- =============================================
-- Grant permissions (adjust user as needed)
-- =============================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bookstore_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO bookstore_user;
