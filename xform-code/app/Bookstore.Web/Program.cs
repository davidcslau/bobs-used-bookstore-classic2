using Amazon.Rekognition;
using Amazon.S3;
using BobsBookstoreClassic.Data;
using Bookstore.Data;
using Bookstore.Data.FileServices;
using Bookstore.Data.ImageResizeService;
using Bookstore.Data.ImageValidationServices;
using Bookstore.Data.Repositories;
using Bookstore.Domain;
using Bookstore.Domain.Addresses;
using Bookstore.Domain.Books;
using Bookstore.Domain.Carts;
using Bookstore.Domain.Customers;
using Bookstore.Domain.Offers;
using Bookstore.Domain.Orders;
using Bookstore.Domain.ReferenceData;
using Bookstore.Web.Helpers;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using NLog.Web;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

// Configure NLog
builder.Logging.ClearProviders();
builder.Host.UseNLog();

// Add services to the container
builder.Services.AddControllersWithViews();

// Initialize configuration
BookstoreConfiguration.Initialize(builder.Configuration);

// Configure Database
var connectionString = builder.Configuration.GetConnectionString("BookstoreDatabaseConnection") 
    ?? throw new InvalidOperationException("Connection string 'BookstoreDatabaseConnection' not found.");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

// Register Services
builder.Services.AddScoped<IBookService, BookService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IReferenceDataService, ReferenceDataService>();
builder.Services.AddScoped<IOfferService, OfferService>();
builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<IAddressService, AddressService>();
builder.Services.AddScoped<IShoppingCartService, ShoppingCartService>();
builder.Services.AddScoped<IImageResizeService, ImageResizeService>();

// Register Repositories
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IAddressRepository, AddressRepository>();
builder.Services.AddScoped<IBookRepository, BookRepository>();
builder.Services.AddScoped<IOfferRepository, OfferRepository>();
builder.Services.AddScoped<IShoppingCartRepository, ShoppingCartRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IReferenceDataRepository, ReferenceDataRepository>();

// Register generic PaginatedList
builder.Services.AddScoped(typeof(IPaginatedList<>), typeof(PaginatedList<>));

// Configure File Service
var fileServiceMode = builder.Configuration.GetValue<string>("AppSettings:Services/FileService") ?? "local";
if (fileServiceMode == "aws")
{
    builder.Services.AddDefaultAWSOptions(builder.Configuration.GetAWSOptions());
    builder.Services.AddAWSService<IAmazonS3>();
    builder.Services.AddScoped<IFileService, S3FileService>();
}
else
{
    var webRootPath = builder.Environment.WebRootPath ?? Path.Combine(builder.Environment.ContentRootPath, "wwwroot");
    builder.Services.AddSingleton<IFileService>(new LocalFileService(webRootPath));
}

// Configure Image Validation Service
var imageValidationMode = builder.Configuration.GetValue<string>("AppSettings:Services/ImageValidationService") ?? "local";
if (imageValidationMode == "aws")
{
    builder.Services.AddDefaultAWSOptions(builder.Configuration.GetAWSOptions());
    builder.Services.AddAWSService<IAmazonRekognition>();
    builder.Services.AddScoped<IImageValidationService, RekognitionImageValidationService>();
}
else
{
    builder.Services.AddScoped<IImageValidationService, LocalImageValidationService>();
}

// Configure Authentication
var authMode = builder.Configuration.GetValue<string>("AppSettings:Services/Authentication") ?? "local";
if (authMode == "aws")
{
    builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
    })
    .AddOpenIdConnect(options =>
    {
        options.ClientId = builder.Configuration["AppSettings:Authentication/Cognito/LocalClientId"] ?? "";
        options.MetadataAddress = builder.Configuration["AppSettings:Authentication/Cognito/MetadataAddress"] ?? "";
        options.ResponseType = OpenIdConnectResponseType.Code;
        options.GetClaimsFromUserInfoEndpoint = true;
        options.Scope.Add("openid");
        options.Scope.Add("profile");
        options.SaveTokens = true;
        options.UseTokenLifetime = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            NameClaimType = "cognito:username",
            RoleClaimType = "cognito:groups"
        };
        options.Events = new OpenIdConnectEvents
        {
            OnTokenValidated = async context =>
            {
                var customerService = context.HttpContext.RequestServices.GetRequiredService<ICustomerService>();
                var identity = (ClaimsIdentity?)context.Principal?.Identity;
                
                if (identity != null)
                {
                    var sub = identity.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                        ?? identity.FindFirst("sub")?.Value ?? "";
                    var name = identity.Name ?? "";
                    var givenName = identity.FindFirst(ClaimTypes.GivenName)?.Value 
                        ?? identity.FindFirst("given_name")?.Value ?? "";
                    var surname = identity.FindFirst(ClaimTypes.Surname)?.Value 
                        ?? identity.FindFirst("family_name")?.Value ?? "";

                    var dto = new CreateOrUpdateCustomerDto(sub, name, givenName, surname);
                    await customerService.CreateOrUpdateCustomerAsync(dto);
                }
            }
        };
    });
}
else
{
    // Local authentication setup
    builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
        .AddCookie(options =>
        {
            options.LoginPath = "/Account/Login";
            options.LogoutPath = "/Account/Logout";
        });
    
    builder.Services.AddScoped<LocalAuthenticationMiddleware>();
}

builder.Services.AddHttpContextAccessor();
builder.Services.AddSession();

var app = builder.Build();

// Seed database
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        await BookstoreDbInitializer.SeedAsync(context);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred seeding the DB.");
    }
}

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();
app.UseSession();

// Use local authentication middleware if configured
if (authMode == "local")
{
    app.UseMiddleware<LocalAuthenticationMiddleware>();
}

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
