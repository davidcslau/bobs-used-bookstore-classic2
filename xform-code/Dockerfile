# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["Bookstore.Domain/Bookstore.Domain.csproj", "Bookstore.Domain/"]
COPY ["Bookstore.Data/Bookstore.Data.csproj", "Bookstore.Data/"]
COPY ["Bookstore.Web/Bookstore.Web.csproj", "Bookstore.Web/"]

# Restore dependencies
RUN dotnet restore "Bookstore.Web/Bookstore.Web.csproj"

# Copy all source files
COPY . .

# Build the application
WORKDIR "/src/Bookstore.Web"
RUN dotnet build "Bookstore.Web.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Bookstore.Web.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Install PostgreSQL client libraries (for Npgsql)
RUN apt-get update && apt-get install -y libgdiplus libc6-dev && rm -rf /var/lib/apt/lists/*

COPY --from=publish /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "Bookstore.Web.dll"]
