# Web Layer and API Documentation - Bob's Used Bookstore Classic

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Framework:** ASP.NET MVC 5.3.0  
**Target:** .NET Framework 4.8

---

## Table of Contents
1. [Overview](#overview)
2. [Controllers](#controllers)
3. [Routing](#routing)
4. [Authentication](#authentication)
5. [Areas (Admin)](#areas-admin)
6. [Views](#views)
7. [Helpers and Attributes](#helpers-and-attributes)

---

## Overview

The Web layer implements the presentation logic using ASP.NET MVC 5 pattern. It handles HTTP requests, user authentication, view rendering, and coordinates with the business layer through service interfaces.

**Key Features:**
- ASP.NET MVC 5 framework
- Razor view engine
- OWIN-based authentication
- Autofac dependency injection
- Areas for admin functionality
- Custom validation attributes
- Bootstrap-based UI

---

## Controllers

### Customer-Facing Controllers

#### 1. HomeController

**Location:** `Bookstore.Web/Controllers/HomeController.cs`

**Purpose:** Landing page and general information

**Routes:**
- `GET /` or `GET /Home/Index` - Home page with featured books

**Actions:**
```csharp
public async Task<ActionResult> Index()
{
    // Display featured books or promotions
    var vm = new HomeIndexViewModel
    {
        FeaturedBooks = await bookService.GetFeaturedBooksAsync()
    };
    return View(vm);
}
```

---

#### 2. SearchController

**Location:** `Bookstore.Web/Controllers/SearchController.cs`

**Purpose:** Book search and browsing

**Routes:**
- `GET /Search/Index` - Search books with filters
- `GET /Search/Details/{id}` - View book details

**Actions:**
```csharp
public async Task<ActionResult> Index(BookFilters filters, int page = 1)
{
    var results = await bookService.SearchBooksAsync(filters, page, PageSize);
    
    var vm = new SearchIndexViewModel
    {
        Books = results.Items,
        Filters = filters,
        PageIndex = page,
        TotalPages = results.TotalPages
    };
    
    return View(vm);
}

public async Task<ActionResult> Details(int id)
{
    var book = await bookService.GetBookAsync(id);
    
    var vm = new SearchDetailsViewModel
    {
        Book = book,
        RelatedBooks = await bookService.GetRelatedBooksAsync(book.GenreId)
    };
    
    return View(vm);
}
```

**Query Parameters:**
- `name` - Book title search
- `author` - Author name search
- `genreId` - Filter by genre
- `conditionId` - Filter by condition
- `bookTypeId` - Filter by book type
- `publisherId` - Filter by publisher
- `page` - Page number (default: 1)

---

#### 3. ShoppingCartController

**Location:** `Bookstore.Web/Controllers/ShoppingCartController.cs`

**Purpose:** Shopping cart management

**Routes:**
- `GET /ShoppingCart/Index` - View cart
- `POST /ShoppingCart/AddToCart` - Add book to cart
- `POST /ShoppingCart/RemoveItem` - Remove item from cart
- `POST /ShoppingCart/UpdateQuantity` - Update item quantity

**Actions:**
```csharp
[HttpPost]
public async Task<ActionResult> AddToCart(int bookId, int quantity = 1)
{
    var correlationId = GetOrCreateCorrelationId();
    await shoppingCartService.AddItemToCartAsync(correlationId, bookId, quantity);
    
    return RedirectToAction("Index");
}

public async Task<ActionResult> Index()
{
    var correlationId = GetOrCreateCorrelationId();
    var cart = await shoppingCartService.GetShoppingCartAsync(correlationId);
    
    var vm = new ShoppingCartIndexViewModel
    {
        Items = cart.Items,
        SubTotal = cart.SubTotal,
        Tax = cart.Tax,
        Total = cart.Total
    };
    
    return View(vm);
}
```

**Session Management:**
- Uses correlation ID stored in cookie
- Anonymous carts supported
- Carts persist across sessions

---

#### 4. WishlistController

**Location:** `Bookstore.Web/Controllers/WishlistController.cs`

**Purpose:** Wishlist management (books saved for later)

**Routes:**
- `GET /Wishlist/Index` - View wishlist
- `POST /Wishlist/AddToWishlist` - Add book to wishlist
- `POST /Wishlist/MoveToCart` - Move wishlist item to cart
- `POST /Wishlist/RemoveItem` - Remove from wishlist

**Actions:**
```csharp
[HttpPost]
public async Task<ActionResult> AddToWishlist(int bookId)
{
    var correlationId = GetOrCreateCorrelationId();
    await shoppingCartService.AddItemToWishlistAsync(correlationId, bookId);
    
    return RedirectToAction("Index", "Search");
}

[HttpPost]
public async Task<ActionResult> MoveToCart(int itemId)
{
    var correlationId = GetOrCreateCorrelationId();
    await shoppingCartService.MoveWishlistItemToCartAsync(correlationId, itemId);
    
    return RedirectToAction("Index", "ShoppingCart");
}
```

---

#### 5. CheckoutController

**Location:** `Bookstore.Web/Controllers/CheckoutController.cs`

**Purpose:** Order checkout process

**Routes:**
- `GET /Checkout/Index` - Checkout page (select address)
- `POST /Checkout/PlaceOrder` - Complete order
- `GET /Checkout/Finished/{orderId}` - Order confirmation

**Actions:**
```csharp
[Authorize]
public async Task<ActionResult> Index()
{
    var customer = await GetCurrentCustomerAsync();
    var correlationId = GetOrCreateCorrelationId();
    var cart = await shoppingCartService.GetShoppingCartAsync(correlationId);
    var addresses = await addressService.ListAddressesByCustomerAsync(customer.Id);
    
    var vm = new CheckoutIndexViewModel
    {
        CartItems = cart.Items,
        SubTotal = cart.SubTotal,
        Tax = cart.Tax,
        Total = cart.Total,
        Addresses = addresses
    };
    
    return View(vm);
}

[HttpPost]
[Authorize]
public async Task<ActionResult> PlaceOrder(int addressId)
{
    var customer = await GetCurrentCustomerAsync();
    var correlationId = GetOrCreateCorrelationId();
    
    var order = await orderService.CreateOrderFromCartAsync(
        customer.Id, addressId, correlationId);
    
    return RedirectToAction("Finished", new { orderId = order.Id });
}
```

**Authorization:**
- Requires authenticated user
- Validates address belongs to customer
- Validates cart has items

---

#### 6. OrdersController

**Location:** `Bookstore.Web/Controllers/OrdersController.cs`

**Purpose:** Order history and tracking

**Routes:**
- `GET /Orders/Index` - List customer's orders
- `GET /Orders/Details/{id}` - View order details

**Actions:**
```csharp
[Authorize]
public async Task<ActionResult> Index(int page = 1)
{
    var customer = await GetCurrentCustomerAsync();
    var filters = new OrderFilters { CustomerId = customer.Id };
    var orders = await orderService.ListOrdersAsync(filters, page, PageSize);
    
    var vm = new OrderIndexViewModel
    {
        Orders = orders.Items,
        PageIndex = page,
        TotalPages = orders.TotalPages
    };
    
    return View(vm);
}

[Authorize]
public async Task<ActionResult> Details(int id)
{
    var customer = await GetCurrentCustomerAsync();
    var order = await orderService.GetOrderAsync(id);
    
    // Verify order belongs to customer
    if (order.CustomerId != customer.Id)
        return HttpNotFound();
    
    var vm = new OrderDetailsViewModel { Order = order };
    return View(vm);
}
```

---

#### 7. ResaleController

**Location:** `Bookstore.Web/Controllers/ResaleController.cs`

**Purpose:** Customer book resale offers

**Routes:**
- `GET /Resale/Index` - List customer's offers
- `GET /Resale/Create` - Create new offer form
- `POST /Resale/Create` - Submit new offer

**Actions:**
```csharp
[Authorize]
public async Task<ActionResult> Index(int page = 1)
{
    var customer = await GetCurrentCustomerAsync();
    var filters = new OfferFilters { CustomerId = customer.Id };
    var offers = await offerService.ListOffersAsync(filters, page, PageSize);
    
    var vm = new ResaleIndexViewModel
    {
        Offers = offers.Items,
        PageIndex = page,
        TotalPages = offers.TotalPages
    };
    
    return View(vm);
}

[Authorize]
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<ActionResult> Create(ResaleCreateViewModel vm)
{
    if (!ModelState.IsValid)
        return View(vm);
    
    var customer = await GetCurrentCustomerAsync();
    
    // Handle image upload
    string imageUrl = null;
    if (vm.CoverImage != null)
    {
        var resizedImage = imageResizeService.ResizeImage(
            vm.CoverImage.InputStream, 300, 450);
        imageUrl = await fileService.UploadFileAsync(
            $"offer-{Guid.NewGuid()}.jpg", resizedImage);
    }
    
    var dto = new CreateOfferDto
    {
        CustomerId = customer.Id,
        BookName = vm.BookName,
        Author = vm.Author,
        ISBN = vm.ISBN,
        BookTypeId = vm.BookTypeId,
        GenreId = vm.GenreId,
        ConditionId = vm.ConditionId,
        PublisherId = vm.PublisherId,
        BookPrice = vm.BookPrice,
        FrontUrl = imageUrl
    };
    
    await offerService.CreateOfferAsync(dto);
    
    return RedirectToAction("Index");
}
```

**Validation:**
- Image file type (jpg, jpeg, png)
- Image file size (max 5MB)
- Required fields
- Price validation

---

#### 8. AddressController

**Location:** `Bookstore.Web/Controllers/AddressController.cs`

**Purpose:** Shipping address management

**Routes:**
- `GET /Address/Index` - List addresses
- `GET /Address/Create` - Create address form
- `POST /Address/Create` - Save new address
- `GET /Address/Edit/{id}` - Edit address form
- `POST /Address/Edit/{id}` - Update address
- `POST /Address/Delete/{id}` - Delete address

**Actions:**
```csharp
[Authorize]
public async Task<ActionResult> Index()
{
    var customer = await GetCurrentCustomerAsync();
    var addresses = await addressService.ListAddressesByCustomerAsync(customer.Id);
    
    var vm = new AddressIndexViewModel { Addresses = addresses };
    return View(vm);
}

[Authorize]
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<ActionResult> Create(AddressCreateUpdateViewModel vm)
{
    if (!ModelState.IsValid)
        return View(vm);
    
    var customer = await GetCurrentCustomerAsync();
    
    var dto = new CreateOrUpdateAddressDto
    {
        CustomerId = customer.Id,
        AddressLine1 = vm.AddressLine1,
        AddressLine2 = vm.AddressLine2,
        City = vm.City,
        State = vm.State,
        Country = vm.Country,
        ZipCode = vm.ZipCode
    };
    
    await addressService.CreateAddressAsync(dto);
    
    return RedirectToAction("Index");
}
```

---

#### 9. AuthenticationController

**Location:** `Bookstore.Web/Controllers/AuthenticationController.cs`

**Purpose:** Login/logout handling

**Routes:**
- `GET /Authentication/Login` - Initiate login
- `GET /Authentication/Logout` - Logout
- `GET /Authentication/LoginCallback` - OAuth callback (AWS mode)

**Actions:**
```csharp
public ActionResult Login(string returnUrl = "/")
{
    if (User.Identity.IsAuthenticated)
        return Redirect(returnUrl);
    
    // In AWS mode, this triggers OIDC authentication
    // In local mode, LocalAuthenticationMiddleware handles it
    HttpContext.GetOwinContext().Authentication.Challenge();
    return new HttpUnauthorizedResult();
}

public ActionResult Logout()
{
    HttpContext.GetOwinContext().Authentication.SignOut();
    return RedirectToAction("Index", "Home");
}
```

---

### Admin Controllers (Area: Admin)

#### 1. DashboardController

**Location:** `Bookstore.Web/Areas/Admin/Controllers/DashboardController.cs`

**Purpose:** Admin dashboard with statistics

**Routes:**
- `GET /Admin/Dashboard/Index` - Dashboard home

**Actions:**
```csharp
[Authorize]
public async Task<ActionResult> Index()
{
    var vm = new DashboardIndexViewModel
    {
        BookStatistics = await bookService.GetBookStatisticsAsync(),
        OrderStatistics = await orderService.GetOrderStatisticsAsync(),
        OfferStatistics = await offerService.GetOfferStatisticsAsync()
    };
    
    return View(vm);
}
```

**Statistics Displayed:**
- Total books in inventory
- Low stock items count
- Total orders (today, week, month)
- Pending offers count
- Revenue statistics

---

#### 2. InventoryController

**Location:** `Bookstore.Web/Areas/Admin/Controllers/InventoryController.cs`

**Purpose:** Book inventory management

**Routes:**
- `GET /Admin/Inventory/Index` - List all books
- `GET /Admin/Inventory/Create` - Add book form
- `POST /Admin/Inventory/Create` - Save new book
- `GET /Admin/Inventory/Edit/{id}` - Edit book form
- `POST /Admin/Inventory/Edit/{id}` - Update book
- `GET /Admin/Inventory/Details/{id}` - View book details
- `POST /Admin/Inventory/Delete/{id}` - Delete book

**Key Features:**
- Full CRUD operations
- Image upload for book covers
- Stock level management
- Low stock indicators
- Filtering and search

---

#### 3. OrdersController (Admin)

**Location:** `Bookstore.Web/Areas/Admin/Controllers/OrdersController.cs`

**Purpose:** Order management and fulfillment

**Routes:**
- `GET /Admin/Orders/Index` - List all orders
- `GET /Admin/Orders/Details/{id}` - View order details
- `POST /Admin/Orders/UpdateStatus` - Update order status

**Actions:**
```csharp
[Authorize]
public async Task<ActionResult> Index(OrderFilters filters, int page = 1)
{
    var orders = await orderService.ListOrdersAsync(filters, page, PageSize);
    
    var vm = new OrderIndexViewModel
    {
        Orders = orders.Items,
        Filters = filters,
        PageIndex = page,
        TotalPages = orders.TotalPages
    };
    
    return View(vm);
}

[Authorize]
[HttpPost]
public async Task<ActionResult> UpdateStatus(int orderId, OrderStatus status)
{
    await orderService.UpdateOrderStatusAsync(orderId, status);
    return RedirectToAction("Details", new { id = orderId });
}
```

**Filters:**
- Order status
- Date range
- Customer search
- Order ID search

---

#### 4. OffersController (Admin)

**Location:** `Bookstore.Web/Areas/Admin/Controllers/OffersController.cs`

**Purpose:** Review and manage customer resale offers

**Routes:**
- `GET /Admin/Offers/Index` - List all offers
- `GET /Admin/Offers/Details/{id}` - View offer details
- `POST /Admin/Offers/Approve` - Approve offer
- `POST /Admin/Offers/Reject` - Reject offer

**Actions:**
```csharp
[Authorize]
[HttpPost]
public async Task<ActionResult> Approve(int id, string comment)
{
    await offerService.UpdateOfferStatusAsync(id, OfferStatus.Approved, comment);
    return RedirectToAction("Index");
}

[Authorize]
[HttpPost]
public async Task<ActionResult> Reject(int id, string comment)
{
    await offerService.UpdateOfferStatusAsync(id, OfferStatus.Rejected, comment);
    return RedirectToAction("Index");
}
```

---

#### 5. ReferenceDataController

**Location:** `Bookstore.Web/Areas/Admin/Controllers/ReferenceDataController.cs`

**Purpose:** Manage reference data (genres, publishers, etc.)

**Routes:**
- `GET /Admin/ReferenceData/Index` - List all reference data
- `POST /Admin/ReferenceData/Create` - Add reference data item
- `POST /Admin/ReferenceData/Delete/{id}` - Delete item

**Actions:**
```csharp
[Authorize]
[HttpPost]
public async Task<ActionResult> Create(ReferenceDataType type, string text)
{
    await referenceDataService.CreateReferenceDataItemAsync(type, text);
    return RedirectToAction("Index");
}
```

---

## Routing

### Default Route Configuration

**Location:** `Bookstore.Web/App_Start/RouteConfig.cs`

```csharp
public static void RegisterRoutes(RouteCollection routes)
{
    routes.IgnoreRoute("{resource}.axd/{*pathInfo}");
    
    routes.MapRoute(
        name: "Default",
        url: "{controller}/{action}/{id}",
        defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional },
        namespaces: new string[] { "Bookstore.Web.Controllers" }
    );
}
```

### Admin Area Route

**Location:** `Bookstore.Web/Areas/Admin/AdminAreaRegistration.cs`

```csharp
public class AdminAreaRegistration : AreaRegistration
{
    public override string AreaName => "Admin";
    
    public override void RegisterArea(AreaRegistrationContext context)
    {
        context.MapRoute(
            "Admin_default",
            "Admin/{controller}/{action}/{id}",
            new { controller = "Dashboard", action = "Index", id = UrlParameter.Optional },
            new string[] { "Bookstore.Web.Areas.Admin.Controllers" }
        );
    }
}
```

### URL Examples

**Customer Area:**
- `/` - Home page
- `/Search` - Book search
- `/Search/Details/5` - Book details (ID: 5)
- `/ShoppingCart` - Shopping cart
- `/Checkout` - Checkout
- `/Orders` - Order history
- `/Orders/Details/10` - Order details (ID: 10)
- `/Resale` - Resale offers
- `/Address` - Address management

**Admin Area:**
- `/Admin` - Admin dashboard
- `/Admin/Inventory` - Inventory management
- `/Admin/Orders` - Order management
- `/Admin/Offers` - Offer management
- `/Admin/ReferenceData` - Reference data management

---

## Authentication

### OWIN Authentication Pipeline

**Configuration:** `Bookstore.Web/App_Start/AuthenticationSetup.cs`

### Local Mode (Development)

**Middleware:** `LocalAuthenticationMiddleware`

```csharp
public class LocalAuthenticationMiddleware : OwinMiddleware
{
    public override async Task Invoke(IOwinContext context)
    {
        var request = context.Request;
        
        // Check for login request
        if (request.Path.Value.Contains("/Authentication/Login"))
        {
            // Create claims identity
            var identity = new ClaimsIdentity("Local");
            identity.AddClaim(new Claim(ClaimTypes.Name, "Admin"));
            identity.AddClaim(new Claim("sub", "local-admin"));
            
            context.Authentication.SignIn(identity);
            context.Response.Redirect("/");
            return;
        }
        
        await Next.Invoke(context);
    }
}
```

### AWS Cognito Mode (Production)

**Protocol:** OpenID Connect (OIDC)

```csharp
app.UseOpenIdConnectAuthentication(new OpenIdConnectAuthenticationOptions
{
    ClientId = GetSetting("Authentication/Cognito/LocalClientId"),
    MetadataAddress = GetSetting("Authentication/Cognito/MetadataAddress"),
    ResponseType = OpenIdConnectResponseType.Code,
    Scope = "openid profile",
    TokenValidationParameters = new TokenValidationParameters
    {
        NameClaimType = "cognito:username",
        RoleClaimType = "cognito:groups"
    },
    Notifications = new OpenIdConnectAuthenticationNotifications
    {
        SecurityTokenValidated = async context =>
        {
            // Create or update customer record
            var identity = (ClaimsIdentity)context.AuthenticationTicket.Identity;
            var customerService = ResolveService<ICustomerService>();
            await customerService.CreateOrUpdateCustomerAsync(new CreateOrUpdateCustomerDto
            {
                Sub = identity.GetSub(),
                Username = identity.Name,
                FirstName = identity.FindFirst("given_name").Value,
                LastName = identity.FindFirst("family_name").Value
            });
        }
    }
});
```

### Authorization

**Attribute-Based:**
```csharp
[Authorize] // Requires authenticated user
public class CheckoutController : Controller
{
    // All actions require authentication
}

[Authorize]
public ActionResult AdminAction()
{
    // Single action requires authentication
}
```

**Claims-Based:**
```csharp
var sub = User.Identity.GetSub();
var customer = await customerService.GetCustomerBySubAsync(sub);
```

---

## Areas (Admin)

### Area Structure

```
Areas/Admin/
├── Controllers/              # Admin controllers
├── Models/                   # Admin view models
└── Views/                    # Admin views
    ├── Dashboard/
    ├── Inventory/
    ├── Orders/
    ├── Offers/
    ├── ReferenceData/
    └── Shared/              # Admin layout and partials
```

### Admin Layout

**Location:** `Bookstore.Web/Areas/Admin/Views/Shared/_Layout.cshtml`

- Different navigation from customer area
- Admin-specific styling
- Dashboard sidebar
- User info display

---

## Views

### Customer Views

**View Engine:** Razor (.cshtml)

**Key Views:**
- `Views/Home/Index.cshtml` - Home page
- `Views/Search/Index.cshtml` - Book search results
- `Views/Search/Details.cshtml` - Book details
- `Views/ShoppingCart/Index.cshtml` - Shopping cart
- `Views/Checkout/Index.cshtml` - Checkout page
- `Views/Orders/Index.cshtml` - Order history
- `Views/Orders/Details.cshtml` - Order details
- `Views/Resale/Create.cshtml` - Submit offer
- `Views/Address/Index.cshtml` - Address list

### Shared Views

**Location:** `Views/Shared/`

- `_Layout.cshtml` - Main layout template
- `_LoginPartial.cshtml` - Login/logout links
- `_ValidationScriptsPartial.cshtml` - Client-side validation
- `Error.cshtml` - Error page

### Layout Structure

```html
<!DOCTYPE html>
<html>
<head>
    <title>@ViewBag.Title - Bob's Used Books</title>
    @Styles.Render("~/Content/css")
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <!-- Navigation -->
        @Html.Partial("_LoginPartial")
    </nav>
    
    <div class="container">
        @RenderBody()
    </div>
    
    <footer>
        <!-- Footer content -->
    </footer>
    
    @Scripts.Render("~/bundles/jquery")
    @Scripts.Render("~/bundles/bootstrap")
    @RenderSection("scripts", required: false)
</body>
</html>
```

---

## Helpers and Attributes

### Custom Validation Attributes

#### MaxFileSizeAttribute

**Location:** `Bookstore.Web/Helpers/MaxFileSizeAttribute.cs`

```csharp
public class MaxFileSizeAttribute : ValidationAttribute
{
    private readonly int maxFileSize;
    
    public MaxFileSizeAttribute(int maxFileSize)
    {
        this.maxFileSize = maxFileSize;
    }
    
    protected override ValidationResult IsValid(object value, ValidationContext validationContext)
    {
        var file = value as HttpPostedFileBase;
        if (file != null && file.ContentLength > maxFileSize)
        {
            return new ValidationResult($"File size must not exceed {maxFileSize / 1024 / 1024}MB");
        }
        return ValidationResult.Success;
    }
}
```

**Usage:**
```csharp
[MaxFileSize(5 * 1024 * 1024)] // 5MB
public HttpPostedFileBase CoverImage { get; set; }
```

#### ImageTypesAttribute

**Location:** `Bookstore.Web/Helpers/ImageTypesAttribute.cs`

```csharp
public class ImageTypesAttribute : ValidationAttribute
{
    protected override ValidationResult IsValid(object value, ValidationContext validationContext)
    {
        var file = value as HttpPostedFileBase;
        if (file != null)
        {
            var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png" };
            if (!allowedTypes.Contains(file.ContentType.ToLower()))
            {
                return new ValidationResult("Only JPG and PNG images are allowed");
            }
        }
        return ValidationResult.Success;
    }
}
```

**Usage:**
```csharp
[ImageTypes]
public HttpPostedFileBase CoverImage { get; set; }
```

### Extension Methods

#### HttpContextExtensions

```csharp
public static class HttpContextExtensions
{
    public static string GetOrCreateCorrelationId(this HttpContext context)
    {
        var correlationId = context.Request.Cookies["CorrelationId"]?.Value;
        if (string.IsNullOrEmpty(correlationId))
        {
            correlationId = Guid.NewGuid().ToString();
            context.Response.Cookies.Add(new HttpCookie("CorrelationId", correlationId)
            {
                Expires = DateTime.Now.AddYears(1)
            });
        }
        return correlationId;
    }
}
```

#### ClaimsIdentityExtensions

```csharp
public static class ClaimsIdentityExtensions
{
    public static string GetSub(this ClaimsIdentity identity)
    {
        return identity.FindFirst("sub")?.Value;
    }
}
```

### Bundling and Minification

**Configuration:** `Bookstore.Web/App_Start/BundleConfig.cs`

```csharp
public static void RegisterBundles(BundleCollection bundles)
{
    bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
        "~/Scripts/jquery-{version}.js"));
    
    bundles.Add(new ScriptBundle("~/bundles/bootstrap").Include(
        "~/Scripts/bootstrap.js"));
    
    bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include(
        "~/Scripts/jquery.validate*"));
    
    bundles.Add(new StyleBundle("~/Content/css").Include(
        "~/Content/bootstrap.css",
        "~/Content/site.css"));
}
```

---

**Next:** 05-database-schema-documentation.md
