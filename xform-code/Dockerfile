# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files
COPY ["BobsBookstoreClassic.sln", "./"]
COPY ["app/Bookstore.Web/Bookstore.Web.csproj", "app/Bookstore.Web/"]
COPY ["app/Bookstore.Data/Bookstore.Data.csproj", "app/Bookstore.Data/"]
COPY ["app/Bookstore.Domain/Bookstore.Domain.csproj", "app/Bookstore.Domain/"]
COPY ["app/Bookstore.Common/Bookstore.Common.csproj", "app/Bookstore.Common/"]
COPY ["app/Bookstore.Cdk/Bookstore.Cdk.csproj", "app/Bookstore.Cdk/"]

# Restore dependencies
RUN dotnet restore "app/Bookstore.Web/Bookstore.Web.csproj"

# Copy everything else
COPY . .

# Build and publish
WORKDIR "/src/app/Bookstore.Web"
RUN dotnet build "Bookstore.Web.csproj" -c Release -o /app/build
RUN dotnet publish "Bookstore.Web.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Install PostgreSQL client for debugging (optional)
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=build /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

# Expose port
EXPOSE 80

# Run the application
ENTRYPOINT ["dotnet", "Bookstore.Web.dll"]
