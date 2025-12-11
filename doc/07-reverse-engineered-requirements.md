# Reverse-Engineered Requirements Specification

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Application:** Bob's Used Bookstore Classic

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Business Requirements](#business-requirements)
3. [Functional Requirements](#functional-requirements)
4. [User Roles and Permissions](#user-roles-and-permissions)
5. [Business Rules](#business-rules)
6. [User Workflows](#user-workflows)
7. [Non-Functional Requirements](#non-functional-requirements)

---

## Executive Summary

Bob's Used Bookstore Classic is an e-commerce web application that enables customers to browse and purchase used books while also allowing them to sell their own used books back to the store. The application serves two primary user types: customers and administrators.

**Core Business Objectives:**
- Sell used books to customers online
- Accept used book offers from customers
- Manage book inventory
- Process customer orders
- Provide a user-friendly shopping experience

---

## Business Requirements

### BR-001: Book Sales
**Description:** The system shall enable the sale of used books to customers through an online storefront.

**Business Value:** Primary revenue stream

**Success Criteria:**
- Customers can browse available books
- Customers can add books to cart
- Customers can complete purchase
- Orders are tracked and fulfillable

---

### BR-002: Book Resale Program
**Description:** The system shall accept offers from customers to sell their used books to the bookstore.

**Business Value:** Inventory acquisition at favorable prices

**Success Criteria:**
- Customers can submit book offers
- Admin can review and approve/reject offers
- Approved offers can be converted to inventory

---

### BR-003: Inventory Management
**Description:** The system shall track book inventory including quantities, pricing, and conditions.

**Business Value:** Accurate stock management and pricing

**Success Criteria:**
- Real-time inventory tracking
- Low stock alerts
- Stock reduction on orders
- Price management

---

### BR-004: Customer Management
**Description:** The system shall maintain customer profiles and order history.

**Business Value:** Customer relationship management

**Success Criteria:**
- Customer registration and authentication
- Order history tracking
- Address management
- Profile management

---

### BR-005: Order Processing
**Description:** The system shall process customer orders from cart through fulfillment.

**Business Value:** Revenue realization and customer satisfaction

**Success Criteria:**
- Cart to order conversion
- Order status tracking
- Delivery date estimation
- Order history

---

## Functional Requirements

### Customer-Facing Features

#### F-001: Book Browsing and Search
**Priority:** Critical  
**Description:** Customers can browse and search the book catalog

**Acceptance Criteria:**
- ✓ Search by book name
- ✓ Search by author
- ✓ Filter by genre
- ✓ Filter by condition
- ✓ Filter by book type (hardcover/paperback)
- ✓ Filter by publisher
- ✓ Pagination of results
- ✓ Book detail page with cover image, summary, pricing

---

#### F-002: Book Detail View
**Priority:** Critical  
**Description:** Customers can view detailed information about a book

**Acceptance Criteria:**
- ✓ Display book cover image
- ✓ Display title, author, ISBN
- ✓ Display publication year
- ✓ Display publisher, genre, book type, condition
- ✓ Display price and availability
- ✓ Display book summary/description
- ✓ "Add to Cart" button
- ✓ "Add to Wishlist" button

---

#### F-003: Shopping Cart
**Priority:** Critical  
**Description:** Customers can manage items they wish to purchase

**Acceptance Criteria:**
- ✓ Add books to cart with quantity
- ✓ View cart contents
- ✓ Update item quantities
- ✓ Remove items from cart
- ✓ Display subtotal, tax (10%), and total
- ✓ Cart persists across sessions (correlation ID)
- ✓ Cart accessible to anonymous users
- ✓ Warning for out-of-stock items
- ✓ Proceed to checkout

---

#### F-004: Wishlist
**Priority:** Medium  
**Description:** Customers can save books for future purchase

**Acceptance Criteria:**
- ✓ Add books to wishlist
- ✓ View wishlist items
- ✓ Move wishlist items to cart
- ✓ Remove items from wishlist
- ✓ Wishlist separate from cart items

---

#### F-005: Checkout Process
**Priority:** Critical  
**Description:** Customers can complete purchase of cart items

**Acceptance Criteria:**
- ✓ Requires user authentication
- ✓ Select shipping address
- ✓ Review order items and total
- ✓ Place order
- ✓ Reduce book quantities upon order
- ✓ Clear cart after order
- ✓ Generate order confirmation
- ✓ Display expected delivery date (7 days)

---

#### F-006: Order History
**Priority:** High  
**Description:** Customers can view their past orders

**Acceptance Criteria:**
- ✓ List all customer orders
- ✓ Display order date, status, total
- ✓ View order details (items, quantities, prices)
- ✓ View delivery information
- ✓ Pagination of order list

---

#### F-007: User Authentication
**Priority:** Critical  
**Description:** Customers can register and log in

**Acceptance Criteria:**
- ✓ Local authentication (development)
- ✓ AWS Cognito authentication (production)
- ✓ Cookie-based sessions
- ✓ Claims-based identity
- ✓ Auto-create customer record on first login
- ✓ Logout functionality

---

#### F-008: Address Management
**Priority:** High  
**Description:** Customers can manage shipping addresses

**Acceptance Criteria:**
- ✓ Create new address
- ✓ Edit existing address
- ✓ Delete address (soft delete)
- ✓ Mark address as active/inactive
- ✓ Multiple addresses per customer
- ✓ Select address during checkout

---

#### F-009: Book Resale Offers
**Priority:** High  
**Description:** Customers can submit offers to sell books

**Acceptance Criteria:**
- ✓ Submit book information (title, author, ISBN, genre, condition, etc.)
- ✓ Upload book cover image
- ✓ Specify desired price
- ✓ View submitted offers
- ✓ Track offer status (Pending/Approved/Rejected)
- ✓ View admin comments on offers

---

### Administrative Features

#### F-010: Admin Dashboard
**Priority:** High  
**Description:** Admins have overview of key business metrics

**Acceptance Criteria:**
- ✓ Display total books in inventory
- ✓ Display low stock items count
- ✓ Display order statistics (today/week/month)
- ✓ Display pending offers count
- ✓ Display revenue statistics

---

#### F-011: Inventory Management
**Priority:** Critical  
**Description:** Admins can manage book inventory

**Acceptance Criteria:**
- ✓ List all books with filtering
- ✓ Add new books
- ✓ Edit book details
- ✓ Update stock quantities
- ✓ Update pricing
- ✓ Upload book cover images
- ✓ Delete books
- ✓ View book details
- ✓ Low stock indicators

---

#### F-012: Order Management
**Priority:** Critical  
**Description:** Admins can manage customer orders

**Acceptance Criteria:**
- ✓ List all orders
- ✓ Filter by status, date, customer
- ✓ View order details
- ✓ Update order status (Pending → Processing → Shipped → Delivered)
- ✓ Cancel orders
- ✓ View customer and shipping information

---

#### F-013: Offer Management
**Priority:** High  
**Description:** Admins can review and process customer offers

**Acceptance Criteria:**
- ✓ List all offers
- ✓ Filter by status, date, customer
- ✓ View offer details and uploaded images
- ✓ Approve offers with comments
- ✓ Reject offers with comments
- ✓ Track offer history

---

#### F-014: Reference Data Management
**Priority:** Medium  
**Description:** Admins can manage lookup data

**Acceptance Criteria:**
- ✓ Manage genres
- ✓ Manage publishers
- ✓ Manage book types
- ✓ Manage conditions
- ✓ Add new reference data items
- ✓ Delete reference data items

---

## User Roles and Permissions

### Anonymous User
**Description:** Non-authenticated visitor

**Permissions:**
- Browse books
- Search books
- View book details
- Add items to cart
- Add items to wishlist
- View cart and wishlist

**Restrictions:**
- Cannot checkout
- Cannot view orders
- Cannot submit offers
- Cannot manage addresses

---

### Authenticated Customer
**Description:** Registered and logged-in customer

**Permissions:**
- All Anonymous User permissions
- Checkout and place orders
- View order history
- Manage addresses
- Submit resale offers
- View own offers
- Update profile

**Restrictions:**
- Cannot access admin functions
- Can only view own orders and offers
- Cannot manage inventory
- Cannot update order statuses

---

### Administrator
**Description:** Store admin/staff

**Permissions:**
- All Authenticated Customer permissions
- View all orders
- Update order statuses
- View all offers
- Approve/reject offers
- Manage inventory (CRUD books)
- Manage reference data
- View dashboard statistics
- Access admin area

---

## Business Rules

### BR-BOOK-001: Stock Management
- Book quantity cannot be negative
- Stock is reduced when order is placed
- Low stock threshold is 5 units
- Out of stock items remain visible but not purchasable

### BR-BOOK-002: Pricing
- Book price must be greater than 0
- Prices stored with 2 decimal precision
- No discount functionality in current version

### BR-BOOK-003: Book Data
- Books must have: name, author, price, quantity
- Books must have reference data: publisher, genre, book type, condition
- ISBN is optional
- Cover image is optional

---

### BR-ORDER-001: Order Creation
- Orders can only be created from authenticated users
- Orders require at least one item
- Orders require shipping address
- Stock quantities validated at order time

### BR-ORDER-002: Order Calculation
- Subtotal = sum of (book price * quantity) for all items
- Tax = subtotal * 0.10 (10% tax rate)
- Total = subtotal + tax
- No shipping charges
- No discounts or promotions

### BR-ORDER-003: Order Status Flow
- New orders start with "Pending" status
- Valid status transitions: Pending → Processing → Shipped → Delivered
- Orders can be cancelled from Pending or Processing status
- Delivered and cancelled orders are final

### BR-ORDER-004: Delivery
- Default delivery date is 7 days from order placement
- Delivery date can be updated by admin

---

### BR-CART-001: Shopping Cart
- Carts use correlation ID (GUID in cookie)
- Carts support anonymous users
- Cart items persist across sessions
- Cart and wishlist share same infrastructure (WantToBuy flag differentiates)

### BR-CART-002: Cart to Order
- Checkout requires authentication
- Cart is cleared after successful order
- Out of stock items cannot be ordered
- Book quantities checked at checkout time

---

### BR-OFFER-001: Offer Submission
- Offers require authentication
- Offers must have: book name, author, price, genre, condition, book type, publisher
- Offer status defaults to "Pending Approval"
- Image upload is optional

### BR-OFFER-002: Offer Review
- Only admins can approve/reject offers
- Admin comments are optional
- Approved offers don't automatically become inventory (manual process)
- Rejected offers remain visible to customer with reason

---

### BR-ADDRESS-001: Address Management
- Customers can have multiple addresses
- At least one address required for checkout
- Addresses can be marked inactive instead of deleted
- Addresses linked to orders cannot be hard deleted

---

### BR-AUTH-001: Authentication
- Local mode: hardcoded admin credentials for development
- AWS mode: Cognito User Pools with OpenID Connect
- Customer record auto-created on first login
- Customer linked to auth via "Sub" identifier

---

## User Workflows

### Workflow 1: Browse and Purchase Books

```
1. Customer visits home page
2. Customer searches for books by title or browses by genre
3. Customer views book details
4. Customer adds book to cart (with quantity)
5. Customer continues shopping or proceeds to cart
6. Customer reviews cart items and totals
7. Customer clicks "Checkout"
8. System prompts for login if not authenticated
9. Customer logs in (or registers)
10. Customer selects shipping address (or creates new one)
11. Customer reviews order summary
12. Customer places order
13. System reduces book quantities
14. System clears cart
15. System displays order confirmation with delivery date
16. Customer can view order in order history
```

---

### Workflow 2: Submit Book Resale Offer

```
1. Customer logs in
2. Customer navigates to Resale page
3. Customer clicks "Create New Offer"
4. Customer enters book information:
   - Title, Author, ISBN
   - Select Genre, Publisher, Book Type, Condition
   - Enter desired price
   - Upload cover image (optional)
5. Customer submits offer
6. System creates offer with "Pending Approval" status
7. Customer can view offer in "My Offers" list
8. Admin receives notification (if configured)
```

---

### Workflow 3: Admin Reviews Offer

```
1. Admin logs into admin area
2. Admin navigates to Offers management
3. Admin sees list of offers with status filter
4. Admin filters for "Pending Approval"
5. Admin clicks on offer to view details
6. Admin reviews book information and uploaded image
7. Admin decides to approve or reject
8. If approving:
   a. Admin enters comment (optional)
   b. Admin clicks "Approve"
   c. Offer status changes to "Approved"
9. If rejecting:
   a. Admin enters reason comment
   b. Admin clicks "Reject"
   c. Offer status changes to "Rejected"
10. Customer sees updated status and comment
```

---

### Workflow 4: Admin Manages Inventory

```
1. Admin logs into admin area
2. Admin navigates to Inventory management
3. Admin sees list of books with low stock indicators
4. To add new book:
   a. Admin clicks "Add Book"
   b. Admin enters book details
   c. Admin selects reference data (genre, publisher, etc.)
   d. Admin uploads cover image
   e. Admin sets price and quantity
   f. Admin saves book
5. To update existing book:
   a. Admin clicks on book
   b. Admin edits details
   c. Admin updates quantity
   d. Admin saves changes
6. To delete book:
   a. Admin clicks "Delete"
   b. Admin confirms deletion
```

---

### Workflow 5: Admin Processes Orders

```
1. Admin logs into admin area
2. Admin navigates to Orders management
3. Admin sees list of orders with filters
4. Admin filters by status "Pending"
5. Admin clicks on order to view details
6. Admin reviews items, customer, and shipping address
7. Admin updates status to "Processing"
8. After packaging:
   a. Admin updates status to "Shipped"
9. After delivery confirmation:
   a. Admin updates status to "Delivered"
10. Customer sees updated status in order history
```

---

## Non-Functional Requirements

### NFR-001: Performance
- Page load time < 3 seconds
- Search results load < 2 seconds
- Support 100 concurrent users (development target)

### NFR-002: Security
- HTTPS in production
- Encrypted passwords (handled by Cognito)
- SQL injection protection via Entity Framework
- XSS protection via Razor encoding
- CSRF protection via anti-forgery tokens
- Image upload validation

### NFR-003: Usability
- Responsive design (desktop and mobile)
- Intuitive navigation
- Clear error messages
- Client-side validation
- Consistent UI patterns

### NFR-004: Reliability
- 99% uptime in production
- Graceful error handling
- Transaction integrity for orders
- Data backup and recovery

### NFR-005: Scalability
- Support growing book catalog (thousands of books)
- Support growing customer base
- Horizontal scaling capability (stateless design)

### NFR-006: Maintainability
- Layered architecture
- Dependency injection
- Repository pattern
- Clear separation of concerns
- Comprehensive logging

### NFR-007: Compatibility
- Support modern browsers (Chrome, Firefox, Edge, Safari)
- Windows Server deployment
- IIS hosting
- SQL Server database

### NFR-008: Accessibility
- Basic WCAG 2.0 Level A compliance
- Keyboard navigation
- Screen reader friendly
- Alt text for images

---

## Features NOT Implemented

The following features are commonly found in e-commerce sites but are NOT in the current version:

### Payment Processing
- No payment gateway integration
- No credit card processing
- No PayPal or third-party payments
- Orders are created but payment is manual

### Advanced Features
- No product reviews/ratings
- No product recommendations
- No email notifications
- No shipment tracking integration
- No returns/refunds workflow
- No discount codes or promotions
- No gift cards
- No customer wishlists shared publicly
- No social media integration
- No analytics dashboard
- No inventory forecasting

### Customer Features
- No saved payment methods
- No order modification after placement
- No guest checkout optimization
- No multiple language support
- No currency conversion

### Admin Features
- No bulk import/export
- No advanced reporting
- No customer segmentation
- No marketing campaigns
- No A/B testing

---

**Next:** 08-reverse-engineered-technical-specification.md
