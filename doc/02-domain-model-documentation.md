# Domain Model Documentation - Bob's Used Bookstore Classic

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Namespace:** Bookstore.Domain

---

## Table of Contents
1. [Overview](#overview)
2. [Domain Entities](#domain-entities)
3. [Entity Relationships](#entity-relationships)
4. [Domain Services](#domain-services)
5. [Data Transfer Objects (DTOs)](#data-transfer-objects)
6. [Business Rules](#business-rules)

---

## Overview

The Domain layer contains all business entities, business logic, and contracts (interfaces) for services and repositories. This layer is independent of any specific data access technology or UI framework, making it the most stable and reusable part of the application.

**Design Principles:**
- Domain-Driven Design (DDD) concepts
- Rich domain models with behavior
- Encapsulation of business rules
- Explicit business terminology
- Technology-agnostic

---

## Domain Entities

### Base Entity

All domain entities inherit from a base `Entity` class:

```csharp
public abstract class Entity
{
    public int Id { get; set; }
}
```

### 1. Book Entity

**Location:** `Bookstore.Domain/Books/Book.cs`

**Purpose:** Represents a book available for purchase in the bookstore.

**Properties:**
- `Id` (int) - Primary key
- `Name` (string) - Book title
- `Author` (string) - Author name
- `Year` (int?) - Publication year (nullable)
- `ISBN` (string) - International Standard Book Number
- `PublisherId` (int) - Foreign key to ReferenceData
- `Publisher` (ReferenceDataItem) - Navigation property
- `BookTypeId` (int) - Foreign key (Hardcover, Paperback, etc.)
- `BookType` (ReferenceDataItem) - Navigation property
- `GenreId` (int) - Foreign key (Fiction, Non-fiction, etc.)
- `Genre` (ReferenceDataItem) - Navigation property
- `ConditionId` (int) - Foreign key (New, Like New, Good, etc.)
- `Condition` (ReferenceDataItem) - Navigation property
- `CoverImageUrl` (string) - URL to book cover image
- `Summary` (string) - Book description
- `Price` (decimal) - Selling price
- `Quantity` (int) - Stock quantity

**Computed Properties:**
- `IsInStock` (bool) - Returns true if Quantity > 0
- `IsLowInStock` (bool) - Returns true if Quantity > LowBookThreshold (5)

**Methods:**
- `ReduceStockLevel(int quantity)` - Reduces stock by specified quantity

**Business Rules:**
- Low stock threshold is 5 books
- Stock cannot go below 0

**Constructor:**
```csharp
public Book(string name, string author, string ISBN, int publisherId, 
            int bookTypeId, int genreId, int conditionId, decimal price, 
            int quantity, int? year = null, string summary = null, 
            string coverImageUrl = null)
```

---

### 2. Customer Entity

**Location:** `Bookstore.Domain/Customers/Customer.cs`

**Purpose:** Represents a registered customer in the system.

**Properties:**
- `Id` (int) - Primary key
- `Sub` (string) - Subject identifier from identity provider (Cognito or local)
- `Username` (string) - User's login name
- `FirstName` (string) - Customer's first name
- `LastName` (string) - Customer's last name
- `FullName` (string) - Computed property: FirstName + LastName
- `Email` (string) - Email address
- `DateOfBirth` (DateTime?) - Birth date (nullable)
- `Phone` (string) - Phone number

**Business Rules:**
- `Sub` must be unique (used for authentication mapping)
- Email is required for account creation

---

### 3. Order Entity

**Location:** `Bookstore.Domain/Orders/Order.cs`

**Purpose:** Represents a customer's purchase order.

**Properties:**
- `Id` (int) - Primary key
- `CustomerId` (int) - Foreign key to Customer
- `Customer` (Customer) - Navigation property
- `AddressId` (int) - Foreign key to shipping address
- `Address` (Address) - Navigation property
- `OrderItems` (ICollection<OrderItem>) - Order line items
- `DeliveryDate` (DateTime) - Expected delivery date (default: +7 days)
- `OrderStatus` (OrderStatus enum) - Order status
- `Tax` (decimal) - Computed: SubTotal * 0.1
- `SubTotal` (decimal) - Computed: Sum of all OrderItem prices
- `Total` (decimal) - Computed: SubTotal + Tax

**Methods:**
- `AddOrderItem(Book book, int quantity)` - Adds an item to the order

**Business Rules:**
- Tax rate is 10% of subtotal
- Delivery date is automatically set to 7 days from order creation
- Order status defaults to "Pending"

**Constructor:**
```csharp
public Order(int customerId, int addressId)
```

---

### 4. OrderItem Entity

**Location:** `Bookstore.Domain/Orders/OrderItem.cs`

**Purpose:** Represents a line item in an order (which book and quantity).

**Properties:**
- `Id` (int) - Primary key
- `OrderId` (int) - Foreign key to Order
- `Order` (Order) - Navigation property
- `BookId` (int) - Foreign key to Book
- `Book` (Book) - Navigation property
- `Quantity` (int) - Number of books ordered

**Constructor:**
```csharp
public OrderItem(Order order, Book book, int quantity)
```

---

### 5. OrderStatus Enum

**Location:** `Bookstore.Domain/Orders/OrderStatus.cs`

**Values:**
- `Pending` - Order placed, not yet processed
- `Processing` - Order is being prepared
- `Shipped` - Order has been shipped
- `Delivered` - Order delivered to customer
- `Cancelled` - Order cancelled

---

### 6. ShoppingCart Entity

**Location:** `Bookstore.Domain/Carts/ShoppingCart.cs`

**Purpose:** Represents a customer's shopping cart and wishlist.

**Properties:**
- `Id` (int) - Primary key
- `CorrelationId` (string) - Session identifier for anonymous users
- `ShoppingCartItems` (List<ShoppingCartItem>) - Cart and wishlist items

**Methods:**
- `GetShoppingCartItems(ShoppingCartItemFilter filter)` - Gets items marked for purchase
- `GetWishListItems()` - Gets items in wishlist
- `AddItemToShoppingCart(int bookId, int quantity)` - Adds book to cart
- `AddItemToWishlist(int bookId)` - Adds book to wishlist
- `MoveWishListItemToShoppingCart(int shoppingCartItemId)` - Moves wishlist item to cart
- `RemoveShoppingCartItemById(int shoppingCartItemId)` - Removes item
- `GetSubTotal(ShoppingCartItemFilter filter)` - Calculates cart total

**Constructor:**
```csharp
public ShoppingCart(string correlationId)
```

---

### 7. ShoppingCartItem Entity

**Location:** `Bookstore.Domain/Carts/ShoppingCartItem.cs`

**Purpose:** Represents an item in a shopping cart or wishlist.

**Properties:**
- `Id` (int) - Primary key (composite with ShoppingCartId)
- `ShoppingCartId` (int) - Foreign key to ShoppingCart
- `ShoppingCart` (ShoppingCart) - Navigation property
- `BookId` (int) - Foreign key to Book
- `Book` (Book) - Navigation property
- `Quantity` (int) - Quantity desired
- `WantToBuy` (bool) - True for cart, False for wishlist

**Composite Key:**
- (Id, ShoppingCartId)

---

### 8. Offer Entity

**Location:** `Bookstore.Domain/Offers/Offer.cs`

**Purpose:** Represents a customer's offer to sell a used book to the bookstore.

**Properties:**
- `Id` (int) - Primary key
- `CustomerId` (int) - Foreign key to Customer
- `Customer` (Customer) - Navigation property
- `BookName` (string) - Title of book being offered
- `Author` (string) - Author name
- `ISBN` (string) - ISBN number
- `BookTypeId` (int) - Foreign key to ReferenceData
- `BookType` (ReferenceDataItem) - Navigation property
- `ConditionId` (int) - Foreign key to ReferenceData
- `Condition` (ReferenceDataItem) - Navigation property
- `GenreId` (int) - Foreign key to ReferenceData
- `Genre` (ReferenceDataItem) - Navigation property
- `PublisherId` (int) - Foreign key to ReferenceData
- `Publisher` (ReferenceDataItem) - Navigation property
- `BookPrice` (decimal) - Price customer wants for the book
- `FrontUrl` (string) - URL to uploaded book cover image
- `Summary` (string) - Description
- `OfferStatus` (OfferStatus enum) - Current status
- `Comment` (string) - Admin comments on the offer

**Constructor:**
```csharp
public Offer(int customerId, string bookName, string author, string ISBN,
             int bookTypeId, int conditionId, int genreId, int publisherId,
             decimal bookPrice)
```

---

### 9. OfferStatus Enum

**Location:** `Bookstore.Domain/Offers/OfferStatus.cs`

**Values:**
- `PendingApproval` - Offer submitted, awaiting admin review
- `Approved` - Offer accepted by admin
- `Rejected` - Offer rejected by admin

---

### 10. Address Entity

**Location:** `Bookstore.Domain/Addresses/Address.cs`

**Purpose:** Represents a customer's shipping/billing address.

**Properties:**
- `Id` (int) - Primary key
- `CustomerId` (int) - Foreign key to Customer
- `Customer` (Customer) - Navigation property
- `AddressLine1` (string) - Primary address line
- `AddressLine2` (string) - Secondary address line (apt, suite, etc.)
- `City` (string) - City name
- `State` (string) - State/Province
- `Country` (string) - Country
- `ZipCode` (string) - Postal/ZIP code
- `IsActive` (bool) - Whether address is active (default: true)

**Constructor:**
```csharp
public Address(Customer customer, string addressLine1, string addressLine2,
               string city, string state, string country, string zipCode)
```

---

### 11. ReferenceDataItem Entity

**Location:** `Bookstore.Domain/ReferenceData/ReferenceDataItem.cs`

**Purpose:** Generic reference data used for dropdowns and lookups.

**Properties:**
- `Id` (int) - Primary key
- `DataType` (ReferenceDataType enum) - Type of reference data
- `Text` (string) - Display text

**Constructor:**
```csharp
public ReferenceDataItem(ReferenceDataType referenceDataType, string text)
```

---

### 12. ReferenceDataType Enum

**Location:** `Bookstore.Domain/ReferenceData/ReferenceDataType.cs`

**Values:**
- `Genre` - Book genres (Fiction, Non-fiction, Mystery, etc.)
- `Publisher` - Publishing companies
- `BookType` - Book formats (Hardcover, Paperback, etc.)
- `Condition` - Book conditions (New, Like New, Good, Fair, Poor)

---

## Entity Relationships

### Entity Relationship Diagram

```
Customer (1) ────────────── (0..*) Order
    │                            │
    │                            │ contains
    │                            ▼
    │                       OrderItem (*.1) ────── Book
    │                            
    │
    ├─────────────── (0..*) Address
    │
    └─────────────── (0..*) Offer


ShoppingCart (1) ────────── (0..*) ShoppingCartItem (*.1) ────── Book
    

Book (*) ────────── (1) ReferenceDataItem [Publisher]
     │
     ├────────────── (1) ReferenceDataItem [BookType]
     │
     ├────────────── (1) ReferenceDataItem [Genre]
     │
     └────────────── (1) ReferenceDataItem [Condition]


Offer (*) ───────── (1) ReferenceDataItem [Publisher]
      │
      ├───────────── (1) ReferenceDataItem [BookType]
      │
      ├───────────── (1) ReferenceDataItem [Genre]
      │
      └───────────── (1) ReferenceDataItem [Condition]
```

### Key Relationships

1. **Customer → Order** (One-to-Many)
   - A customer can have multiple orders
   - Each order belongs to one customer

2. **Customer → Address** (One-to-Many)
   - A customer can have multiple addresses
   - Each address belongs to one customer

3. **Customer → Offer** (One-to-Many)
   - A customer can submit multiple offers
   - Each offer belongs to one customer

4. **Order → OrderItem** (One-to-Many)
   - An order contains multiple order items
   - Each order item belongs to one order

5. **OrderItem → Book** (Many-to-One)
   - An order item references one book
   - A book can be in multiple order items

6. **ShoppingCart → ShoppingCartItem** (One-to-Many)
   - A shopping cart contains multiple items
   - Each item belongs to one cart

7. **Book → ReferenceDataItem** (Many-to-One, multiple)
   - Each book has one publisher, book type, genre, and condition
   - Reference data items are reused across books

8. **Offer → ReferenceDataItem** (Many-to-One, multiple)
   - Each offer has one publisher, book type, genre, and condition

---

## Domain Services

### 1. IBookService

**Purpose:** Book catalog operations

**Methods:**
- `GetBookAsync(int id)` - Get book by ID
- `SearchBooksAsync(BookFilters filters, int page, int pageSize)` - Search books with pagination
- `CreateBookAsync(CreateOrUpdateBookDto dto)` - Add new book to catalog
- `UpdateBookAsync(int id, CreateOrUpdateBookDto dto)` - Update existing book
- `DeleteBookAsync(int id)` - Remove book from catalog
- `GetBookStatisticsAsync()` - Get inventory statistics

---

### 2. IOrderService

**Purpose:** Order processing operations

**Methods:**
- `GetOrderAsync(int id)` - Get order by ID
- `ListOrdersAsync(OrderFilters filters, int page, int pageSize)` - List orders with filters
- `CreateOrderFromCartAsync(int customerId, int addressId, string correlationId)` - Create order from cart
- `UpdateOrderStatusAsync(int orderId, OrderStatus status)` - Update order status
- `GetOrderStatisticsAsync()` - Get order statistics

---

### 3. IOfferService

**Purpose:** Book resale offer management

**Methods:**
- `GetOfferAsync(int id)` - Get offer by ID
- `ListOffersAsync(OfferFilters filters, int page, int pageSize)` - List offers with filters
- `CreateOfferAsync(CreateOfferDto dto)` - Submit new offer
- `UpdateOfferStatusAsync(int id, OfferStatus status, string comment)` - Review offer
- `GetOfferStatisticsAsync()` - Get offer statistics

---

### 4. IShoppingCartService

**Purpose:** Shopping cart operations

**Methods:**
- `GetShoppingCartAsync(string correlationId)` - Get cart by correlation ID
- `AddItemToCartAsync(string correlationId, int bookId, int quantity)` - Add to cart
- `AddItemToWishlistAsync(string correlationId, int bookId)` - Add to wishlist
- `MoveWishlistItemToCartAsync(string correlationId, int itemId)` - Move to cart
- `RemoveItemAsync(string correlationId, int itemId)` - Remove item
- `GetCartSummaryAsync(string correlationId)` - Get cart summary

---

### 5. ICustomerService

**Purpose:** Customer profile management

**Methods:**
- `GetCustomerBySubAsync(string sub)` - Get customer by identity sub
- `CreateOrUpdateCustomerAsync(CreateOrUpdateCustomerDto dto)` - Upsert customer
- `UpdateCustomerProfileAsync(int id, UpdateCustomerProfileDto dto)` - Update profile

---

### 6. IAddressService

**Purpose:** Address management

**Methods:**
- `GetAddressByIdAsync(int id)` - Get address by ID
- `ListAddressesByCustomerAsync(int customerId)` - Get customer addresses
- `CreateAddressAsync(CreateOrUpdateAddressDto dto)` - Create new address
- `UpdateAddressAsync(int id, CreateOrUpdateAddressDto dto)` - Update address
- `DeleteAddressAsync(int id)` - Delete address

---

### 7. IReferenceDataService

**Purpose:** Reference data lookups

**Methods:**
- `ListByTypeAsync(ReferenceDataType type)` - Get reference data by type
- `GetAllReferenceDataAsync()` - Get all reference data grouped by type
- `CreateReferenceDataItemAsync(ReferenceDataType type, string text)` - Add item
- `DeleteReferenceDataItemAsync(int id)` - Remove item

---

## Data Transfer Objects (DTOs)

DTOs are used to transfer data between layers and for API contracts.

### Book DTOs
- `BookDto` - Full book information for display
- `CreateOrUpdateBookDto` - Input for creating/updating books
- `BookSearchResultDto` - Paginated search results

### Order DTOs
- `OrderDto` - Order details for display
- `OrderItemDto` - Order item details
- `OrderSummaryDto` - Order summary information

### Offer DTOs
- `OfferDto` - Offer details
- `CreateOfferDto` - Input for creating offers

### Customer DTOs
- `CustomerDto` - Customer information
- `CreateOrUpdateCustomerDto` - Input for customer upsert
- `UpdateCustomerProfileDto` - Profile update input

### Address DTOs
- `AddressDto` - Address information
- `CreateOrUpdateAddressDto` - Input for address operations

### ShoppingCart DTOs
- `ShoppingCartDto` - Cart contents
- `ShoppingCartItemDto` - Cart item details
- `CartSummaryDto` - Cart summary with totals

### ReferenceData DTOs
- `ReferenceDataDto` - Reference data item
- `ReferenceDataGroupDto` - Grouped reference data by type

---

## Business Rules

### Book Management
1. Book quantities cannot be negative
2. Low stock threshold is 5 units
3. Books require publisher, genre, book type, and condition
4. Price must be greater than 0
5. ISBN should be unique (business rule, not enforced by database)

### Order Processing
1. Orders can only be created from items in stock
2. Tax rate is fixed at 10%
3. Default delivery is 7 days from order date
4. Book quantities are reduced when order is placed
5. Orders cannot be deleted, only cancelled

### Shopping Cart
1. Cart items can be marked for purchase (cart) or wishlist
2. Cart persists using correlation ID (session-based)
3. Out of stock items show warning but remain in cart
4. Moving from wishlist to cart changes WantToBuy flag

### Offers
1. Offers default to PendingApproval status
2. Only admin can approve/reject offers
3. Approved offers can be converted to books manually
4. Customers can only view their own offers

### Customer Management
1. Customer Sub must be unique (linked to authentication)
2. Email is required for customer accounts
3. Customers can have multiple addresses
4. At least one active address required for orders

### Address Management
1. Address can be marked inactive instead of deleted
2. Cannot delete address if used in existing orders
3. All address fields except AddressLine2 are required

---

**Next:** 03-data-access-layer-documentation.md
