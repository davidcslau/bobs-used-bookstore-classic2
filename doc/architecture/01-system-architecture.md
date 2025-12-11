# System Architecture Overview

## Overview

Bob's Used Bookstore Classic follows a three-tier architecture pattern with clear separation of concerns between presentation, business logic, and data access layers. The application is built using .NET Framework 4.8 and ASP.NET MVC 5.

## Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│                   (Bookstore.Web)                            │
│  - MVC Controllers                                           │
│  - Razor Views                                               │
│  - View Models                                               │
│  - Middleware (Authentication, Logging)                      │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                      │
│                   (Bookstore.Domain)                         │
│  - Domain Entities                                           │
│  - Business Services                                         │
│  - Service Interfaces                                        │
│  - Business Rules & Validation                               │
│  - Domain Transfer Objects (DTOs)                            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Access Layer                         │
│                   (Bookstore.Data)                           │
│  - Entity Framework DbContext                                │
│  - Repository Implementations                                │
│  - Database Configuration                                    │
│  - External Service Integrations                             │
│    - File Services (Local/S3)                                │
│    - Image Validation (Local/Rekognition)                    │
│    - Image Resize Service                                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  - SQL Server Database                                       │
│  - AWS Services (S3, Rekognition, CloudWatch)                │
│  - File System Storage                                       │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

### 1. Bookstore.Web (Presentation Layer)
**Purpose**: Handles HTTP requests, user interface, and presentation logic

**Key Components**:
- **Controllers**: Handle HTTP requests and orchestrate business logic
  - Customer Controllers: Home, Search, ShoppingCart, Wishlist, Checkout, Orders, Resale, Address
  - Admin Controllers: Dashboard, Inventory, Orders, Offers, ReferenceData
  - Authentication Controller: Manages login/logout
  
- **Views**: Razor templates for rendering HTML
  - Layout pages for consistent UI
  - Partial views for reusable components
  - Area-specific views (Admin area)

- **View Models**: Data transfer objects for views
  - Input models for form submissions
  - Display models for rendering data
  - Paginated view models

- **App_Start**: Configuration and startup logic
  - DependencyInjectionSetup: Autofac container configuration
  - AuthenticationSetup: OWIN authentication middleware
  - RouteConfig: URL routing rules
  - BundleConfig: JavaScript and CSS bundling
  - FilterConfig: Global action filters

- **Middleware**:
  - LocalAuthenticationMiddleware: Local development authentication
  - Error handling middleware
  - Logging middleware

### 2. Bookstore.Domain (Business Logic Layer)
**Purpose**: Contains business entities, rules, and services

**Key Components**:

- **Domain Entities**:
  - `Book`: Book inventory items with properties and business rules
  - `Customer`: Customer accounts and profile information
  - `Order`: Purchase orders with order items
  - `ShoppingCart`: Shopping cart and wishlist functionality
  - `Offer`: Customer book resale offers
  - `Address`: Customer shipping addresses
  - `ReferenceData`: Lookup data (genres, publishers, book types, conditions)

- **Business Services**:
  - `BookService`: Book inventory and search operations
  - `CustomerService`: Customer management
  - `OrderService`: Order processing and management
  - `ShoppingCartService`: Cart and wishlist operations
  - `OfferService`: Resale offer management
  - `AddressService`: Address management
  - `ReferenceDataService`: Lookup data operations

- **Service Interfaces**:
  - Repository interfaces (IBookRepository, ICustomerRepository, etc.)
  - External service interfaces (IFileService, IImageValidationService, IImageResizeService)

- **DTOs (Data Transfer Objects)**:
  - Request/response objects for service methods
  - Decouples domain entities from API contracts

### 3. Bookstore.Data (Data Access Layer)
**Purpose**: Manages data persistence and external service integration

**Key Components**:

- **ApplicationDbContext**: Entity Framework DbContext
  - Configures entity mappings
  - Defines database relationships
  - Manages database initialization

- **Repositories**: Implementation of repository pattern
  - `BookRepository`: Book data access
  - `CustomerRepository`: Customer data access
  - `OrderRepository`: Order data access
  - `ShoppingCartRepository`: Shopping cart data access
  - `OfferRepository`: Offer data access
  - `AddressRepository`: Address data access
  - `ReferenceDataRepository`: Reference data access

- **File Services**:
  - `LocalFileService`: Local filesystem storage
  - `S3FileService`: AWS S3 cloud storage

- **Image Services**:
  - `LocalImageValidationService`: Basic image validation
  - `RekognitionImageValidationService`: AWS Rekognition content moderation
  - `ImageResizeService`: Image transformation

- **Configuration**:
  - `BookstoreConfiguration`: Configuration management
  - Connection string management
  - AWS Systems Manager Parameter Store integration

### 4. Bookstore.Common (Shared Utilities)
**Purpose**: Shared utilities and common code

**Components**:
- Extension methods
- Constants
- Helper classes

### 5. Bookstore.Cdk (Infrastructure as Code)
**Purpose**: AWS CDK infrastructure definitions

**Components**:
- `NetworkStack`: VPC and networking
- `DatabaseStack`: RDS configuration
- `EcsStack`: ECS Fargate deployment
- `CoreStack`: Shared resources

## Design Patterns

### 1. Repository Pattern
- Abstracts data access logic
- Provides testable interfaces
- Centralizes data access logic
- Enables easy switching of data sources

### 2. Service Layer Pattern
- Encapsulates business logic
- Coordinates between repositories
- Provides transaction boundaries
- Implements business rules

### 3. Dependency Injection
- Uses Autofac for IoC container
- Constructor injection throughout
- Interface-based dependencies
- Enables loose coupling and testability

### 4. Model-View-Controller (MVC)
- Separates concerns in web layer
- Controllers handle requests
- Views render UI
- Models carry data

### 5. Data Transfer Object (DTO)
- Separates internal and external representations
- Optimizes data transfer
- Provides versioning capability

## Layer Communication

### Request Flow (Customer Browsing Books)
```
1. User → Browser → HTTP Request
2. IIS/Kestrel → Routing → BooksController
3. BooksController → IBookService.ListBooksAsync()
4. BookService → IBookRepository.ListAsync()
5. BookRepository → ApplicationDbContext → Database
6. Database → Results
7. BookRepository → BookService (Domain Entities)
8. BookService → BooksController (DTOs)
9. BooksController → View (ViewModel)
10. View → HTML Response → Browser
```

### Authentication Flow
```
1. User Login → AuthenticationController
2. Local Mode: LocalAuthenticationMiddleware
3. AWS Mode: OWIN OpenIdConnect → AWS Cognito
4. Token Validation → Claims Principal
5. Create/Update Customer → CustomerService
6. Set Authentication Cookie
7. Redirect to Application
```

### File Upload Flow
```
1. File Upload → Controller
2. Image Validation → IImageValidationService
   - Local: Basic validation
   - AWS: Rekognition content moderation
3. Image Resize → IImageResizeService
4. File Storage → IFileService
   - Local: FileSystem storage
   - AWS: S3 upload with CloudFront URL
5. URL returned to Controller
6. Save URL in Database
```

## Cross-Cutting Concerns

### 1. Logging
- **Framework**: NLog
- **Configuration**: NLog.config
- **AWS Integration**: CloudWatch Logs via AWS.Logger.NLog
- **Scope**: Application-wide error and diagnostic logging

### 2. Configuration Management
- **Local**: Web.config/App.config
- **AWS**: Systems Manager Parameter Store
- **Pattern**: Configuration abstraction through BookstoreConfiguration class

### 3. Authentication & Authorization
- **Framework**: OWIN + Microsoft.Owin.Security
- **Methods**: 
  - Local: Cookie-based authentication
  - AWS: OpenID Connect with Cognito
- **Authorization**: Role-based with Admin area

### 4. Error Handling
- **Global Error Handler**: Application_Error in Global.asax
- **Controller Error Handling**: Try-catch with logging
- **User-Friendly Errors**: Error views

### 5. Database Transaction Management
- **Unit of Work**: DbContext per request (InstancePerRequest)
- **Transaction Scope**: Repository SaveChanges methods
- **Concurrency**: RowVersion timestamp fields

## Architectural Principles

### 1. Separation of Concerns
- Clear boundaries between layers
- Each layer has specific responsibility
- Minimal dependencies between layers

### 2. Dependency Inversion
- High-level modules don't depend on low-level modules
- Both depend on abstractions
- Interfaces define contracts

### 3. Single Responsibility
- Each class has one reason to change
- Services focus on specific business domains
- Repositories handle single entity types

### 4. Open/Closed Principle
- Open for extension (interfaces)
- Closed for modification
- Strategy pattern for file/image services

### 5. Interface Segregation
- Small, focused interfaces
- Clients depend only on methods they use
- Repository interfaces per entity

## Technology Stack Integration

### ASP.NET MVC 5.3.0
- Request pipeline and routing
- Model binding and validation
- View rendering with Razor
- Action filters for cross-cutting concerns

### Entity Framework 6.5.1
- Code-first approach
- Fluent API for configuration
- Lazy loading and eager loading
- Database migrations

### Autofac 8.2.1
- Dependency injection container
- Lifetime management
- Module-based configuration
- Integration with OWIN and MVC

### OWIN
- Authentication middleware
- Application startup
- Middleware pipeline

## Deployment Architecture

### Development Environment
```
Developer Workstation
  ├── IIS Express (Web Server)
  ├── SQL Server LocalDB (Database)
  └── Local File System (File Storage)
```

### Production Environment (Windows/IIS)
```
┌──────────────────────┐
│   Load Balancer      │
└──────────────────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌─────────┐   ┌─────────┐
│  IIS 1  │   │  IIS 2  │
│  Web    │   │  Web    │
└─────────┘   └─────────┘
     │             │
     └──────┬──────┘
            ▼
    ┌──────────────┐
    │  SQL Server  │
    └──────────────┘
            │
    ┌───────┴────────┐
    ▼                ▼
┌─────────┐    ┌──────────┐
│   S3    │    │Rekognition│
└─────────┘    └──────────┘
```

### Target Environment (Linux/ECS)
```
┌──────────────────────┐
│   Application LB     │
└──────────────────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌──────────┐  ┌──────────┐
│ECS Task 1│  │ECS Task 2│
│ Fargate  │  │ Fargate  │
└──────────┘  └──────────┘
     │             │
     └──────┬──────┘
            ▼
    ┌──────────────┐
    │  PostgreSQL  │
    │     RDS      │
    └──────────────┘
            │
    ┌───────┴────────┐
    ▼                ▼
┌─────────┐    ┌──────────┐
│   S3    │    │Rekognition│
└─────────┘    └──────────┘
```

## Key Architectural Decisions

### 1. Three-Tier Architecture
**Decision**: Use layered architecture with Web, Domain, and Data projects

**Rationale**:
- Clear separation of concerns
- Independent testability
- Flexibility to change implementations
- Standard enterprise pattern

### 2. Repository Pattern
**Decision**: Implement repository pattern for data access

**Rationale**:
- Abstracts Entity Framework details
- Enables unit testing with mocks
- Centralizes query logic
- Provides consistent data access API

### 3. Service Layer
**Decision**: Separate business logic into service classes

**Rationale**:
- Keeps controllers thin
- Reusable business logic
- Transaction boundaries
- Domain-driven design

### 4. Configuration Strategy Pattern
**Decision**: Use strategy pattern for file and image services

**Rationale**:
- Support local development without AWS
- Easy switching between implementations
- Production uses AWS services
- Configuration-driven selection

### 5. OWIN Authentication
**Decision**: Use OWIN middleware for authentication

**Rationale**:
- Standard .NET Framework approach
- Supports multiple authentication schemes
- OpenID Connect integration
- Cookie-based sessions

## Scalability Considerations

### Current Limitations
1. **Session State**: In-memory sessions don't scale horizontally
2. **File Storage**: Local files require sticky sessions
3. **Database**: Single SQL Server instance
4. **IIS Hosting**: Windows-specific deployment

### Scaling Strategies (Current)
1. **Vertical Scaling**: Increase server resources
2. **AWS Services**: Offload to S3, Rekognition, CloudWatch
3. **Database Optimization**: Indexes, query optimization
4. **Caching**: Output caching for static content

### Future Scalability (Post-Migration)
1. **Horizontal Scaling**: Multiple ECS tasks
2. **Distributed Caching**: Redis for session state
3. **Database Clustering**: PostgreSQL read replicas
4. **CDN**: CloudFront for static assets
5. **Containerization**: Docker for consistent deployment

## Security Architecture

### Authentication
- OpenID Connect for federated identity
- Cookie-based session management
- Secure token storage

### Authorization
- Role-based access control
- Admin area protection
- Controller-level authorization attributes

### Data Protection
- SQL parameterization (Entity Framework)
- Input validation
- Content Security Policy headers

### Sensitive Data
- Connection strings in configuration
- AWS credentials from IAM roles
- Parameter Store for secrets

## Performance Characteristics

### Response Time
- Average page load: < 500ms
- Database queries: < 100ms
- Image operations: < 2 seconds

### Throughput
- Concurrent users: 50-100 (current IIS setup)
- Database connections: Pooled, max 100
- File uploads: Max 5MB

### Resource Usage
- Memory: ~200MB per application pool
- CPU: Low usage, spikes during image processing
- Database: < 1GB current size

## Monitoring and Observability

### Logging
- NLog for application logs
- CloudWatch Logs for centralized logging
- Error tracking with stack traces

### Metrics
- IIS performance counters
- SQL Server query statistics
- Application-level metrics (planned)

### Health Checks
- Basic application availability
- Database connectivity
- AWS service availability

## Summary

The Bob's Used Bookstore Classic application follows well-established architectural patterns with clear separation between presentation, business logic, and data access layers. The architecture supports both local development and cloud deployment, with configuration-driven selection of services. The three-tier structure provides maintainability and testability, though some .NET Framework-specific patterns will need modernization during the .NET 8 migration.
