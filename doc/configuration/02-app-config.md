# App.config Settings (Bookstore.Data)

## Entity Framework Configuration

```xml
<entityFramework>
  <providers>
    <provider invariantName="System.Data.SqlClient" 
              type="System.Data.Entity.SqlServer.SqlProviderServices, EntityFramework.SqlServer" />
  </providers>
</entityFramework>
```

Configures SQL Server provider for Entity Framework 6.

## Migration to EF Core

No App.config needed. Configuration in DbContext or appsettings.json.
