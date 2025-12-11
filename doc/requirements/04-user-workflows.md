# User Workflows and Use Cases

## Customer Workflows

### 1. Browse and Purchase Book

**Actor**: Customer
**Precondition**: None (can be anonymous initially)

**Steps**:
1. Visit home page
2. Browse featured books or use search
3. Filter/sort results
4. Click book to view details
5. Click "Add to Cart"
6. Continue shopping or go to cart
7. Review cart items
8. Click "Checkout"
9. Login (if not authenticated)
10. Select shipping address (or create new)
11. Review order and click "Place Order"
12. View order confirmation

**Postcondition**: Order created, inventory reduced, customer can view in order history

### 2. Add Book to Wishlist

**Actor**: Authenticated Customer

**Steps**:
1. Browse or search for book
2. Click "Add to Wishlist"
3. View wishlist
4. Optionally move items to cart
5. Continue shopping

### 3. Create Resale Offer

**Actor**: Authenticated Customer

**Steps**:
1. Navigate to "Sell Books"
2. Fill in book details (title, author, ISBN, condition, etc.)
3. Upload book image
4. Set desired price
5. Submit offer
6. Receive confirmation
7. Wait for admin review
8. View offer status in "My Offers"

### 4. Manage Addresses

**Actor**: Authenticated Customer

**Steps**:
1. Go to "My Account" → "Addresses"
2. View existing addresses
3. Add new address (form)
4. Edit existing address
5. Delete old address
6. Use address during checkout

### 5. View Order History

**Actor**: Authenticated Customer

**Steps**:
1. Go to "My Orders"
2. View list of past orders
3. Click order to view details
4. See order items, status, delivery date
5. Track order status

## Admin Workflows

### 1. Add Book to Inventory

**Actor**: Admin

**Steps**:
1. Login to admin area
2. Navigate to "Inventory"
3. Click "Add Book"
4. Fill in book details
5. Select genre, publisher, book type, condition from dropdowns
6. Upload book cover image
7. Set price and quantity
8. Submit
9. Book appears in inventory and customer search

### 2. Process Customer Order

**Actor**: Admin

**Steps**:
1. Login to admin area
2. Navigate to "Orders"
3. View orders filtered by status
4. Click order to view details
5. Review order items and customer info
6. Update order status:
   - Pending → Processing (preparing order)
   - Processing → Shipped (order dispatched)
   - Shipped → Delivered (order received)
7. Customer sees updated status

### 3. Review Resale Offer

**Actor**: Admin

**Steps**:
1. Login to admin area
2. Navigate to "Offers"
3. Filter by "Pending Approval"
4. Click offer to view details
5. Review book information and image
6. Decision:
   - **Approve**: Offer accepted, can add to inventory
   - **Reject**: Provide reason/comment
7. Customer notified of decision

### 4. Manage Reference Data

**Actor**: Admin

**Steps**:
1. Login to admin area
2. Navigate to "Reference Data"
3. Select type (Genre, Publisher, BookType, Condition)
4. Add new item (e.g., new genre)
5. Edit existing item
6. Delete unused item
7. Reference data available in inventory forms

### 5. Monitor Dashboard

**Actor**: Admin

**Steps**:
1. Login to admin area
2. View dashboard
3. See statistics:
   - Total books in stock
   - Low stock items
   - Out of stock items
   - Recent orders
   - Pending offers
4. Click statistics to drill into details
5. Take action (restock, process orders, review offers)

## System Workflows

### 1. User Authentication (AWS Cognito)

**Flow**:
1. User clicks "Login"
2. Redirect to Cognito hosted UI
3. User enters credentials
4. Cognito validates
5. Return to application with authorization code
6. Exchange code for tokens
7. Validate tokens
8. Extract user claims
9. Create/update customer record
10. Set authentication cookie
11. Redirect to original page

### 2. Image Upload and Validation

**Flow**:
1. User selects image file
2. Client uploads via form
3. Server validates file size and type
4. Image validation service checks content (Rekognition)
5. If valid, resize image to standard dimensions
6. Save to storage (local or S3)
7. Return URL
8. Save URL in database
9. Display image in UI

### 3. Order Processing

**Flow**:
1. User clicks "Place Order" at checkout
2. Validate cart has items
3. Check stock availability
4. Create Order entity
5. For each cart item:
   - Create OrderItem
   - Reduce book quantity
6. Save order to database (transaction)
7. Clear shopping cart
8. Send order confirmation (future enhancement)
9. Display order confirmation page

## Use Case Matrix

| Use Case | Customer | Admin | Guest |
|----------|----------|-------|-------|
| Browse Books | ✓ | ✓ | ✓ |
| View Book Details | ✓ | ✓ | ✓ |
| Add to Cart | ✓ | ✗ | ✓ |
| Add to Wishlist | ✓ | ✗ | ✗ |
| Checkout | ✓ | ✗ | ✗ |
| View Orders | ✓ | ✓ | ✗ |
| Create Offer | ✓ | ✗ | ✗ |
| Manage Addresses | ✓ | ✗ | ✗ |
| Add Inventory | ✗ | ✓ | ✗ |
| Process Orders | ✗ | ✓ | ✗ |
| Review Offers | ✗ | ✓ | ✗ |
| Manage Reference Data | ✗ | ✓ | ✗ |
| View Dashboard | ✗ | ✓ | ✗ |
