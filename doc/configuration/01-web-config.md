# Web.config Analysis

## Structure

The Web.config file configures ASP.NET MVC application settings, connection strings, and system settings.

## Key Sections

### Connection Strings
```xml
<connectionStrings>
  <add name="BookstoreDatabaseConnection" 
       connectionString="Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;MultipleActiveResultSets=true;Integrated Security=SSPI;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

### App Settings
```xml
<appSettings>
  <add key="Environment" value="Development" />
  <add key="Services/Authentication" value="local" />
  <add key="Services/Database" value="local" />
  <add key="Services/FileService" value="local" />
  <add key="Services/ImageValidationService" value="local" />
  <add key="Services/LoggingService" value="local" />
</appSettings>
```

**Service Modes**: "local" or "aws"

### System.Web
```xml
<system.web>
  <compilation debug="true" targetFramework="4.8" />
  <httpRuntime targetFramework="4.8" />
</system.web>
```

### Assembly Binding Redirects
Required for resolving version conflicts:
```xml
<dependentAssembly>
  <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" />
  <bindingRedirect oldVersion="0.0.0.0-13.0.0.0" newVersion="13.0.0.0" />
</dependentAssembly>
```

## Migration to appsettings.json

ASP.NET Core equivalent:
```json
{
  "ConnectionStrings": {
    "BookstoreDatabaseConnection": "..."
  },
  "Environment": "Development",
  "Services": {
    "Authentication": "local",
    "FileService": "local"
  }
}
```
