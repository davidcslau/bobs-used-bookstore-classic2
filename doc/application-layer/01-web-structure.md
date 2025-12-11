# Web Application Structure

## Overview

The web application follows ASP.NET MVC 5 architecture with Areas for admin functionality, following convention-over-configuration principles.

## Project Structure

```
Bookstore.Web/
├── App_Start/               # Application startup configuration
├── Areas/                   # Admin area for management functions
│   └── Admin/
│       ├── Controllers/
│       ├── Models/
│       └── Views/
├── Controllers/             # Customer-facing controllers
├── Models/                  # View models and DTOs
├── Views/                   # Razor templates
│   ├── Shared/             # Shared layouts and partials
│   └── [Controller]/       # Controller-specific views
├── Content/                 # CSS, images, static files
├── Scripts/                 # JavaScript files
├── Helpers/                 # Utility classes
├── Global.asax.cs          # Application lifecycle
├── Startup.cs              # OWIN startup
└── Web.config              # Configuration

## Controllers

### Customer-Facing Controllers

**HomeController**: Landing page and navigation
- `Index()`: Home page with featured books
- `Privacy()`: Privacy policy page
- `Error()`: Error handling

**SearchController**: Book search functionality
- `Index(query, filters)`: Search books with filters
- `Details(id)`: Book details page

**ShoppingCartController**: Cart management
- `Index()`: View cart
- `AddItem(bookId, quantity)`: Add to cart
- `RemoveItem(itemId)`: Remove from cart
- `UpdateQuantity(itemId, quantity)`: Update item quantity

**WishlistController**: Wishlist management
- `Index()`: View wishlist
- `AddItem(bookId)`: Add to wishlist
- `MoveToCart(itemId)`: Move item to cart
- `RemoveItem(itemId)`: Remove from wishlist

**CheckoutController**: Order processing
- `Index()`: Checkout page with address selection
- `FinishCheckout(addressId)`: Complete purchase

**OrdersController**: Order history
- `Index(page)`: List customer orders
- `Details(id)`: Order details

**ResaleController**: Book resale offers
- `Index(page)`: List customer offers
- `Create()`: Create new offer form
- `Create(model)`: Submit offer
- `Details(id)`: Offer details

**AddressController**: Address management
- `Index()`: List addresses
- `Create()`: Add new address
- `Edit(id)`: Edit address
- `Delete(id)`: Delete address

**AuthenticationController**: Login/logout
- `Login()`: Initiate login
- `Logout()`: Sign out
- `AccessDenied()`: Unauthorized access page

### Admin Area Controllers

**Admin/DashboardController**: Admin home
- `Index()`: Dashboard with statistics

**Admin/InventoryController**: Book inventory management
- `Index(filters, page)`: List books
- `Create()`: Add new book
- `Edit(id)`: Update book
- `Details(id)`: Book details
- `Delete(id)`: Remove book

**Admin/OrdersController**: Order management
- `Index(filters, page)`: List all orders
- `Details(id)`: Order details
- `UpdateStatus(id, status)`: Change order status

**Admin/OffersController**: Manage resale offers
- `Index(filters, page)`: List offers
- `Details(id)`: Offer details
- `Approve(id)`: Approve offer
- `Reject(id, comment)`: Reject offer

**Admin/ReferenceDataController**: Manage lookup data
- `Index()`: List all reference data
- `Create(type)`: Add new item
- `Edit(id)`: Update item
- `Delete(id)`: Remove item

**Admin/ErrorController**: Admin error handling
- `Index()`: Admin-specific error page

## View Models

### Pattern
View models are organized by controller/feature area:
```
Models/
├── Home/
│   └── HomeIndexViewModel.cs
├── Search/
│   ├── SearchIndexViewModel.cs
│   └── SearchDetailsViewModel.cs
├── ShoppingCart/
│   └── ShoppingCartIndexViewModel.cs
├── Checkout/
│   ├── CheckoutIndexViewModel.cs
│   └── CheckoutFinishedViewModel.cs
└── PaginatedViewModel.cs
```

### Key View Models

**PaginatedViewModel<T>**: Base class for paginated lists
- Items: List<T>
- PageIndex, PageSize, TotalPages
- HasNextPage, HasPreviousPage

**HomeIndexViewModel**: Featured books on home page
- FeaturedBooks: List<BookDto>

**SearchIndexViewModel**: Search results
- Books: PaginatedViewModel<BookDto>
- Filters: SearchFilters
- Genres, Publishers, Conditions: Reference data lists

**ShoppingCartIndexViewModel**: Cart display
- Items: List<ShoppingCartItemDto>
- SubTotal, Tax, Total: decimal

**CheckoutIndexViewModel**: Checkout form
- Addresses: List<AddressDto>
- CartItems: List<ShoppingCartItemDto>
- Total: decimal

## Routing Configuration

### Default Route
```csharp
routes.MapRoute(
    name: "Default",
    url: "{controller}/{action}/{id}",
    defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional }
);
```

### Area Registration
```csharp
context.MapRoute(
    "Admin_default",
    "Admin/{controller}/{action}/{id}",
    new { action = "Index", id = UrlParameter.Optional }
);
```

## Authorization

### Controller Level
```csharp
[Authorize] // Requires authentication
public class OrdersController : Controller { }

[AllowAnonymous] // No authentication required
public class HomeController : Controller { }
```

### Admin Area
```csharp
[Authorize] // All admin controllers require authentication
public class AdminAreaControllerBase : Controller { }
```

## View Structure

### Layouts
- `_Layout.cshtml`: Main customer layout
- `_AdminLayout.cshtml`: Admin area layout
- `_LoginPartial.cshtml`: Login/logout partial

### Shared Views
- `Error.cshtml`: Generic error page
- `_ValidationScriptsPartial.cshtml`: Client-side validation

### View Conventions
- Views stored in `/Views/{ControllerName}/`
- Shared views in `/Views/Shared/`
- Area views in `/Areas/{AreaName}/Views/{ControllerName}/`

## Bundling and Minification

### Script Bundles
```csharp
bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
    "~/Scripts/jquery-{version}.js"));

bundles.Add(new ScriptBundle("~/bundles/bootstrap").Include(
    "~/Scripts/bootstrap.js"));

bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include(
    "~/Scripts/jquery.validate*"));
```

### Style Bundles
```csharp
bundles.Add(new StyleBundle("~/Content/css").Include(
    "~/Content/bootstrap.css",
    "~/Content/site.css"));
```

## Filters

### Global Filters
```csharp
filters.Add(new HandleErrorAttribute()); // Global error handling
filters.Add(new AuthorizeAttribute()); // Require authentication by default
```

### Custom Filters
- Error logging filter
- Performance monitoring filter (potential)

## Helpers

### Custom HTML Helpers
Located in `/Helpers/` directory for reusable view logic.

### Extension Methods
- ClaimsExtensions: Extract claims from identity
- UrlExtensions: URL generation helpers

## Migration to ASP.NET Core

### Changes Required
1. **Controllers**: Similar structure but different base class
2. **View Models**: Can remain similar
3. **Routing**: Use endpoint routing
4. **Areas**: Similar concept, different registration
5. **Filters**: Attribute-based similar, implementation different
6. **Bundling**: Use LibMan, npm, or webpack
7. **Helpers**: Tag helpers instead of HTML helpers

## Summary

The web structure follows standard ASP.NET MVC patterns with:
- Separate controllers for customer and admin functionality
- Area-based organization for admin features
- View models for data transfer to views
- Convention-based routing
- Authorization at controller level
- Bundling for performance
