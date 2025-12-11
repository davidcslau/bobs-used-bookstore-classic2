# Bob's Used Bookstore Classic - Documentation

This documentation provides a comprehensive analysis of the Bob's Used Bookstore Classic application, built on .NET Framework 4.8. The documentation is organized to support engineering teams in understanding the current system and preparing for migration to .NET 8.0.

## Documentation Structure

### 1. [Architecture Documentation](./architecture/)
- [System Architecture Overview](./architecture/01-system-architecture.md) - Three-tier structure and design patterns
- [Component Interactions](./architecture/02-component-interactions.md) - Dependencies and communication patterns
- [Technology Stack](./architecture/03-technology-stack.md) - Current technologies and frameworks

### 2. [Data Layer Documentation](./data-layer/)
- [Database Schema](./data-layer/01-database-schema.md) - Complete entity model documentation
- [Entity Framework Configuration](./data-layer/02-ef-configuration.md) - DbContext and relationships
- [Repository Pattern](./data-layer/03-repository-pattern.md) - Repository implementations

### 3. [Application Layer Documentation](./application-layer/)
- [Web Application Structure](./application-layer/01-web-structure.md) - MVC architecture details
- [Application Startup](./application-layer/02-startup-configuration.md) - Bootstrap and configuration
- [Dependency Injection](./application-layer/03-dependency-injection.md) - DI container setup
- [Authentication & Authorization](./application-layer/04-authentication.md) - Security implementation

### 4. [Service Integrations Documentation](./service-integrations/)
- [File Service](./service-integrations/01-file-service.md) - Local and AWS S3 implementations
- [Image Validation Service](./service-integrations/02-image-validation.md) - Image processing and validation
- [Image Resize Service](./service-integrations/03-image-resize.md) - Image transformation
- [External Dependencies](./service-integrations/04-external-dependencies.md) - Third-party services

### 5. [Configuration Documentation](./configuration/)
- [Web.config Analysis](./configuration/01-web-config.md) - Application configuration
- [App.config Settings](./configuration/02-app-config.md) - Data layer configuration
- [Package Dependencies](./configuration/03-package-dependencies.md) - NuGet packages

### 6. [Requirements Documentation](./requirements/)
- [Functional Requirements](./requirements/01-functional-requirements.md) - Feature catalog
- [Non-Functional Requirements](./requirements/02-non-functional-requirements.md) - Quality attributes
- [Business Rules](./requirements/03-business-rules.md) - Domain logic and validation
- [User Workflows](./requirements/04-user-workflows.md) - Use cases and scenarios

### 7. [Migration Analysis](./migration-analysis/)
- [Framework Dependencies](./migration-analysis/01-framework-dependencies.md) - .NET Framework specifics
- [Entity Framework Migration](./migration-analysis/02-ef-migration.md) - EF 6.x to EF Core
- [Database Migration](./migration-analysis/03-database-migration.md) - SQL Server to PostgreSQL
- [Hosting Migration](./migration-analysis/04-hosting-migration.md) - IIS to Kestrel/Linux
- [Migration Strategy](./migration-analysis/05-migration-strategy.md) - Phased approach

### 8. [Technology Steering](./tech_steering.json)
Complete technology stack documentation including current state, target state, and service configurations for the migration.

## Application Overview

**Bob's Used Bookstore Classic** is an e-commerce web application for managing a used bookstore. The application supports:

- **Customer-facing features**: Book browsing, search, shopping cart, wishlist, checkout
- **Admin features**: Inventory management, order processing, offer management, reference data management
- **Authentication**: Local and AWS Cognito integration
- **File Management**: Local filesystem and AWS S3 storage
- **Image Processing**: Local and AWS Rekognition validation

## Current Technology Stack

- **.NET Framework**: 4.8
- **Web Framework**: ASP.NET MVC 5.3.0
- **ORM**: Entity Framework 6.5.1
- **Database**: SQL Server (LocalDB for development)
- **DI Container**: Autofac 8.2.1
- **Authentication**: OWIN + OpenID Connect
- **Logging**: NLog 5.4.0
- **Cloud Services**: AWS SDK (S3, Rekognition, CloudWatch Logs, Systems Manager)

## Target Technology Stack

- **.NET**: 8.0
- **Web Framework**: ASP.NET Core MVC
- **ORM**: Entity Framework Core
- **Database**: PostgreSQL
- **Hosting**: Kestrel on Linux
- **DI Container**: Built-in .NET Core DI
- **Authentication**: ASP.NET Core Identity + OpenID Connect
- **Logging**: ASP.NET Core Logging + AWS integration

## Getting Started with Documentation

For a quick understanding of the system:
1. Start with [System Architecture Overview](./architecture/01-system-architecture.md)
2. Review [Database Schema](./data-layer/01-database-schema.md)
3. Understand [Functional Requirements](./requirements/01-functional-requirements.md)
4. Review [Migration Strategy](./migration-analysis/05-migration-strategy.md) for transformation planning

## Documentation Maintenance

This documentation was generated on: 2025-12-11

For questions or updates, please contact the development team.
