using Bookstore.Data;
using Bookstore.Data.FileServices;
using Bookstore.Data.ImageResizeService;
using Bookstore.Data.ImageValidationServices;
using Bookstore.Data.Repositories;
using Bookstore.Domain.Addresses;
using Bookstore.Domain.Books;
using Bookstore.Domain.Carts;
using Bookstore.Domain.Customers;
using Bookstore.Domain.Offers;
using Bookstore.Domain.Orders;
using Bookstore.Domain.ReferenceData;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using NLog.Web;
using System;

var builder = WebApplication.CreateBuilder(args);

// Configure NLog
builder.Logging.ClearProviders();
builder.Logging.SetMinimumLevel(Microsoft.Extensions.Logging.LogLevel.Trace);
builder.Host.UseNLog();

// Add services to the container
builder.Services.AddControllersWithViews();

// Configure Database Context for PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("BookstoreDatabaseConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

// Register repositories
builder.Services.AddScoped<IAddressRepository, AddressRepository>();
builder.Services.AddScoped<IBookRepository, BookRepository>();
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IOfferRepository, OfferRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IReferenceDataRepository, ReferenceDataRepository>();
builder.Services.AddScoped<IShoppingCartRepository, ShoppingCartRepository>();

// Register services
builder.Services.AddScoped<IAddressService, AddressService>();
builder.Services.AddScoped<IBookService, BookService>();
builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<IOfferService, OfferService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IReferenceDataService, ReferenceDataService>();
builder.Services.AddScoped<IShoppingCartService, ShoppingCartService>();

// Register image and file services based on configuration
var imageValidationService = builder.Configuration["Services:ImageValidationService"] ?? "local";
if (imageValidationService == "aws")
{
    builder.Services.AddScoped<Bookstore.Domain.IImageValidationService, RekognitionImageValidationService>();
}
else
{
    builder.Services.AddScoped<Bookstore.Domain.IImageValidationService, LocalImageValidationService>();
}

var fileService = builder.Configuration["Services:FileService"] ?? "local";
if (fileService == "aws")
{
    builder.Services.AddScoped<Bookstore.Domain.IFileService, S3FileService>();
}
else
{
    builder.Services.AddScoped<Bookstore.Domain.IFileService>(provider => 
        new LocalFileService(builder.Environment.WebRootPath));
}

builder.Services.AddScoped<Bookstore.Domain.IImageResizeService, Bookstore.Data.ImageResizeService.ImageResizeService>();

// Configure authentication
var authenticationService = builder.Configuration["Services:Authentication"] ?? "local";
if (authenticationService == "aws")
{
    // Configure OpenID Connect with AWS Cognito
    builder.Services
        .AddAuthentication(options =>
        {
            options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
        })
        .AddCookie()
        .AddOpenIdConnect(options =>
        {
            options.ClientId = builder.Configuration["Authentication:Cognito:ClientId"] ?? "";
            options.MetadataAddress = builder.Configuration["Authentication:Cognito:MetadataAddress"] ?? "";
            options.ResponseType = OpenIdConnectResponseType.Code;
            options.GetClaimsFromUserInfoEndpoint = true;
            options.SaveTokens = true;
            options.SignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
            options.Events = new OpenIdConnectEvents
            {
                OnRedirectToIdentityProviderForSignOut = context =>
                {
                    var cognitoDomain = builder.Configuration["Authentication:Cognito:CognitoDomain"];
                    var clientId = builder.Configuration["Authentication:Cognito:ClientId"];
                    var logoutUrl = $"{cognitoDomain}/logout?client_id={clientId}&logout_uri={context.Request.Scheme}://{context.Request.Host}/";
                    context.Response.Redirect(logoutUrl);
                    context.HandleResponse();
                    return System.Threading.Tasks.Task.CompletedTask;
                }
            };
        });
}
else
{
    // Use cookie authentication for local development
    builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
        .AddCookie(options =>
        {
            options.LoginPath = "/Authentication/Login";
            options.LogoutPath = "/Authentication/Logout";
        });
}

builder.Services.AddAuthorization();

var app = builder.Build();

// Seed database on startup
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
        logger.LogError(ex, "An error occurred while seeding the database.");
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

// Configure area routes
app.MapAreaControllerRoute(
    name: "admin",
    areaName: "Admin",
    pattern: "Admin/{controller=Dashboard}/{action=Index}/{id?}");

// Configure default route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
