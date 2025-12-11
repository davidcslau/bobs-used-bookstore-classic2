# Bob's Used Bookstore Classic - Technical Documentation

**Application:** Bob's Used Bookstore Classic  
**Version:** 1.0  
**Framework:** .NET Framework 4.8  
**Database:** SQL Server  
**Documentation Date:** December 11, 2024

---

## Overview

This directory contains comprehensive technical documentation for Bob's Used Bookstore Classic, an ASP.NET MVC 5 e-commerce application built on .NET Framework 4.8. The documentation has been reverse-engineered from the codebase to support understanding, maintenance, and future migration to .NET Core 8.0 and PostgreSQL.

---

## Documentation Structure

### 01. Architecture Overview
**File:** `01-architecture-overview.md`

**Contents:**
- Executive summary of the application
- Solution architecture and project structure
- Architectural patterns (Layered, Repository, Service Layer, MVC)
- Technology stack inventory
- Deployment architectures (Development, AWS ECS, Windows Server/IIS)
- Security architecture

**Audience:** Technical leads, architects, developers

---

### 02. Domain Model Documentation
**File:** `02-domain-model-documentation.md`

**Contents:**
- All domain entities with properties and relationships
- Entity relationship diagrams
- Domain services and interfaces
- Data Transfer Objects (DTOs)
- Business rules and constraints
- Domain-driven design concepts

**Key Entities:**
- Book, Customer, Order, OrderItem
- ShoppingCart, ShoppingCartItem
- Offer, Address, ReferenceData

**Audience:** Developers, business analysts

---

### 03. Data Access Layer Documentation
**File:** `03-data-access-layer-documentation.md`

**Contents:**
- ApplicationDbContext configuration
- Repository pattern implementation
- Entity Framework 6.5.1 mappings and configurations
- Database schema details
- Supporting services (File, Image processing)
- Performance considerations

**Audience:** Database administrators, backend developers

---

### 04. Web Layer and API Documentation
**File:** `04-web-layer-api-documentation.md`

**Contents:**
- All controllers (9 customer-facing, 5 admin)
- Routing configuration
- Authentication and authorization
- MVC Areas (Admin)
- Views and Razor templates
- Custom helpers and validation attributes

**Key Controllers:**
- SearchController, ShoppingCartController, CheckoutController
- OrdersController, ResaleController
- Admin: InventoryController, OrdersController, OffersController

**Audience:** Full-stack developers, frontend developers

---

### 05. Database Schema Documentation
**File:** `05-database-schema-documentation.md`

**Contents:**
- Complete database schema (9 tables)
- Table structures with columns and data types
- Relationships and foreign keys
- Indexes and constraints
- Seed data
- Migration to PostgreSQL considerations

**Audience:** Database administrators, data engineers

---

### 06. Dependencies and Packages Inventory
**File:** `06-dependencies-and-packages-inventory.md`

**Contents:**
- Complete NuGet package inventory (57 packages)
- Package categories and purposes
- Version information
- Dependency trees
- Package sizes
- Migration equivalents for .NET Core

**Key Dependencies:**
- Entity Framework 6.5.1
- ASP.NET MVC 5.3.0
- Autofac 8.2.1
- AWS SDK packages
- Magick.NET 14.6.0

**Audience:** DevOps, developers, architects

---

### 07. Reverse-Engineered Requirements
**File:** `07-reverse-engineered-requirements.md`

**Contents:**
- Business requirements
- Functional requirements (14 major features)
- User roles and permissions
- Business rules
- User workflows
- Non-functional requirements

**Key Features:**
- Book browsing and search
- Shopping cart and wishlist
- Checkout and order processing
- Book resale offers
- Inventory management (admin)
- Order management (admin)

**Audience:** Business analysts, product managers, QA engineers

---

### 08. Reverse-Engineered Technical Specification
**File:** `08-reverse-engineered-technical-specification.md`

**Contents:**
- Technical architecture details
- Technology stack specifications
- Database design
- API contracts and interfaces
- Authentication mechanisms (Local, AWS Cognito)
- File storage (Local, AWS S3)
- Configuration management
- Logging and monitoring
- Deployment architectures

**Audience:** Technical leads, DevOps engineers, architects

---

### 09. Migration Considerations
**File:** `09-migration-considerations.md`

**Contents:**
- Migration from .NET Framework 4.8 to .NET Core 8.0
- Migration from SQL Server to PostgreSQL
- Breaking changes and challenges
- Detailed migration strategy (5 phases)
- Testing requirements
- Risk assessment
- Cost analysis
- Rollback plan

**Key Sections:**
- ASP.NET MVC 5 → ASP.NET Core MVC changes
- Entity Framework 6 → Entity Framework Core changes
- SQL Server → PostgreSQL data type mappings
- OWIN → ASP.NET Core middleware
- Estimated timeline: 4-6 weeks

**Audience:** Migration team, architects, technical leads

---

## Documentation Purpose

### Primary Goals

1. **Knowledge Transfer**
   - Comprehensive understanding of codebase
   - Enable new team members to onboard quickly
   - Preserve architectural decisions and patterns

2. **Migration Support**
   - Document current state for .NET Core migration
   - Identify challenges and breaking changes
   - Provide migration roadmap

3. **Maintenance and Development**
   - Reference for bug fixes and enhancements
   - Guide for adding new features
   - Understanding business logic and rules

4. **Deployment and Operations**
   - Deployment procedures
   - Configuration management
   - Troubleshooting guide

---

## How to Use This Documentation

### For New Team Members
**Start here:**
1. Read `01-architecture-overview.md` - Get overall picture
2. Read `07-reverse-engineered-requirements.md` - Understand business requirements
3. Read `02-domain-model-documentation.md` - Learn domain concepts
4. Explore specific areas based on your role

### For Migration Team
**Start here:**
1. Read `09-migration-considerations.md` - Migration strategy
2. Review `06-dependencies-and-packages-inventory.md` - Package updates
3. Study `03-data-access-layer-documentation.md` - EF changes
4. Review `04-web-layer-api-documentation.md` - MVC changes

### For Maintenance Developers
**Reference as needed:**
- Controller implementation: `04-web-layer-api-documentation.md`
- Database changes: `05-database-schema-documentation.md`
- Business rules: `02-domain-model-documentation.md`
- Deployment: `08-reverse-engineered-technical-specification.md`

### For Architects and Technical Leads
**Strategic view:**
1. `01-architecture-overview.md` - Architecture patterns
2. `08-reverse-engineered-technical-specification.md` - Technical decisions
3. `09-migration-considerations.md` - Future planning
4. `06-dependencies-and-packages-inventory.md` - Technology choices

---

## Application Summary

**Bob's Used Bookstore Classic** is a full-featured e-commerce web application for buying and selling used books. Built on proven Microsoft technologies (.NET Framework 4.8, ASP.NET MVC 5, Entity Framework 6, SQL Server), it demonstrates solid architectural principles and design patterns.

### Key Features
- 📚 Book catalog with search and filtering
- 🛒 Shopping cart and wishlist
- 💳 Checkout and order processing
- 📦 Order tracking and history
- ♻️ Customer book resale program
- 👨‍💼 Admin inventory management
- 📊 Admin dashboard with statistics

### Technical Highlights
- **Architecture:** 3-tier layered with clear separation of concerns
- **Patterns:** Repository, Service Layer, Dependency Injection, MVC
- **Security:** OWIN authentication, Cognito integration, HTTPS
- **Cloud-Ready:** AWS integrations (S3, Rekognition, Cognito, CloudWatch)
- **Deployment:** Windows Server/IIS or AWS ECS with containers

### Statistics
- **Projects:** 5 (.NET projects + CDK)
- **Controllers:** 14 (9 customer + 5 admin)
- **Domain Entities:** 12
- **Database Tables:** 9
- **NuGet Packages:** 57
- **Lines of Code:** ~10,000+ (estimated)

---

## Additional Resources

### Code Locations
- **Source Code:** `/projects/sandbox/bobs-used-bookstore-classic2/app/`
- **Solution File:** `BobsBookstoreClassic.sln`
- **Database Scripts:** `/projects/sandbox/bobs-used-bookstore-classic2/db-scripts/`
- **Documentation:** `/projects/sandbox/bobs-used-bookstore-classic2/doc/` (this directory)

### External References
- [.NET Framework 4.8 Documentation](https://docs.microsoft.com/en-us/dotnet/framework/)
- [ASP.NET MVC 5 Documentation](https://docs.microsoft.com/en-us/aspnet/mvc/overview/getting-started/introduction/)
- [Entity Framework 6 Documentation](https://docs.microsoft.com/en-us/ef/ef6/)
- [AWS SDK for .NET](https://aws.amazon.com/sdk-for-net/)

---

## Contributing to Documentation

### Documentation Standards
- Use Markdown format (.md)
- Include table of contents for long documents
- Use code blocks with syntax highlighting
- Include diagrams where helpful (ASCII art is fine)
- Keep line length reasonable (~100-120 characters)
- Use clear headings and sections

### Updating Documentation
When making code changes, update relevant documentation:
- New features → Update requirements and functional specs
- Architecture changes → Update architecture overview
- Database changes → Update schema documentation
- API changes → Update web layer documentation
- Package changes → Update dependencies inventory

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-12-11 | System | Initial comprehensive documentation generated from codebase analysis |

---

## Contact and Support

For questions about this documentation or the application:
- Review the specific documentation files for detailed information
- Refer to inline code comments in the source code
- Check Git commit history for change rationale

---

## Next Steps

### Immediate Actions
1. ✅ Documentation complete and comprehensive
2. ⏭️ Review documentation with team
3. ⏭️ Plan migration phases
4. ⏭️ Set up .NET Core 8 development environment
5. ⏭️ Begin Phase 1 of migration

### Future Documentation Needs
- API documentation (if REST API is added)
- Deployment runbooks
- Troubleshooting guides
- Performance tuning guides
- Security audit documentation

---

**End of Documentation Index**
