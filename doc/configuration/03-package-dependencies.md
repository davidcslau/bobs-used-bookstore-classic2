# Package Dependencies

## Core Dependencies

### Web Framework
- Microsoft.AspNet.Mvc 5.3.0
- Microsoft.AspNet.Razor 3.3.0
- Microsoft.AspNet.WebPages 3.3.0
- Microsoft.AspNet.Web.Optimization 1.1.3

### Data Access
- EntityFramework 6.5.1

### Dependency Injection
- Autofac 8.2.1
- Autofac.Mvc5 6.1.0
- Autofac.Owin 7.1.0

### Authentication
- Microsoft.Owin 4.2.2
- Microsoft.Owin.Security.OpenIdConnect 4.2.2
- Microsoft.Owin.Security.Cookies 4.2.2
- Microsoft.IdentityModel.Protocols.OpenIdConnect 8.7.0

### AWS SDK
- AWSSDK.Core 3.7.402.35
- AWSSDK.S3 3.7.416.5
- AWSSDK.Rekognition 3.7.400.129
- AWSSDK.CloudWatchLogs 3.7.410.17
- AWSSDK.SimpleSystemsManagement 3.7.404.10

### Logging
- NLog 5.4.0
- AWS.Logger.NLog 3.3.4

### Utilities
- Newtonsoft.Json 13.0.3
- jQuery 3.7.1
- jQuery.Validation 1.21.0

## Version Conflicts

Resolved via binding redirects in Web.config for:
- Newtonsoft.Json
- System.Memory
- System.Buffers
- Microsoft.Owin
- Microsoft.IdentityModel.*

## Migration Path

### .NET 8.0 Replacements
- EntityFramework 6.5.1 → Microsoft.EntityFrameworkCore 8.x
- Autofac (optional) → Built-in DI
- Microsoft.AspNet.Mvc → Microsoft.AspNetCore.Mvc
- OWIN → ASP.NET Core middleware
- System.Web → Microsoft.AspNetCore.*

### Package Compatibility
- AWS SDK: Compatible with .NET 8
- NLog: Compatible with .NET 8
- Newtonsoft.Json: Compatible with .NET 8
- jQuery: No changes needed
