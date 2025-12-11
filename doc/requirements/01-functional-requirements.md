# Functional Requirements

## Customer Features

### 1. Book Browsing and Search
- Browse books on home page
- Search books by title, author, ISBN
- Filter by genre, publisher, book type, condition
- Sort by name, price (ascending/descending)
- View book details with cover image and summary
- Pagination of search results

### 2. Shopping Cart Management
- Add books to shopping cart
- Update quantities in cart
- Remove items from cart
- View subtotal, tax, and total
- Persist cart across sessions (via correlation ID)
- Handle out-of-stock items

### 3. Wishlist Functionality
- Add books to wishlist
- View wishlist items
- Move items from wishlist to cart
- Remove items from wishlist

### 4. Checkout Process
- Select shipping address
- Review order items and totals
- Place order
- Reduce book inventory on order completion
- Calculate tax (10% of subtotal)
- Set delivery date (7 days from order)

### 5. Order Management
- View order history
- View order details
- See order status (Pending, Processing, Shipped, Delivered, Cancelled)
- View order items with book details

### 6. Address Management
- Add new shipping addresses
- Edit existing addresses
- Delete addresses
- Mark addresses as active/inactive
- Associate addresses with orders

### 7. Resale Offers
- Create book resale offers
- Upload book images
- Specify book details and condition
- Set offered price
- View offer status (Pending, Approved, Rejected)
- View admin comments on offers

### 8. User Authentication
- Login via AWS Cognito or local authentication
- Logout
- Automatic customer profile creation on first login
- Profile information from authentication provider

## Admin Features

### 1. Dashboard
- View inventory statistics (low stock, out of stock, total)
- View order statistics
- View offer statistics

### 2. Inventory Management
- List all books with filtering
- Add new books to inventory
- Edit book information
- Upload/update book cover images
- Delete books
- Track stock levels
- Mark low stock items

### 3. Order Management
- View all orders
- Filter orders by status and customer
- View order details
- Update order status
- View customer and shipping information

### 4. Offer Management
- View all customer resale offers
- Filter by status
- Approve offers (converts to inventory)
- Reject offers with comments
- View offer images and details

### 5. Reference Data Management
- Manage genres
- Manage publishers
- Manage book types
- Manage condition types
- Add, edit, delete reference data items

## System Features

### 1. File Management
- Upload and store images
- Serve images via local or CDN
- Delete unused images
- Image validation before upload
- Image resizing for consistent display

### 2. Configuration Management
- Environment-specific configuration
- Switch between local and AWS services
- Parameter Store integration for production

### 3. Logging
- Application error logging
- Structured logging with NLog
- CloudWatch Logs integration
- Request/response logging

### 4. Data Validation
- Server-side validation
- Client-side validation (jQuery Validation)
- Model state management
- User-friendly error messages
