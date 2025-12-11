# Dependencies and Packages Inventory - Bob's Used Bookstore Classic

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Package Manager:** NuGet

---

## Table of Contents
1. [Overview](#overview)
2. [Core Framework Packages](#core-framework-packages)
3. [Web Framework Packages](#web-framework-packages)
4. [Data Access Packages](#data-access-packages)
5. [AWS Integration Packages](#aws-integration-packages)
6. [Image Processing Packages](#image-processing-packages)
7. [Logging Packages](#logging-packages)
8. [Security and Authentication Packages](#security-and-authentication-packages)
9. [Dependency Injection Packages](#dependency-injection-packages)
10. [Build and Compilation Packages](#build-and-compilation-packages)
11. [Package Dependencies Tree](#package-dependencies-tree)

---

## Overview

This document provides a comprehensive inventory of all NuGet packages used in the Bob's Used Bookstore Classic application, organized by functional area. This information is critical for migration planning and dependency resolution.

**Total Packages:** 57  
**Package Sources:** NuGet.org  
**Package Config Format:** packages.config (legacy)

---

## Core Framework Packages

### System Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| System.Buffers | 4.6.1 | Memory buffers | Bookstore.Web |
| System.Memory | 4.6.3 | Memory APIs | Bookstore.Web |
| System.Numerics.Vectors | 4.6.1 | Vector operations | Bookstore.Web |
| System.ValueTuple | 4.6.1 | Value tuple support | Bookstore.Web |
| System.Text.Encoding | 4.3.0 | Text encoding | Bookstore.Web |
| System.Text.Encodings.Web | 9.0.3 | Web encoding | Bookstore.Web |
| System.Text.Json | 9.0.3 | JSON serialization | Bookstore.Web |
| System.IO.Pipelines | 9.0.3 | I/O pipelines | Bookstore.Web |
| System.Threading.Tasks.Extensions | 4.6.3 | Task extensions | Bookstore.Web |
| System.Runtime.CompilerServices.Unsafe | 6.1.2 | Unsafe operations | Bookstore.Web |

---

## Web Framework Packages

### ASP.NET MVC

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Microsoft.AspNet.Mvc | 5.3.0 | MVC framework | Bookstore.Web |
| Microsoft.AspNet.Razor | 3.3.0 | Razor view engine | Bookstore.Web |
| Microsoft.AspNet.WebPages | 3.3.0 | Web pages infrastructure | Bookstore.Web |
| Microsoft.Web.Infrastructure | 2.0.1 | Web infrastructure | Bookstore.Web |

### Web Optimization

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Microsoft.AspNet.Web.Optimization | 1.1.3 | Bundling and minification | Bookstore.Web |
| WebGrease | 1.6.0 | CSS/JS optimization | Bookstore.Web |
| Antlr | 3.5.0.2 | Parser for WebGrease | Bookstore.Web |

### JavaScript Libraries

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| jQuery | 3.7.1 | JavaScript library | Bookstore.Web |
| jQuery.Validation | 1.21.0 | Client-side validation | Bookstore.Web |
| Microsoft.jQuery.Unobtrusive.Validation | 4.0.0 | Unobtrusive validation | Bookstore.Web |
| Modernizr | 2.8.3 | Feature detection | Bookstore.Web |

---

## Data Access Packages

### Entity Framework

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| EntityFramework | 6.5.1 | ORM framework | Bookstore.Data, Bookstore.Web |

**Dependencies Included:**
- EntityFramework.SqlServer (automatically included)
- Includes Code-First migrations
- DbContext API
- LINQ to Entities

**Key Features:**
- SQL Server provider
- Async query support
- Code-First approach
- Migration support

---

## AWS Integration Packages

### AWS SDK Core

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| AWSSDK.Core | 3.7.402.35 | AWS SDK core | Bookstore.Data, Bookstore.Web |

### AWS Service Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| AWSSDK.S3 | 3.7.416.5 | S3 file storage | Bookstore.Data, Bookstore.Web |
| AWSSDK.Rekognition | 3.7.400.129 | Image validation | Bookstore.Data, Bookstore.Web |
| AWSSDK.CloudWatchLogs | 3.7.410.17 | CloudWatch logging | Bookstore.Web |
| AWSSDK.SimpleSystemsManagement | 3.7.404.10 | Parameter Store config | Bookstore.Web |

**Use Cases:**
- **S3:** Book cover image storage in production
- **Rekognition:** Content moderation for uploaded images
- **CloudWatch Logs:** Centralized logging in AWS
- **Systems Manager:** Configuration and secrets management

---

## Image Processing Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Magick.NET-Q8-AnyCPU | 14.6.0 | Image manipulation | Bookstore.Data |
| Magick.NET.Core | 14.6.0 | Magick.NET core | Bookstore.Data (dependency) |

**Features Used:**
- Image resizing
- Format conversion
- Quality optimization
- Thumbnail generation

**Q8 vs Q16:**
- Q8 = 8-bit color depth (smaller memory footprint)
- Sufficient for web images

---

## Logging Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| NLog | 5.4.0 | Logging framework | Bookstore.Web |
| AWS.Logger.Core | 3.3.3 | AWS logging core | Bookstore.Web |
| AWS.Logger.NLog | 3.3.4 | NLog AWS integration | Bookstore.Web |

**Configuration:**
- File logging for development
- CloudWatch Logs for production
- Configurable log levels
- Structured logging support

---

## Security and Authentication Packages

### OWIN Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Owin | 1.0 | OWIN specification | Bookstore.Web |
| Microsoft.Owin | 4.2.2 | OWIN implementation | Bookstore.Web |
| Microsoft.Owin.Host.SystemWeb | 4.2.2 | IIS hosting | Bookstore.Web |

### Authentication Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Microsoft.Owin.Security | 4.2.2 | Security middleware | Bookstore.Web |
| Microsoft.Owin.Security.Cookies | 4.2.2 | Cookie authentication | Bookstore.Web |
| Microsoft.Owin.Security.OpenIdConnect | 4.2.2 | OIDC authentication | Bookstore.Web |

### Identity Model Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Microsoft.IdentityModel.Abstractions | 8.7.0 | Identity abstractions | Bookstore.Web |
| Microsoft.IdentityModel.Logging | 8.7.0 | Identity logging | Bookstore.Web |
| Microsoft.IdentityModel.Protocols | 8.7.0 | Protocol handling | Bookstore.Web |
| Microsoft.IdentityModel.Protocols.OpenIdConnect | 8.7.0 | OIDC protocol | Bookstore.Web |
| Microsoft.IdentityModel.Tokens | 8.7.0 | Token handling | Bookstore.Web |
| Microsoft.IdentityModel.JsonWebTokens | 8.7.0 | JWT tokens | Bookstore.Web |
| System.IdentityModel.Tokens.Jwt | 8.7.0 | JWT validation | Bookstore.Web |

**Authentication Flows:**
- OpenID Connect with Cognito
- Cookie-based sessions
- JWT token validation
- Claims-based identity

---

## Dependency Injection Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Autofac | 8.2.1 | IoC container | Bookstore.Web |
| Autofac.Mvc5 | 6.1.0 | MVC integration | Bookstore.Web |
| Autofac.Owin | 7.1.0 | OWIN integration | Bookstore.Web |

**Features:**
- Constructor injection
- Lifetime management (Instance, PerRequest, Singleton)
- Module-based registration
- Integration with MVC and OWIN pipelines

---

## Build and Compilation Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Microsoft.CodeDom.Providers.DotNetCompilerPlatform | 4.1.0 | Roslyn compiler | Bookstore.Web |

**Features:**
- C# 7.3 language support
- Improved compilation performance
- Better error messages

---

## Microsoft Extensions Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| Microsoft.Extensions.DependencyInjection.Abstractions | 9.0.3 | DI abstractions | Bookstore.Web |
| Microsoft.Extensions.Logging.Abstractions | 9.0.3 | Logging abstractions | Bookstore.Web |
| Microsoft.Bcl.AsyncInterfaces | 9.0.3 | Async interfaces | Bookstore.Web |
| Microsoft.Bcl.TimeProvider | 9.0.3 | Time abstractions | Bookstore.Web |
| Microsoft.Bcl.Memory | 9.0.3 | Memory abstractions | Bookstore.Web |

**Note:** These are compatibility packages to support newer APIs on .NET Framework 4.8

---

## Diagnostics Packages

| Package | Version | Purpose | Project |
|---------|---------|---------|---------|
| System.Diagnostics.DiagnosticSource | 9.0.3 | Diagnostics | Bookstore.Web |

---

## Package Dependencies Tree

### Bookstore.Web

```
Bookstore.Web
├── Microsoft.AspNet.Mvc (5.3.0)
│   ├── Microsoft.AspNet.Razor (3.3.0)
│   └── Microsoft.AspNet.WebPages (3.3.0)
├── EntityFramework (6.5.1)
│   └── EntityFramework.SqlServer
├── Autofac (8.2.1)
│   ├── Autofac.Mvc5 (6.1.0)
│   └── Autofac.Owin (7.1.0)
├── Microsoft.Owin.Security.OpenIdConnect (4.2.2)
│   ├── Microsoft.Owin.Security.Cookies (4.2.2)
│   ├── Microsoft.Owin.Security (4.2.2)
│   ├── Microsoft.Owin (4.2.2)
│   └── Microsoft.IdentityModel.Protocols.OpenIdConnect (8.7.0)
│       ├── Microsoft.IdentityModel.Protocols (8.7.0)
│       └── Microsoft.IdentityModel.Tokens (8.7.0)
├── AWSSDK.S3 (3.7.416.5)
│   └── AWSSDK.Core (3.7.402.35)
├── AWSSDK.Rekognition (3.7.400.129)
│   └── AWSSDK.Core (3.7.402.35)
├── AWSSDK.CloudWatchLogs (3.7.410.17)
│   └── AWSSDK.Core (3.7.402.35)
├── AWS.Logger.NLog (3.3.4)
│   ├── AWS.Logger.Core (3.3.3)
│   └── NLog (5.4.0)
└── jQuery (3.7.1)
    ├── jQuery.Validation (1.21.0)
    └── Microsoft.jQuery.Unobtrusive.Validation (4.0.0)
```

### Bookstore.Data

```
Bookstore.Data
├── EntityFramework (6.5.1)
├── AWSSDK.S3 (3.7.416.5)
│   └── AWSSDK.Core (3.7.402.35)
├── AWSSDK.Rekognition (3.7.400.129)
│   └── AWSSDK.Core (3.7.402.35)
└── Magick.NET-Q8-AnyCPU (14.6.0)
    └── Magick.NET.Core (14.6.0)
```

### Bookstore.Domain

```
Bookstore.Domain
└── (No external dependencies - only .NET Framework references)
```

---

## License Considerations

### Open Source Licenses

- **MIT License:** Most Microsoft packages, Autofac, jQuery, NLog
- **Apache 2.0:** AWS SDK packages
- **ImageMagick License:** Magick.NET (permissive, Apache 2.0 style)

### Commercial Considerations

All packages used are free for commercial use. No paid licenses required.

---

## Security Vulnerabilities

### Known Issues (as of December 2024)

Check NuGet Audit for latest vulnerabilities:

```bash
dotnet list package --vulnerable
```

**Recommendation:** Before migration, update all packages to their latest versions within .NET Framework 4.8 compatibility.

---

## Migration to .NET Core 8.0 Package Equivalents

### Direct Equivalents

| .NET Framework 4.8 | .NET 8.0 | Notes |
|-------------------|----------|-------|
| EntityFramework 6.5.1 | Microsoft.EntityFrameworkCore 8.x | Different API |
| EntityFramework.SqlServer | Npgsql.EntityFrameworkCore.PostgreSQL | For PostgreSQL |
| Microsoft.AspNet.Mvc 5.3.0 | (Built-in to ASP.NET Core) | Framework |
| Autofac 8.2.1 | Autofac 8.x (compatible) | Version compatible |
| AWSSDK.* 3.7.x | AWSSDK.* 3.7.x | Same packages |
| NLog 5.4.0 | NLog 5.4.0 | Same package |
| Microsoft.Owin.* | (Built-in middleware) | ASP.NET Core middleware |

### Packages No Longer Needed in .NET 8.0

- **Microsoft.AspNet.***  - Built into ASP.NET Core
- **Microsoft.Owin.*** - ASP.NET Core middleware
- **Microsoft.Web.Infrastructure** - Not needed
- **WebGrease** - Built-in bundling in ASP.NET Core
- **Microsoft.CodeDom.Providers.DotNetCompilerPlatform** - Roslyn included

### New Packages Needed for .NET 8.0

- **Npgsql.EntityFrameworkCore.PostgreSQL** - PostgreSQL provider
- **Microsoft.AspNetCore.Authentication.OpenIdConnect** - OIDC (built-in)
- **Microsoft.Extensions.*** - Configuration, DI (built-in)

---

## Package Sizes and Performance

### Largest Packages

| Package | Download Size | Installed Size | Impact |
|---------|--------------|----------------|--------|
| Magick.NET-Q8-AnyCPU | ~8 MB | ~25 MB | Image processing |
| AWSSDK.S3 | ~5 MB | ~12 MB | File storage |
| EntityFramework | ~4 MB | ~10 MB | Data access |
| jQuery | ~250 KB | ~300 KB | Frontend |
| NLog | ~2 MB | ~5 MB | Logging |

**Total Package Size:** ~150 MB (all projects combined)

---

## Package Update Strategy

### Safe Updates (Patch versions)

- Update to latest patch version within same minor version
- Example: 8.7.0 → 8.7.x

### Minor Updates (Feature versions)

- Test thoroughly before updating
- Example: 8.7.x → 8.8.x
- Review breaking changes

### Major Updates

- Requires code changes
- Review migration guides
- Example: 6.x → 8.x (EF Framework to EF Core)

---

**Next:** 07-reverse-engineered-requirements.md
