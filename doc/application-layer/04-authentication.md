# Authentication & Authorization

## Authentication Methods

### 1. Local Authentication (Development)

**Middleware**: LocalAuthenticationMiddleware
**Purpose**: Bypass authentication for local development
**Implementation**: Creates a fake authenticated user

```csharp
if (BookstoreConfiguration.GetSetting("Services/Authentication") != "aws")
{
    builder.RegisterType<LocalAuthenticationMiddleware>();
}
```

### 2. AWS Cognito (Production)

**Protocol**: OpenID Connect
**Provider**: AWS Cognito User Pools

```csharp
app.UseOpenIdConnectAuthentication(new OpenIdConnectAuthenticationOptions
{
    ClientId = BookstoreConfiguration.GetSetting("Authentication/Cognito/LocalClientId"),
    MetadataAddress = BookstoreConfiguration.GetSetting("Authentication/Cognito/MetadataAddress"),
    ResponseType = OpenIdConnectResponseType.Code,
    Scope = "openid profile",
    TokenValidationParameters = new TokenValidationParameters
    {
        NameClaimType = "cognito:username",
        RoleClaimType = "cognito:groups"
    }
});
```

## Authentication Flow (Cognito)

1. User clicks Login
2. Redirected to Cognito hosted UI
3. User enters credentials
4. Cognito validates and returns authorization code
5. Application exchanges code for ID token
6. Token validated using OIDC metadata
7. Claims extracted from token
8. Customer record created/updated
9. Authentication cookie set
10. User redirected to application

## Authorization

### Controller-Level
```csharp
[Authorize] // Requires authentication
public class OrdersController : Controller { }

[AllowAnonymous] // Public access
public class HomeController : Controller { }
```

### Admin Area
All admin controllers inherit from AdminAreaControllerBase with [Authorize] attribute.

## Claims

- **Sub**: Subject identifier (unique user ID)
- **cognito:username**: Username
- **givenname**: First name
- **surname**: Last name
- **email**: Email address
- **cognito:groups**: User roles (admin, etc.)

## Session Management

- **Cookie-based**: Authentication stored in encrypted cookie
- **Sliding Expiration**: Cookie refreshed on activity
- **Lifetime**: Configured in OWIN cookie middleware

## Migration to ASP.NET Core

Use ASP.NET Core Identity with OpenID Connect:
```csharp
services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
})
.AddCookie()
.AddOpenIdConnect(options =>
{
    options.Authority = cognitoAuthority;
    options.ClientId = clientId;
});
```
