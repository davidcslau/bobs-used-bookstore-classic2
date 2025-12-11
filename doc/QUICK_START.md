# Quick Start Guide - Bob's Used Bookstore Documentation

**For:** Engineering teams new to the codebase  
**Time to Read:** 10 minutes  
**Documentation Location:** `/doc/` directory

---

## 🚀 5-Minute Overview

### What is This Application?
Bob's Used Bookstore Classic is an e-commerce web application for buying and selling used books. Built with .NET Framework 4.8, ASP.NET MVC 5, and SQL Server.

### Key Features
- 📚 Browse and search books
- 🛒 Shopping cart and wishlist
- 💳 Order processing and tracking
- ♻️ Sell used books back to store (offers)
- 👨‍💼 Admin inventory and order management

### Architecture
```
Bookstore.Web (MVC 5) → Bookstore.Domain (Business Logic) → Bookstore.Data (EF 6.5.1) → SQL Server
```

---

## 📖 Reading Guide by Role

### New Developer (Day 1)
**Time: 30-45 minutes**

1. **README.md** (5 min) - Overview and navigation
2. **01-architecture-overview.md** (10 min) - Understanding the structure
3. **07-reverse-engineered-requirements.md** (15 min) - Business context
4. **02-domain-model-documentation.md** (10 min) - Core entities

**Result:** Understanding of what the app does and how it's structured

---

### Backend Developer
**Time: 1-2 hours**

1. **02-domain-model-documentation.md** (20 min) - Entities and business logic
2. **03-data-access-layer-documentation.md** (30 min) - Repositories and EF
3. **05-database-schema-documentation.md** (20 min) - Database structure
4. **04-web-layer-api-documentation.md** (30 min) - Controllers and APIs

**Result:** Ready to work on backend features

---

### Frontend Developer
**Time: 45 minutes**

1. **04-web-layer-api-documentation.md** (30 min) - Controllers and views
2. **07-reverse-engineered-requirements.md** (15 min) - User workflows

**Result:** Understanding of routes, views, and user flows

---

### Migration Team Lead
**Time: 2-3 hours**

1. **01-architecture-overview.md** (15 min) - Current architecture
2. **08-reverse-engineered-technical-specification.md** (30 min) - Technical details
3. **09-migration-considerations.md** (90 min) - Migration guide
4. **06-dependencies-and-packages-inventory.md** (30 min) - Packages

**Result:** Complete migration strategy and timeline

---

### Database Administrator
**Time: 45 minutes**

1. **05-database-schema-documentation.md** (30 min) - Schema and relationships
2. **03-data-access-layer-documentation.md** (15 min) - EF mappings
3. **09-migration-considerations.md** (read PostgreSQL sections)

**Result:** Database migration plan

---

### QA Engineer
**Time: 1 hour**

1. **07-reverse-engineered-requirements.md** (45 min) - All features and workflows
2. **04-web-layer-api-documentation.md** (15 min) - Endpoints

**Result:** Test plan and scenarios

---

### Architect
**Time: 1.5 hours**

1. **01-architecture-overview.md** (20 min) - Architecture patterns
2. **08-reverse-engineered-technical-specification.md** (40 min) - Technical decisions
3. **09-migration-considerations.md** (30 min) - Migration strategy

**Result:** Understanding of architecture and modernization path

---

## 🎯 Common Questions Answered

### "What does this application do?"
→ Read **07-reverse-engineered-requirements.md** Section 1-2

### "How is the code organized?"
→ Read **01-architecture-overview.md** Section 3

### "What are the main entities?"
→ Read **02-domain-model-documentation.md** Section 2

### "How do I find a specific controller?"
→ Read **04-web-layer-api-documentation.md** Section 2

### "What's in the database?"
→ Read **05-database-schema-documentation.md** Section 2

### "What packages are used?"
→ Read **06-dependencies-and-packages-inventory.md**

### "How do I migrate to .NET Core?"
→ Read **09-migration-considerations.md** (complete guide)

### "How does authentication work?"
→ Read **04-web-layer-api-documentation.md** Section 4

### "What are the business rules?"
→ Read **02-domain-model-documentation.md** Section 6 and **07-reverse-engineered-requirements.md** Section 5

---

## 📊 Quick Stats

| Metric | Value |
|--------|-------|
| Controllers | 14 (9 customer + 5 admin) |
| Domain Entities | 12 |
| Database Tables | 9 |
| NuGet Packages | 57 |
| User Roles | 3 (Anonymous, Customer, Admin) |
| Major Features | 14 |

---

## 🔍 Find Information Fast

### Code Location
```
/projects/sandbox/bobs-used-bookstore-classic2/
├── app/                          ← Source code
│   ├── Bookstore.Domain/        ← Business logic
│   ├── Bookstore.Data/          ← Data access
│   └── Bookstore.Web/           ← Web layer
├── db-scripts/                   ← Database scripts
└── doc/                          ← Documentation (you are here)
```

### Key Files in Codebase
- **ApplicationDbContext.cs** - EF DbContext
- **RouteConfig.cs** - URL routing
- **Web.config** - Configuration
- **Controllers/** - All HTTP endpoints
- **Views/** - Razor templates

---

## 🚨 Important Notes

### Before Making Changes
1. Read the relevant documentation section
2. Understand the architecture layer
3. Check business rules
4. Review existing patterns

### Authentication Modes
- **Local Mode** (Development) - Hardcoded credentials
- **AWS Mode** (Production) - Cognito integration

### Configuration
- Development: Web.config
- Production: AWS Systems Manager Parameter Store

---

## 🎓 Learning Path

### Week 1: Understanding
- Day 1-2: Read architecture and requirements docs
- Day 3-4: Study domain and data layers
- Day 5: Explore web layer and UI

### Week 2: Hands-On
- Day 1-2: Set up development environment
- Day 3-4: Make small changes with guidance
- Day 5: Work on real tasks

---

## 📞 Getting Help

### Can't Find Information?
1. Check the documentation README.md index
2. Use search in your text editor (grep/find)
3. Review the table of contents in each doc
4. Check inline code comments

### Found Issues in Documentation?
- Update the relevant .md file
- Keep documentation in sync with code
- Add clarifications as you learn

---

## ✅ Quick Checklist

### Before Starting Development
- [ ] Read architecture overview
- [ ] Understand domain model
- [ ] Review business rules
- [ ] Set up development environment
- [ ] Understand authentication mode

### Before Migration
- [ ] Read complete migration guide
- [ ] Review all breaking changes
- [ ] Understand package changes
- [ ] Plan database migration
- [ ] Set up test environment

---

## 🔗 Document Cross-Reference

| If you want to... | Read this document |
|-------------------|--------------------|
| Understand architecture | 01-architecture-overview.md |
| Learn domain entities | 02-domain-model-documentation.md |
| Work with database | 03-data-access-layer-documentation.md |
| Modify controllers | 04-web-layer-api-documentation.md |
| Change database schema | 05-database-schema-documentation.md |
| Update packages | 06-dependencies-and-packages-inventory.md |
| Understand features | 07-reverse-engineered-requirements.md |
| Deploy application | 08-reverse-engineered-technical-specification.md |
| Plan migration | 09-migration-considerations.md |

---

## 🎯 Success Criteria

You're ready to work on the codebase when you can answer:
1. What are the three main layers?
2. What are the core domain entities?
3. How does authentication work?
4. Where are controllers defined?
5. What database tables exist?

---

**Happy Learning! 🚀**

For detailed information, navigate to specific documentation files in the `/doc/` directory.
