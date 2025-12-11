# Business Rules and Validation

## Inventory Management

### Book Rules
- **Unique ISBN**: Not enforced (used books may share ISBNs)
- **Low Stock Threshold**: 5 units
- **Stock Reduction**: On order completion, reduce quantity
- **Negative Stock**: Prevented (minimum 0)
- **Price**: Must be > 0
- **Quantity**: Must be >= 0

### Reference Data Rules
- **Required Fields**: Publisher, BookType, Genre, Condition for each book
- **Cascading Deletes**: Disabled to prevent accidental book deletion
- **Unique Text**: Not enforced (allow duplicates)

## Order Processing

### Cart Rules
- **Out of Stock**: Can add to cart but flagged at checkout
- **Quantity Limits**: No hard limit
- **Session Association**: Cart tied to correlation ID (session or user)
- **Cart vs Wishlist**: Controlled by WantToBuy flag

### Checkout Rules
- **Address Required**: Must select shipping address
- **Empty Cart**: Cannot checkout with empty cart
- **Stock Validation**: Check availability before placing order
- **Tax Calculation**: 10% of subtotal
- **Delivery Date**: Automatic (current date + 7 days)

### Order Rules
- **Initial Status**: Pending
- **Status Progression**: Pending → Processing → Shipped → Delivered
- **Cancellation**: Allowed (status = Cancelled)
- **Order History**: Immutable after creation
- **Customer Association**: Required, no cascade delete

## Customer Management

### Authentication Rules
- **Subject ID (Sub)**: Must be unique
- **Auto-Creation**: Create customer on first login
- **Profile Update**: Update on each login
- **Required Fields**: Sub, Username, FirstName, LastName

### Address Rules
- **Multiple Addresses**: Allowed per customer
- **Active Flag**: Only active addresses shown for selection
- **Required Fields**: AddressLine1, City, State, Country, ZipCode
- **Deletion**: Soft delete (set IsActive = false)

## Resale Offers

### Offer Creation Rules
- **Customer Required**: Must be authenticated
- **Image Upload**: Optional
- **Price Validation**: Must be > 0
- **Initial Status**: PendingApproval
- **Content Moderation**: Image validation via Rekognition (if AWS mode)

### Offer Processing Rules
- **Admin Only**: Only admins can approve/reject
- **Status Change**: PendingApproval → Approved/Rejected
- **Approval**: Can convert to inventory (manual process)
- **Rejection**: Admin must provide comment
- **Immutable After Decision**: Cannot change approved/rejected offers

## Image Management

### Upload Rules
- **File Size**: Maximum 5MB
- **File Types**: JPEG, PNG, GIF
- **Dimensions**: Resized to standard dimensions (400x600)
- **Content Validation**: AWS Rekognition checks for inappropriate content
- **Unique Filenames**: Generated to prevent conflicts

### Deletion Rules
- **Orphan Cleanup**: Delete when book/offer deleted
- **No Cascade**: Manual cleanup required

## Validation Rules

### Client-Side (jQuery Validation)
- Required fields
- Email format
- Number ranges
- String length

### Server-Side (Model Validation)
- Model state validation
- Business rule enforcement
- Database constraint checking
- Transaction rollback on failure

## Concurrency Rules

### Optimistic Concurrency
- **RowVersion**: Timestamp field on all entities
- **Conflict Detection**: DbUpdateConcurrencyException
- **Resolution**: Last write wins (can be changed)
- **User Notification**: Alert on conflict

## Tax and Pricing

### Tax Calculation
- **Rate**: 10% of subtotal
- **Application**: Applied at checkout
- **Display**: Shown separately from subtotal

### Pricing Rules
- **Currency**: USD (implied)
- **Decimal Places**: 2
- **Discount**: Not implemented
- **Promotions**: Not implemented
