# Database Schema Documentation - Bob's Used Bookstore Classic

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Database:** SQL Server  
**ORM:** Entity Framework 6.5.1

---

## Table of Contents
1. [Overview](#overview)
2. [Database Tables](#database-tables)
3. [Relationships](#relationships)
4. [Indexes](#indexes)
5. [Data Types](#data-types)
6. [Seed Data](#seed-data)

---

## Overview

The database schema is generated using Entity Framework Code-First approach. The schema supports an e-commerce platform for used books with features for inventory management, customer orders, shopping carts, and resale offers.

**Database Name:** BookStoreClassic

**Key Characteristics:**
- 9 main tables
- Foreign key relationships with no cascade delete on reference data
- Identity columns for primary keys
- Unique constraints on authentication identifiers
- Composite primary key for shopping cart items

---

## Database Tables

### 1. Book

Stores the book inventory available for purchase.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| Name | nvarchar(MAX) | No | Book title |
| Author | nvarchar(MAX) | No | Author name |
| Year | int | Yes | Publication year |
| ISBN | nvarchar(MAX) | Yes | ISBN number |
| PublisherId | int | No | FK to ReferenceData (Publisher) |
| BookTypeId | int | No | FK to ReferenceData (Hardcover/Paperback) |
| GenreId | int | No | FK to ReferenceData (Genre) |
| ConditionId | int | No | FK to ReferenceData (Condition) |
| CoverImageUrl | nvarchar(MAX) | Yes | URL to cover image |
| Summary | nvarchar(MAX) | Yes | Book description |
| Price | decimal(18,2) | No | Selling price |
| Quantity | int | No | Stock quantity |

**Foreign Keys:**
- PublisherId → ReferenceData(Id)
- BookTypeId → ReferenceData(Id)
- GenreId → ReferenceData(Id)
- ConditionId → ReferenceData(Id)

---

### 2. Customer

Stores registered customer information.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| Sub | nvarchar(450) | No | Authentication subject identifier (unique) |
| Username | nvarchar(MAX) | Yes | Username |
| FirstName | nvarchar(MAX) | Yes | First name |
| LastName | nvarchar(MAX) | Yes | Last name |
| Email | nvarchar(MAX) | Yes | Email address |
| DateOfBirth | datetime2 | Yes | Date of birth |
| Phone | nvarchar(MAX) | Yes | Phone number |

**Unique Constraints:**
- Sub (unique index)

**Notes:**
- Sub links customer to authentication provider (Cognito or local)
- Sub is used to find/create customer during login

---

### 3. Order

Stores customer orders.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| CustomerId | int | No | FK to Customer |
| AddressId | int | No | FK to Address (shipping) |
| DeliveryDate | datetime2 | No | Expected delivery date |
| OrderStatus | int | No | Order status (enum) |

**Foreign Keys:**
- CustomerId → Customer(Id)
- AddressId → Address(Id)

**Computed Values (in application):**
- SubTotal = Sum(OrderItems.Book.Price)
- Tax = SubTotal * 0.1
- Total = SubTotal + Tax

---

### 4. OrderItem

Stores line items for orders.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| OrderId | int | No | FK to Order |
| BookId | int | No | FK to Book |
| Quantity | int | No | Quantity ordered |

**Foreign Keys:**
- OrderId → Order(Id) [CASCADE DELETE]
- BookId → Book(Id)

**Notes:**
- Deleting an order will cascade delete its items
- Book reference preserved (no cascade delete)

---

### 5. ShoppingCart

Stores shopping cart sessions.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| CorrelationId | nvarchar(MAX) | No | Session identifier (GUID) |

**Notes:**
- CorrelationId stored in browser cookie
- Supports anonymous shopping
- Cart persists across sessions

---

### 6. ShoppingCartItem

Stores items in shopping carts and wishlists.

**Primary Key:** (Id, ShoppingCartId) - Composite

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Part of composite PK |
| ShoppingCartId | int | No | FK to ShoppingCart, part of composite PK |
| BookId | int | No | FK to Book |
| Quantity | int | No | Desired quantity |
| WantToBuy | bit | No | True=Cart, False=Wishlist |

**Foreign Keys:**
- ShoppingCartId → ShoppingCart(Id) [CASCADE DELETE]
- BookId → Book(Id)

**Notes:**
- Composite key allows multiple carts with same item IDs
- WantToBuy distinguishes cart items from wishlist items
- Deleting a cart cascades to its items

---

### 7. Offer

Stores customer offers to sell used books.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| CustomerId | int | No | FK to Customer |
| BookName | nvarchar(MAX) | No | Title of book offered |
| Author | nvarchar(MAX) | No | Author name |
| ISBN | nvarchar(MAX) | Yes | ISBN number |
| BookTypeId | int | No | FK to ReferenceData |
| ConditionId | int | No | FK to ReferenceData |
| GenreId | int | No | FK to ReferenceData |
| PublisherId | int | No | FK to ReferenceData |
| BookPrice | decimal(18,2) | No | Price requested by customer |
| FrontUrl | nvarchar(MAX) | Yes | URL to uploaded cover image |
| Summary | nvarchar(MAX) | Yes | Description |
| OfferStatus | int | No | Status (enum): PendingApproval/Approved/Rejected |
| Comment | nvarchar(MAX) | Yes | Admin comments |

**Foreign Keys:**
- CustomerId → Customer(Id)
- PublisherId → ReferenceData(Id)
- BookTypeId → ReferenceData(Id)
- GenreId → ReferenceData(Id)
- ConditionId → ReferenceData(Id)

---

### 8. Address

Stores customer shipping/billing addresses.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| CustomerId | int | No | FK to Customer |
| AddressLine1 | nvarchar(MAX) | No | Primary address line |
| AddressLine2 | nvarchar(MAX) | Yes | Secondary address line |
| City | nvarchar(MAX) | No | City name |
| State | nvarchar(MAX) | No | State/Province |
| Country | nvarchar(MAX) | No | Country |
| ZipCode | nvarchar(MAX) | No | Postal/ZIP code |
| IsActive | bit | No | Active flag (default: 1) |

**Foreign Keys:**
- CustomerId → Customer(Id)

**Notes:**
- Multiple addresses per customer supported
- IsActive allows soft delete
- Used by Order table for shipping information

---

### 9. ReferenceData

Stores lookup data for dropdowns and categorization.

**Primary Key:** Id (int, identity)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| Id | int IDENTITY(1,1) | No | Primary key |
| DataType | int | No | Type enum: Genre/Publisher/BookType/Condition |
| Text | nvarchar(MAX) | No | Display text |

**DataType Values:**
- 0 = Genre (Fiction, Non-fiction, Mystery, etc.)
- 1 = Publisher (Publishing companies)
- 2 = BookType (Hardcover, Paperback, etc.)
- 3 = Condition (New, Like New, Good, Fair, Poor)

**Notes:**
- Generic table for all reference data
- DataType discriminates between types
- Used by Book and Offer tables

---

### 10. __MigrationHistory

Entity Framework migration tracking table (auto-generated).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| MigrationId | nvarchar(150) | No | Migration identifier |
| ContextKey | nvarchar(300) | No | Context name |
| Model | varbinary(MAX) | No | Serialized model |
| ProductVersion | nvarchar(32) | No | EF version |

**Primary Key:** (MigrationId, ContextKey)

---

## Relationships

### Entity Relationship Diagram

```
                    ┌─────────────┐
                    │  Customer   │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
     ┌──────────┐   ┌──────────┐   ┌──────────┐
     │ Address  │   │  Order   │   │  Offer   │
     └──────────┘   └────┬─────┘   └────┬─────┘
                         │              │
                         ▼              │
                   ┌───────────┐        │
                   │ OrderItem │        │
                   └─────┬─────┘        │
                         │              │
                         ▼              ▼
                   ┌────────────────────────┐
                   │         Book           │
                   └────────────────────────┘
                         │ │ │ │
          ┌──────────────┘ │ │ └───────────────┐
          │   ┌────────────┘ └────────────┐    │
          ▼   ▼                           ▼    ▼
    ┌──────────────────────────────────────────────┐
    │            ReferenceData                      │
    │  (Publisher, BookType, Genre, Condition)     │
    └──────────────────────────────────────────────┘


    ┌──────────────┐
    │ShoppingCart  │
    └──────┬───────┘
           │
           ▼
    ┌──────────────────┐
    │ShoppingCartItem  │────────────▶ Book
    └──────────────────┘
```

### Relationship Summary

| Parent | Child | Relationship | Cascade Delete |
|--------|-------|--------------|----------------|
| Customer | Order | 1:Many | No |
| Customer | Address | 1:Many | No |
| Customer | Offer | 1:Many | No |
| Order | OrderItem | 1:Many | Yes |
| Book | OrderItem | 1:Many | No |
| Address | Order | 1:Many | No |
| ReferenceData | Book | 1:Many | No |
| ReferenceData | Offer | 1:Many | No |
| ShoppingCart | ShoppingCartItem | 1:Many | Yes |
| Book | ShoppingCartItem | 1:Many | No |

**Cascade Delete Strategy:**
- OrderItem: CASCADE (when Order is deleted)
- ShoppingCartItem: CASCADE (when ShoppingCart is deleted)
- All other relationships: NO CASCADE (preserve data integrity)

---

## Indexes

### Clustered Indexes (Primary Keys)

All tables have clustered indexes on their primary keys (Id column) with IDENTITY(1,1).

### Non-Clustered Indexes

**Customer.Sub:**
```sql
CREATE UNIQUE NONCLUSTERED INDEX IX_Customer_Sub 
ON Customer(Sub ASC);
```
- **Purpose:** Fast lookup by authentication identifier
- **Uniqueness:** Enforces one customer per authentication account

**Foreign Key Indexes:**

Entity Framework automatically creates indexes on foreign key columns for:
- Book.PublisherId
- Book.BookTypeId
- Book.GenreId
- Book.ConditionId
- Order.CustomerId
- Order.AddressId
- OrderItem.OrderId
- OrderItem.BookId
- Offer.CustomerId
- Offer.PublisherId
- Offer.BookTypeId
- Offer.GenreId
- Offer.ConditionId
- Address.CustomerId
- ShoppingCartItem.ShoppingCartId
- ShoppingCartItem.BookId

---

## Data Types

### Numeric Types

- **int:** Integer values (IDs, quantities, status enums)
- **decimal(18,2):** Monetary values (prices, totals)
  - 18 total digits
  - 2 decimal places
  - Range: -999,999,999,999,999.99 to 999,999,999,999,999.99

### String Types

- **nvarchar(MAX):** Variable-length Unicode strings (most text fields)
- **nvarchar(450):** Fixed-length for indexed columns (Customer.Sub)

**Note:** nvarchar uses 2 bytes per character (Unicode support)

### Date/Time Types

- **datetime2:** High-precision date and time
  - Range: 0001-01-01 to 9999-12-31
  - Precision: 100 nanoseconds
  - Used for: DateOfBirth, DeliveryDate

### Boolean Types

- **bit:** Boolean values (IsActive, WantToBuy)
  - 0 = False
  - 1 = True

### Binary Types

- **varbinary(MAX):** Binary data (EF migration model storage)

---

## Seed Data

### Reference Data

The BookstoreDbInitializer seeds the following reference data:

#### Genres (DataType = 0)
- Fiction
- Non-fiction
- Mystery
- Science Fiction
- Fantasy
- Biography
- History
- Self-Help
- Romance
- Thriller

#### Publishers (DataType = 1)
- Penguin Random House
- HarperCollins
- Simon & Schuster
- Hachette
- Macmillan
- Scholastic
- Wiley
- Oxford University Press

#### Book Types (DataType = 2)
- Hardcover
- Paperback
- Mass Market Paperback
- Library Binding

#### Conditions (DataType = 3)
- New
- Like New
- Very Good
- Good
- Acceptable

### Sample Books

The initializer creates 20-30 sample books for development:
- Various genres and authors
- Different conditions and prices
- Sample cover images
- Varying stock quantities

### Admin User

A default admin customer is created for local authentication:
- Sub: "local-admin"
- Username: "Admin"
- FirstName: "Admin"
- LastName: "User"

---

## Database Creation Scripts

### LocalDB (Development)

```sql
CREATE DATABASE BookStoreClassic;
GO

USE BookStoreClassic;
GO

-- Tables are created automatically by Entity Framework
-- on first run when BookstoreDbInitializer runs
```

**Connection String:**
```
Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;MultipleActiveResultSets=true;Integrated Security=SSPI;
```

### SQL Server (Production)

For production deployment, use the provided script:
- Location: `db-scripts/bobs-used-bookstore-classic-db.sql`
- Creates database and all tables
- Includes seed data
- Sets up constraints and indexes

---

## Migration to PostgreSQL Considerations

### Data Type Mappings

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| int IDENTITY | serial / integer with sequence | Auto-increment |
| nvarchar(MAX) | text | Unlimited length |
| nvarchar(450) | varchar(450) | Fixed length |
| decimal(18,2) | numeric(18,2) | Same precision |
| datetime2 | timestamp | PostgreSQL default |
| bit | boolean | True/false |
| varbinary(MAX) | bytea | Binary data |

### Naming Conventions

PostgreSQL considerations:
- Table/column names are case-sensitive (use lowercase or quotes)
- Reserved keywords differ from SQL Server
- Index naming conventions may differ

### Query Differences

- String concatenation: `+` → `||`
- ISNULL() → COALESCE()
- GETDATE() → NOW() or CURRENT_TIMESTAMP
- TOP → LIMIT

### Entity Framework Core Changes

- Use Npgsql.EntityFrameworkCore.PostgreSQL
- Update connection string format
- Review provider-specific behaviors
- Test migrations thoroughly

---

**Next:** 06-dependencies-and-packages-inventory.md
