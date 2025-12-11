# Dependency Injection

## Container: Autofac 8.2.1

The application uses Autofac as the IoC container with integrations for MVC and OWIN.

## Registration (DependencyInjectionSetup.cs)

### Services
```csharp
builder.RegisterType<BookService>().As<IBookService>();
builder.RegisterType<OrderService>().As<IOrderService>();
builder.RegisterType<CustomerService>().As<ICustomerService>();
builder.RegisterType<ShoppingCartService>().As<IShoppingCartService>();
builder.RegisterType<AddressService>().As<IAddressService>();
builder.RegisterType<OfferService>().As<IOfferService>();
builder.RegisterType<ReferenceDataService>().As<IReferenceDataService>();
builder.RegisterType<ImageResizeService>().As<IImageResizeService>();
```

### Repositories
```csharp
builder.RegisterType<BookRepository>().As<IBookRepository>();
builder.RegisterType<OrderRepository>().As<IOrderRepository>();
builder.RegisterType<CustomerRepository>().As<ICustomerRepository>();
builder.RegisterType<ShoppingCartRepository>().As<IShoppingCartRepository>();
builder.RegisterType<AddressRepository>().As<IAddressRepository>();
builder.RegisterType<OfferRepository>().As<IOfferRepository>();
builder.RegisterType<ReferenceDataRepository>().As<IReferenceDataRepository>();
```

### DbContext (InstancePerRequest)
```csharp
var connectionString = BookstoreConfiguration.GetConnectionString("BookstoreDatabaseConnection");
builder.RegisterType<ApplicationDbContext>()
    .WithParameter("connectionString", connectionString)
    .InstancePerRequest();
```

### Conditional Services

**File Service** (Local vs AWS):
```csharp
if (BookstoreConfiguration.GetSetting("Services/FileService") == "aws")
{
    builder.RegisterType<AmazonS3Client>().As<IAmazonS3>();
    builder.RegisterType<S3FileService>().As<IFileService>();
}
else
{
    builder.RegisterInstance(new LocalFileService(webRootPath)).As<IFileService>();
}
```

**Image Validation Service**:
```csharp
if (BookstoreConfiguration.GetSetting("Services/ImageValidationService") == "aws")
{
    builder.RegisterType<AmazonRekognitionClient>().As<IAmazonRekognition>();
    builder.RegisterType<RekognitionImageValidationService>().As<IImageValidationService>();
}
else
{
    builder.RegisterType<LocalImageValidationService>().As<IImageValidationService>();
}
```

### MVC Integration
```csharp
builder.RegisterControllers(typeof(MvcApplication).Assembly);
DependencyResolver.SetResolver(new AutofacDependencyResolver(container));
```

### OWIN Integration
```csharp
app.UseAutofacMiddleware(container);
```

## Lifetime Scopes

- **InstancePerRequest**: DbContext (one per HTTP request)
- **Transient**: Services and repositories (new instance per resolution)
- **Singleton**: File service instances
- **InstancePerLifetimeScope**: PaginatedList<T>

## Migration to ASP.NET Core

Built-in DI:
```csharp
services.AddScoped<IBookService, BookService>();
services.AddScoped<IBookRepository, BookRepository>();
services.AddDbContext<ApplicationDbContext>();
```

Or continue using Autofac with ASP.NET Core adapter.
