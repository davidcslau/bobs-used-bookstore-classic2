# Database Schema Documentation

## Overview

The Bob's Used Bookstore Classic application uses a relational database schema designed using Entity Framework Code-First approach. The schema supports a used bookstore e-commerce system with customer management, inventory tracking, order processing, and resale offers.

## Database: BookStoreClassic

### Connection String (Development)
```
Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;MultipleActiveResultSets=true;Integrated Security=SSPI;
```

### Entity Framework Configuration
- **Provider**: System.Data.SqlClient
- **EF Version**: 6.5.1
- **Approach**: Code-First
- **Conventions**: PluralizingTableNameConvention removed (singular table names)

## Entity Models

### 1. Book Entity

**Table Name**: `Book`

**Purpose**: Stores inventory of books available for sale

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| Name | nvarchar(MAX) | Yes | - | Book title |
| Author | nvarchar(MAX) | Yes | - | Author name(s) |
| Year | int | Yes | - | Publication year |
| ISBN | nvarchar(MAX) | Yes | - | ISBN number |
| PublisherId | int | No | FK | Reference to Publisher (ReferenceData) |
| BookTypeId | int | No | FK | Reference to BookType (ReferenceData) |
| GenreId | int | No | FK | Reference to Genre (ReferenceData) |
| ConditionId | int | No | FK | Reference to Condition (ReferenceData) |
| CoverImageUrl | nvarchar(MAX) | Yes | - | URL to book cover image |
| Summary | nvarchar(MAX) | Yes | - | Book description/summary |
| Price | decimal(18,2) | No | - | Selling price |
| Quantity | int | No | - | Available stock quantity |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- Many-to-One with ReferenceDataItem (Publisher) - Cascade: No
- Many-to-One with ReferenceDataItem (BookType) - Cascade: No
- Many-to-One with ReferenceDataItem (Genre) - Cascade: No
- Many-to-One with ReferenceDataItem (Condition) - Cascade: No

**Business Rules**:
- LowBookThreshold = 5 (stock level warning threshold)
- IsInStock = Quantity > 0
- IsLowInStock = Quantity <= LowBookThreshold

**Indexes**:
- Primary Key on Id (Clustered)
- Foreign Keys on PublisherId, BookTypeId, GenreId, ConditionId

### 2. Customer Entity

**Table Name**: `Customer`

**Purpose**: Stores customer account information

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| Sub | nvarchar(450) | Yes | UK | Subject ID from authentication provider (Cognito) |
| Username | nvarchar(MAX) | Yes | - | Customer username |
| FirstName | nvarchar(MAX) | Yes | - | First name |
| LastName | nvarchar(MAX) | Yes | - | Last name |
| Email | nvarchar(MAX) | Yes | - | Email address |
| DateOfBirth | datetime | Yes | - | Date of birth |
| Phone | nvarchar(MAX) | Yes | - | Phone number |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- One-to-Many with Address
- One-to-Many with Order
- One-to-Many with Offer

**Indexes**:
- Primary Key on Id (Clustered)
- Unique Index on Sub

**Computed Properties**:
- FullName = FirstName + " " + LastName

### 3. Order Entity

**Table Name**: `Order`

**Purpose**: Stores customer purchase orders

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| CustomerId | int | No | FK | Reference to Customer |
| AddressId | int | No | - | Reference to delivery Address |
| DeliveryDate | datetime | No | - | Expected delivery date (default: Now + 7 days) |
| OrderStatus | int | No | - | Order status enum (default: Pending) |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- Many-to-One with Customer - Cascade: No
- Many-to-One with Address
- One-to-Many with OrderItem

**Computed Properties**:
- SubTotal = Sum of (OrderItem.Book.Price)
- Tax = SubTotal * 0.1 (10% tax)
- Total = SubTotal + Tax

**OrderStatus Enum**:
- 0 = Pending
- 1 = Processing
- 2 = Shipped
- 3 = Delivered
- 4 = Cancelled

### 4. OrderItem Entity

**Table Name**: `OrderItem`

**Purpose**: Line items for orders (many-to-many between Order and Book)

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| OrderId | int | No | FK | Reference to Order |
| BookId | int | No | FK | Reference to Book |
| Quantity | int | No | - | Quantity ordered |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- Many-to-One with Order
- Many-to-One with Book

### 5. ShoppingCart Entity

**Table Name**: `ShoppingCart`

**Purpose**: Stores customer shopping carts (both cart and wishlist)

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| CorrelationId | nvarchar(MAX) | Yes | - | Session/user correlation identifier |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- One-to-Many with ShoppingCartItem

### 6. ShoppingCartItem Entity

**Table Name**: `ShoppingCartItem`

**Purpose**: Items in shopping cart or wishlist

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment (Identity) |
| ShoppingCartId | int | No | PK | Reference to ShoppingCart (composite key) |
| BookId | int | No | FK | Reference to Book |
| Quantity | int | No | - | Quantity in cart |
| WantToBuy | bit | No | - | True = Cart, False = Wishlist |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- Many-to-One with ShoppingCart
- Many-to-One with Book

**Composite Primary Key**: (Id, ShoppingCartId)

**Business Logic**:
- WantToBuy = true: Item in shopping cart
- WantToBuy = false: Item in wishlist

### 7. Address Entity

**Table Name**: `Address`

**Purpose**: Customer shipping/billing addresses

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| CustomerId | int | No | FK | Reference to Customer |
| AddressLine1 | nvarchar(MAX) | Yes | - | Street address line 1 |
| AddressLine2 | nvarchar(MAX) | Yes | - | Street address line 2 |
| City | nvarchar(MAX) | Yes | - | City name |
| State | nvarchar(MAX) | Yes | - | State/province |
| Country | nvarchar(MAX) | Yes | - | Country |
| ZipCode | nvarchar(MAX) | Yes | - | Postal code |
| IsActive | bit | No | - | Address active status (default: true) |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- Many-to-One with Customer
- One-to-Many with Order (addresses can be reused)

### 8. Offer Entity

**Table Name**: `Offer`

**Purpose**: Customer book resale offers (customers selling books to the store)

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| CustomerId | int | No | FK | Reference to Customer making offer |
| BookName | nvarchar(MAX) | Yes | - | Book title |
| Author | nvarchar(MAX) | Yes | - | Author name |
| ISBN | nvarchar(MAX) | Yes | - | ISBN number |
| BookTypeId | int | No | FK | Reference to BookType (ReferenceData) |
| ConditionId | int | No | FK | Reference to Condition (ReferenceData) |
| GenreId | int | No | FK | Reference to Genre (ReferenceData) |
| PublisherId | int | No | FK | Reference to Publisher (ReferenceData) |
| FrontUrl | nvarchar(MAX) | Yes | - | URL to uploaded book image |
| Summary | nvarchar(MAX) | Yes | - | Book description |
| BookPrice | decimal(18,2) | No | - | Offered price |
| OfferStatus | int | No | - | Offer status enum (default: PendingApproval) |
| Comment | nvarchar(MAX) | Yes | - | Admin comments on offer |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**Relationships**:
- Many-to-One with Customer
- Many-to-One with ReferenceDataItem (Publisher) - Cascade: No
- Many-to-One with ReferenceDataItem (BookType) - Cascade: No
- Many-to-One with ReferenceDataItem (Genre) - Cascade: No
- Many-to-One with ReferenceDataItem (Condition) - Cascade: No

**OfferStatus Enum**:
- 0 = PendingApproval
- 1 = Approved
- 2 = Rejected

### 9. ReferenceDataItem Entity

**Table Name**: `ReferenceData`

**Purpose**: Lookup/reference data (genres, publishers, book types, conditions)

**Fields**:

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| Id | int | No | PK | Auto-increment primary key |
| DataType | int | No | - | Type of reference data (enum) |
| Text | nvarchar(MAX) | Yes | - | Display text value |
| CreatedBy | nvarchar(MAX) | Yes | - | User who created the record |
| CreatedOn | datetime | No | - | Creation timestamp |
| UpdatedOn | datetime | No | - | Last update timestamp |
| RowVersion | timestamp | No | - | Concurrency token |

**ReferenceDataType Enum**:
- 0 = Genre (e.g., Fiction, Non-Fiction, Mystery)
- 1 = Publisher (e.g., Penguin, HarperCollins)
- 2 = BookType (e.g., Hardcover, Paperback, eBook)
- 3 = Condition (e.g., New, Like New, Good, Acceptable)

**Usage**:
- Single table for all reference data types
- Discriminated by DataType field
- Used by Book and Offer entities for categorization

## Entity Base Class

All entities inherit from `Entity` base class:

```csharp
public abstract class Entity
{
    public int Id { get; set; }
    public string CreatedBy { get; set; }
    public DateTime CreatedOn { get; set; } = DateTime.Now;
    public DateTime UpdatedOn { get; set; } = DateTime.Now;
    public byte[] RowVersion { get; set; } // Concurrency token
}
```

## Entity Relationships Diagram

```
┌─────────────┐
│  Customer   │
└──────┬──────┘
       │
       ├──────────────────────┬──────────────────────┬─────────────────
       │                      │                      │
       ▼                      ▼                      ▼
┌─────────────┐        ┌─────────────┐      ┌─────────────┐
│   Address   │        │    Order    │      │    Offer    │
└─────────────┘        └──────┬──────┘      └──────┬──────┘
                              │                    │
                              ▼                    │
                       ┌─────────────┐             │
                       │  OrderItem  │             │
                       └──────┬──────┘             │
                              │                    │
       ┌──────────────────────┼────────────────────┘
       │                      │
       ▼                      ▼
┌─────────────┐        ┌──────────────────┐
│    Book     │◄───────│  ReferenceDataItem│
└──────┬──────┘        └──────────────────┘
       │                      ▲
       │                      │
       ▼                      │
┌─────────────┐               │
│ShoppingCart │               │
└──────┬──────┘               │
       │                      │
       ▼                      │
┌─────────────┐               │
│ShoppingCart │               │
│    Item     │───────────────┘
└─────────────┘
```

## Database Constraints

### Primary Keys
All tables have an auto-incrementing integer primary key named `Id`
- Clustered index on Id
- Identity specification (1, 1)

### Foreign Keys
- **Book**: PublisherId, BookTypeId, GenreId, ConditionId → ReferenceData.Id (No Cascade)
- **Offer**: CustomerId → Customer.Id, PublisherId, BookTypeId, GenreId, ConditionId → ReferenceData.Id (No Cascade)
- **Order**: CustomerId → Customer.Id (No Cascade), AddressId → Address.Id
- **OrderItem**: OrderId → Order.Id, BookId → Book.Id
- **ShoppingCartItem**: ShoppingCartId → ShoppingCart.Id, BookId → Book.Id
- **Address**: CustomerId → Customer.Id

### Unique Constraints
- **Customer.Sub**: Unique index (maps to authentication provider subject ID)

### Concurrency Control
All entities have a `RowVersion` field (timestamp type) for optimistic concurrency control

## Indexes

### Existing Indexes
1. **Customer**: Unique index on `Sub` field
2. All foreign key columns have implicit indexes

### Recommended Additional Indexes (for migration)
1. **Book**: Index on `(Name, Author)` for search performance
2. **Book**: Index on `(GenreId, BookTypeId, ConditionId)` for filtering
3. **Order**: Index on `CustomerId` for customer order history
4. **Order**: Index on `CreatedOn` for date-based queries
5. **ShoppingCart**: Index on `CorrelationId` for session lookup
6. **ReferenceData**: Index on `DataType` for reference data queries

## Data Types

### String Fields
- Most string fields use `nvarchar(MAX)` for maximum flexibility
- Unicode support (nvarchar) for international characters
- No length constraints (MAX) - consider adding for performance in migration

### Numeric Fields
- **Integers**: Standard `int` (4 bytes)
- **Decimals**: `decimal(18,2)` for money (18 total digits, 2 decimal places)

### Date/Time Fields
- **datetime**: SQL Server datetime type
- Stored in UTC would be best practice (currently not enforced)

### Boolean Fields
- **bit**: SQL Server bit type (0/1)
- .NET bool maps to bit

### Binary Fields
- **timestamp**: Row version for concurrency (8 bytes)
- Automatically updated by SQL Server

## Business Rules Enforced in Database

### Cascade Delete Rules
Most foreign keys have `WillCascadeOnDelete(false)` to prevent accidental data loss:
- Deleting a Customer does NOT delete their Orders, Addresses, or Offers
- Deleting a ReferenceDataItem (Genre) does NOT delete Books using it
- Manual cleanup or soft deletes should be implemented

### Default Values
- **Order.DeliveryDate**: Default = DateTime.Now.AddDays(7)
- **Order.OrderStatus**: Default = OrderStatus.Pending (0)
- **Offer.OfferStatus**: Default = OfferStatus.PendingApproval (0)
- **Address.IsActive**: Default = true
- **ShoppingCartItem.WantToBuy**: Determines cart vs wishlist
- **Entity.CreatedOn**: Default = DateTime.Now
- **Entity.UpdatedOn**: Default = DateTime.Now

### Required Fields
Fields marked as NOT NULL:
- All Id fields (primary keys)
- All foreign key fields
- Price and Quantity fields
- Status enums
- Timestamps (CreatedOn, UpdatedOn, RowVersion)

## Sample Data Requirements

### ReferenceData (Required for Application to Function)

**Genres** (DataType = 0):
- Fiction
- Non-Fiction
- Mystery
- Science Fiction
- Romance
- Biography
- etc.

**Publishers** (DataType = 1):
- Penguin Random House
- HarperCollins
- Simon & Schuster
- etc.

**BookTypes** (DataType = 2):
- Hardcover
- Paperback
- Mass Market Paperback
- eBook

**Conditions** (DataType = 3):
- New
- Like New
- Very Good
- Good
- Acceptable

## Database Initialization

**Initializer**: `BookstoreDbInitializer` (inherits from database initializer)

**Purpose**: Seeds initial reference data

**Configuration**: Set in `ApplicationDbContext.OnModelCreating()`

```csharp
Database.SetInitializer(new BookstoreDbInitializer());
```

## SQL Server Specific Features

### Features Used
1. **LocalDB**: For development (lightweight SQL Server)
2. **Identity Columns**: Auto-incrementing primary keys
3. **Timestamp**: Concurrency tokens
4. **Clustered Indexes**: On primary keys
5. **Non-Clustered Indexes**: On foreign keys and unique constraints

### Features NOT Used (Opportunities for Enhancement)
1. **Stored Procedures**: All data access via Entity Framework
2. **Views**: No database views defined
3. **Triggers**: No triggers used
4. **Computed Columns**: Calculations done in application layer
5. **Full-Text Search**: Using LIKE queries instead
6. **JSON Columns**: Not available in EF6/SQL Server 2016

## Migration to PostgreSQL Considerations

### Data Type Mappings
- `nvarchar(MAX)` → `text` or `varchar`
- `int` → `integer`
- `decimal(18,2)` → `numeric(18,2)`
- `datetime` → `timestamp`
- `bit` → `boolean`
- `timestamp` → `bytea` with trigger or use built-in version columns

### Syntax Differences
- Identity columns: Use `SERIAL` or `IDENTITY` (PostgreSQL 10+)
- String comparison: PostgreSQL is case-sensitive by default
- LIKE queries: May need to use ILIKE for case-insensitive searches
- Date functions: Different syntax for date manipulation

### Feature Enhancements
- Consider using PostgreSQL-specific types (JSONB, arrays)
- Use ENUM types instead of integer enums
- Implement proper indexes for text search
- Consider table partitioning for large tables

## Performance Characteristics

### Current Size Estimates
- **Book**: Hundreds to thousands of records
- **Customer**: Hundreds to thousands of records
- **Order**: Thousands to tens of thousands of records
- **OrderItem**: Tens of thousands of records
- **ShoppingCart**: Active carts only (hundreds)
- **ShoppingCartItem**: Thousands of records (cleaned up periodically)
- **Address**: Thousands of records
- **Offer**: Hundreds to thousands of records
- **ReferenceData**: Dozens to hundreds of records (relatively static)

### Query Performance
- Most queries are simple entity lookups (fast)
- Book search can be slow with LIKE '%term%' queries
- Order history queries should be paginated
- Consider materialized views for statistics

## Summary

The database schema is well-normalized with clear entity relationships and proper foreign key constraints. The use of Entity Framework Code-First provides type safety and maintainability. The schema supports all core bookstore operations including inventory management, customer accounts, shopping cart, orders, and resale offers. The reference data pattern provides flexibility for categorization without hardcoded values.

Key characteristics:
- **8 main entities** + 1 reference data table
- **Code-First approach** with fluent API configuration
- **Optimistic concurrency** with timestamp fields
- **No cascade deletes** to prevent accidental data loss
- **Single table** for all reference data types
- **Composite key** for ShoppingCartItem
- **Separation** between cart and wishlist in same table
