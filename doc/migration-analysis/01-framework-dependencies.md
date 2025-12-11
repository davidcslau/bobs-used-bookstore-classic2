# .NET Framework Dependencies and Migration

## .NET Framework 4.8 Specific Dependencies

### System.Web Namespace
**Current Usage**: Core web hosting infrastructure

**Components**:
- HttpContext, HttpRequest, HttpResponse
- HttpApplication (Global.asax)
- HttpPostedFileBase (file uploads)
- HttpRuntime (application paths)

**Migration Path**:
- HttpContext → Microsoft.AspNetCore.Http.HttpContext
- HttpPostedFileBase → IFormFile
- HttpRuntime.AppDomainAppPath → IWebHostEnvironment.ContentRootPath
- No Global.asax → Use Program.cs and middleware

### OWIN Dependencies
**Current Usage**: Authentication middleware

**Packages**:
- Microsoft.Owin 4.2.2
- Microsoft.Owin.Security.OpenIdConnect
- Microsoft.Owin.Security.Cookies

**Migration Path**:
- OWIN → ASP.NET Core middleware pipeline
- CookieAuthenticationMiddleware → Built-in cookie authentication
- OpenIdConnectAuthenticationMiddleware → Built-in OIDC
- IAppBuilder → IApplicationBuilder

**Example**:
```csharp
// .NET Framework OWIN
app.UseCookieAuthentication(new CookieAuthenticationOptions());

// ASP.NET Core
services.AddAuthentication()
    .AddCookie();
```

### ASP.NET MVC 5 Dependencies
**Current Usage**: Web framework

**Components**:
- System.Web.Mvc.Controller
- ActionResult types
- Razor view engine
- Model binding
- Filters

**Migration Path**:
- System.Web.Mvc → Microsoft.AspNetCore.Mvc
- Controller → Microsoft.AspNetCore.Mvc.Controller
- ActionResult → IActionResult
- Razor remains similar
- Filters: Attribute-based similar, implementation different

**Changes Required**:
```csharp
// .NET Framework
public class HomeController : Controller
{
    public ActionResult Index()
    {
        return View();
    }
}

// ASP.NET Core (minimal changes)
public class HomeController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}
```

### Web.config Dependencies
**Current Usage**: Application configuration

**Migration Path**:
- XML-based → JSON-based (appsettings.json)
- Connection strings → ConnectionStrings section
- AppSettings → Configuration sections
- System.web settings → Middleware configuration in code

### Assembly Binding Redirects
**Current Usage**: Resolve package version conflicts

**Migration Path**:
- Not needed in .NET Core (improved dependency resolution)
- Remove all bindingRedirect elements

## Breaking Changes

### 1. No More System.Web
**Impact**: High
**Effort**: High

**Affected Areas**:
- File upload handling
- Session state access
- HTTP context access
- Path resolution
- Server variables

### 2. Configuration System
**Impact**: Medium
**Effort**: Medium

**Required Changes**:
- Convert Web.config to appsettings.json
- Update configuration access code
- Move secrets to user secrets or Parameter Store

### 3. Startup Model
**Impact**: Medium
**Effort**: Low

**Changes**:
- Remove Global.asax
- Create Program.cs with WebApplication.CreateBuilder
- Move initialization to Program.cs or Startup class

### 4. Routing
**Impact**: Low
**Effort**: Low

**Changes**:
- Attribute routing preferred
- Endpoint routing instead of route table
- Similar concepts, different syntax

### 5. Dependency Injection
**Impact**: Low (already using Autofac)
**Effort**: Low

**Options**:
- Continue using Autofac (with ASP.NET Core adapter)
- Migrate to built-in DI (recommended)

## Migration Steps

### Phase 1: Analysis
1. Identify all System.Web usages
2. List OWIN middleware dependencies
3. Document Web.config settings
4. Map configuration to appsettings.json

### Phase 2: Project Conversion
1. Convert .csproj to SDK-style
2. Update target framework to net8.0
3. Update package references
4. Remove assembly binding redirects

### Phase 3: Code Updates
1. Replace System.Web.Mvc with Microsoft.AspNetCore.Mvc
2. Update controller base classes
3. Replace HttpPostedFileBase with IFormFile
4. Update HTTP context access
5. Convert OWIN middleware to ASP.NET Core middleware

### Phase 4: Configuration
1. Create appsettings.json from Web.config
2. Update configuration access code
3. Set up user secrets for local development
4. Configure AWS Parameter Store for production

### Phase 5: Testing
1. Unit tests for converted code
2. Integration tests for HTTP endpoints
3. End-to-end testing
4. Performance comparison

## Compatibility Tools

### .NET Portability Analyzer
- Analyze assemblies for .NET Core compatibility
- Identify APIs not available in .NET Core

### try-convert Tool
- Automatically convert .csproj files to SDK-style
- Updates package references

### Platform Compatibility Analyzer
- Built into .NET 5+
- Warns about platform-specific APIs

## Risk Assessment

### High Risk Items
- System.Web dependencies (requires code changes throughout)
- OWIN middleware (authentication flow changes)
- File upload handling (different API)

### Medium Risk Items
- Configuration management (structural changes)
- Session state (may need distributed cache)
- Path resolution (different APIs)

### Low Risk Items
- Controllers (mostly compatible)
- Views (Razor similar)
- Domain/Data layers (no changes needed)

## Effort Estimation

### Bookstore.Web Project
- **Effort**: 20-30 hours
- **Complexity**: Medium-High
- **Testing**: 10-15 hours

### Bookstore.Domain Project
- **Effort**: 0-2 hours
- **Complexity**: Low
- **Testing**: 5 hours

### Bookstore.Data Project
- **Effort**: 10-15 hours (EF 6 → EF Core)
- **Complexity**: Medium
- **Testing**: 10 hours

### Bookstore.Common Project
- **Effort**: 0-2 hours
- **Complexity**: Low
- **Testing**: 2 hours

**Total Estimated Effort**: 45-64 hours

## Success Criteria

1. ✓ Application runs on .NET 8.0
2. ✓ No System.Web dependencies
3. ✓ All tests pass
4. ✓ Performance equal or better
5. ✓ Can deploy to Linux
6. ✓ Configuration management working
7. ✓ Authentication functional
