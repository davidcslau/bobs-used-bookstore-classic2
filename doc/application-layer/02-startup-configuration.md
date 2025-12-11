# Application Startup and Configuration

## Overview

The application uses two startup mechanisms: Global.asax for ASP.NET MVC initialization and OWIN Startup class for middleware configuration.

## Global.asax.cs

**Purpose**: ASP.NET application lifecycle events and MVC initialization

```csharp
public class MvcApplication : HttpApplication
{
    protected void Application_Start()
    {
        AreaRegistration.RegisterAllAreas();
        FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
        RouteConfig.RegisterRoutes(RouteTable.Routes);
        BundleConfig.RegisterBundles(BundleTable.Bundles);
    }

    protected void Application_Error()
    {
        var ex = Server.GetLastError();
        var logger = LogManager.GetCurrentClassLogger();
        logger.Error(ex);
    }
}
```

### Application_Start Events

1. **AreaRegistration.RegisterAllAreas()**: Registers MVC Areas (Admin area)
2. **FilterConfig.RegisterGlobalFilters()**: Registers global action filters
3. **RouteConfig.RegisterRoutes()**: Configures URL routing
4. **BundleConfig.RegisterBundles()**: Sets up script and CSS bundles

### Application_Error

- Captures unhandled exceptions
- Logs using NLog
- Provides fallback error handling

## OWIN Startup.cs

**Purpose**: OWIN middleware pipeline configuration

```csharp
[assembly: OwinStartup(typeof(Bookstore.Web.Startup))]

public class Startup
{
    public void Configuration(IAppBuilder app)
    {
        LoggingSetup.ConfigureLogging();
        ConfigurationSetup.ConfigureConfiguration();
        DependencyInjectionSetup.ConfigureDependencyInjection(app);
        AuthenticationConfig.ConfigureAuthentication(app);
    }
}
```

### Startup Sequence

1. **LoggingSetup**: Configure NLog with CloudWatch targets
2. **ConfigurationSetup**: Load configuration from Parameter Store (AWS)
3. **DependencyInjectionSetup**: Configure Autofac container
4. **AuthenticationConfig**: Setup OWIN authentication (Cognito or local)

## Configuration Files

### LoggingSetup.cs

```csharp
public static void ConfigureLogging()
{
    var config = new LoggingConfiguration();
    
    if (BookstoreConfiguration.GetSetting("Services/LoggingService") == "aws")
    {
        // CloudWatch Logs configuration
        var awsTarget = new AWSTarget()
        {
            LogGroup = "/aws/bookstore/classic",
            Region = "us-east-1"
        };
        config.AddTarget("aws", awsTarget);
        config.AddRule(LogLevel.Info, LogLevel.Fatal, awsTarget);
    }
    else
    {
        // File logging configuration
        var fileTarget = new FileTarget("logfile")
        {
            FileName = "${basedir}/logs/app.log",
            Layout = "${longdate}|${level:uppercase=true}|${logger}|${message}|${exception}"
        };
        config.AddTarget(fileTarget);
        config.AddRule(LogLevel.Debug, LogLevel.Fatal, fileTarget);
    }
    
    LogManager.Configuration = config;
}
```

### ConfigurationSetup.cs

```csharp
public static void ConfigureConfiguration()
{
    // Load configuration from AWS Parameter Store if in AWS mode
    if (BookstoreConfiguration.GetSetting("Services/Database") == "aws")
    {
        BookstoreConfiguration.LoadFromParameterStore();
    }
    // Otherwise use Web.config
}
```

### FilterConfig.cs

```csharp
public static void RegisterGlobalFilters(GlobalFilterCollection filters)
{
    filters.Add(new HandleErrorAttribute());
}
```

### RouteConfig.cs

```csharp
public static void RegisterRoutes(RouteCollection routes)
{
    routes.IgnoreRoute("{resource}.axd/{*pathInfo}");

    routes.MapRoute(
        name: "Default",
        url: "{controller}/{action}/{id}",
        defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional }
    );
}
```

### BundleConfig.cs

```csharp
public static void RegisterBundles(BundleCollection bundles)
{
    bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
        "~/Scripts/jquery-{version}.js"));

    bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include(
        "~/Scripts/jquery.validate*"));

    bundles.Add(new ScriptBundle("~/bundles/modernizr").Include(
        "~/Scripts/modernizr-*"));

    bundles.Add(new StyleBundle("~/Content/css").Include(
        "~/Content/bootstrap.css",
        "~/Content/site.css"));

    BundleTable.EnableOptimizations = true; // Production
}
```

## Startup Order

```
1. IIS/IIS Express starts application
   ↓
2. Global.asax Application_Start()
   ├─ Area Registration
   ├─ Filter Configuration
   ├─ Route Configuration
   └─ Bundle Configuration
   ↓
3. OWIN Startup Configuration()
   ├─ Logging Setup
   ├─ Configuration Loading
   ├─ Dependency Injection
   └─ Authentication Middleware
   ↓
4. Application ready to handle requests
```

## Configuration Sources

### Development
- Web.config: Connection strings and app settings
- Local file system: For file storage
- LocalDB: For database

### Production (AWS)
- Web.config: Base configuration
- AWS Parameter Store: Sensitive configuration
  - Connection strings
  - Cognito client IDs
  - S3 bucket names
  - CloudFront domains
- AWS IAM: For service credentials
- RDS: For database

## Environment Detection

```csharp
var environment = BookstoreConfiguration.GetSetting("Environment");
if (environment == "Production")
{
    // Production-specific configuration
}
else
{
    // Development configuration
}
```

## Migration to ASP.NET Core

### Program.cs (ASP.NET Core equivalent)
```csharp
var builder = WebApplication.CreateBuilder(args);

// Add services to container
builder.Services.AddControllers();
builder.Services.AddDbContext<ApplicationDbContext>();

var app = builder.Build();

// Configure middleware pipeline
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### Key Differences
- No Global.asax (use Program.cs)
- No OWIN (use ASP.NET Core middleware)
- Built-in DI (no Autofac required)
- Simplified configuration (appsettings.json)

## Summary

Application startup involves:
- **Global.asax**: MVC configuration (areas, routes, filters, bundles)
- **OWIN Startup**: Middleware pipeline (logging, DI, authentication)
- **Configuration files**: Modular setup in App_Start folder
- **Environment-specific**: Different behavior for dev vs production
