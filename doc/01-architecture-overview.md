# Architecture Overview - Bob's Used Bookstore Classic

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Target Framework:** .NET Framework 4.8  
**Database:** SQL Server (LocalDB / RDS for SQL Server)

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Solution Architecture](#solution-architecture)
3. [Project Structure](#project-structure)
4. [Architectural Patterns](#architectural-patterns)
5. [Technology Stack](#technology-stack)

---

## Executive Summary

Bob's Used Bookstore Classic is an ASP.NET MVC 5 web application built on .NET Framework 4.8 that implements a complete e-commerce platform for buying and selling used books. The application follows a 3-tier layered architecture with clear separation of concerns between presentation, business logic, and data access layers.

**Key Characteristics:**
- **Architecture Style:** 3-Tier Layered Architecture
- **Presentation Pattern:** Model-View-Controller (MVC 5)
- **Data Access Pattern:** Repository Pattern with Entity Framework 6.5.1
- **Dependency Injection:** Autofac 8.2.1
- **Authentication:** OWIN-based (local or AWS Cognito)
- **Deployment Target:** Windows Server / IIS or AWS ECS with Windows containers

---

## Solution Architecture

### High-Level Architecture

The application consists of three primary layers:

1. **Presentation Layer (Bookstore.Web)** - ASP.NET MVC 5 application handling HTTP requests and rendering views
2. **Business Logic Layer (Bookstore.Domain)** - Domain models, business rules, and service interfaces
3. **Data Access Layer (Bookstore.Data)** - Entity Framework implementation and repository pattern

### Layer Dependencies

```
Bookstore.Web (MVC)
    ↓ depends on
Bookstore.Domain (Business Logic)
    ↓ depends on
Bookstore.Data (Data Access)
    ↓ depends on
SQL Server Database
```

---

## Project Structure

### 1. Bookstore.Web (Presentation Layer)
- **Type:** ASP.NET MVC 5 Web Application
- **Target Framework:** .NET Framework 4.8
- **Key Components:**
  - Controllers: Handle HTTP requests (9 controllers)
  - Views: Razor templates for UI rendering (24 views)
  - ViewModels: Data structures for views
  - App_Start: Application configuration and startup
  - Areas: Admin area for administrative functions
  - Helpers: Custom attributes, extensions, middleware

### 2. Bookstore.Domain (Business Logic Layer)
- **Type:** Class Library
- **Target Framework:** .NET Framework 4.8
- **Key Components:**
  - Domain Entities: Books, Orders, Customers, Offers, Carts, Addresses, ReferenceData
  - Service Interfaces: IBookService, IOrderService, IOfferService, etc.
  - Repository Interfaces: IBookRepository, IOrderRepository, etc.
  - DTOs: Data Transfer Objects for API contracts
  - Business Logic: Validation, calculations, domain rules

**Domain Modules:**
- Books: Book catalog management
- Orders: Order processing and management
- Offers: Customer book resale offers
- Carts: Shopping cart and wishlist
- Customers: Customer profile management
- Addresses: Shipping address management
- ReferenceData: Genres, publishers, book types, conditions

### 3. Bookstore.Data (Data Access Layer)
- **Type:** Class Library
- **Target Framework:** .NET Framework 4.8
- **Key Components:**
  - ApplicationDbContext: Entity Framework DbContext
  - Repositories: Concrete implementation of repository interfaces
  - BookstoreDbInitializer: Database seeding
  - FileServices: Local and S3 file storage
  - ImageServices: Image resizing and validation

### 4. Bookstore.Common
- **Type:** Class Library
- **Purpose:** Shared utilities and common functionality

### 5. Bookstore.Cdk
- **Type:** AWS CDK Project
- **Purpose:** Infrastructure as Code for AWS deployment

---

## Architectural Patterns

### 1. Layered Architecture
Strict 3-tier separation ensuring:
- Clear separation of concerns
- Improved maintainability
- Testability at each layer
- Technology independence at business layer

### 2. Repository Pattern
All data access abstracted through repository interfaces defined in Domain layer:

```csharp
// Interface in Domain layer
public interface IBookRepository
{
    Task<Book> GetAsync(int id);
    Task<IPaginatedList<Book>> ListAsync(BookFilters filters, int pageIndex, int pageSize);
    Task CreateAsync(Book book);
}

// Implementation in Data layer
public class BookRepository : IBookRepository
{
    private readonly ApplicationDbContext dbContext;
    // Implementation...
}
```

### 3. Service Layer Pattern
Business logic encapsulated in service classes:

```csharp
public interface IBookService
{
    Task<BookDto> GetBookAsync(int id);
    Task<BookSearchResultDto> SearchBooksAsync(BookFilters filters, int page, int pageSize);
}
```

### 4. Model-View-Controller (MVC)
- **Models (ViewModels):** Data structures for views
- **Views (Razor):** HTML templates with server-side rendering
- **Controllers:** Handle HTTP requests and coordinate responses

### 5. Dependency Injection
Uses Autofac for IoC:
- Constructor injection throughout
- Lifetime management (InstancePerRequest, Singleton)
- Interface-based programming

---

## Technology Stack

### Core Framework
- **.NET Framework 4.8**
- **ASP.NET MVC 5.3.0**
- **C# 7.3**

### Data Access
- **Entity Framework 6.5.1** - ORM
- **SQL Server** - Database
- **System.Data.SqlClient** - Database provider

### Web Technologies
- **Razor View Engine 3.3.0**
- **jQuery 3.7.1**
- **Bootstrap** (CSS framework)
- **ASP.NET Web Optimization 1.1.3** - Bundling/minification

### Authentication & Security
- **OWIN 4.2.2**
- **Microsoft.Owin.Security.OpenIdConnect 4.2.2**
- **Microsoft.IdentityModel.Tokens 8.7.0**

### Dependency Injection
- **Autofac 8.2.1**
- **Autofac.Mvc5 6.1.0**
- **Autofac.Owin 7.1.0**

### AWS Integration (Optional)
- **AWSSDK.S3 3.7.416.5** - File storage
- **AWSSDK.Rekognition 3.7.400.129** - Image validation
- **AWSSDK.CloudWatchLogs 3.7.410.17** - Logging
- **AWSSDK.SimpleSystemsManagement 3.7.404.10** - Configuration

### Image Processing
- **Magick.NET-Q8-AnyCPU 14.6.0**

### Logging
- **NLog 5.4.0**
- **AWS.Logger.NLog 3.3.4**

---

## Deployment Architecture

### Development Environment
- IIS Express
- SQL Server LocalDB
- Local file system for book covers
- Local authentication (no Cognito)

### Production Environment (AWS ECS)
- Windows containers on Fargate
- Application Load Balancer
- RDS for SQL Server (private VPC)
- Amazon S3 for file storage
- Amazon Cognito for authentication
- Amazon Rekognition for image validation
- Systems Manager Parameter Store for configuration

### IIS Deployment (Windows Server)
- Windows Server 2016/2019/2022
- IIS 10.0
- SQL Server 2019/2022 (local or remote)
- Application Pool (.NET CLR v4.0, Integrated Pipeline)

---

## Security Architecture

### Authentication
- **Local Mode:** Custom OWIN middleware with hardcoded credentials
- **AWS Mode:** OpenID Connect with Cognito User Pools
- Cookie-based sessions
- Claims-based identity

### Authorization
- Controller/Action level with [Authorize] attribute
- Admin area requires authentication
- Customer-specific data access controls

### Data Protection
- Connection strings in Web.config (encrypted in production)
- AWS Systems Manager for secrets in production
- Entity Framework parameterized queries (SQL injection protection)
- Razor auto-escaping (XSS protection)
- Anti-forgery tokens (CSRF protection)

### File Upload Security
- File type validation (images only)
- Size limits
- Content validation with Rekognition (AWS mode)

---

**Next:** 02-domain-model-documentation.md
