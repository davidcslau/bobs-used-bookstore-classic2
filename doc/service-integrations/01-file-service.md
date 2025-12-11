# File Service Implementation

## Overview

The file service provides abstraction for file storage with local and AWS S3 implementations.

## Interface (Domain Layer)

```csharp
public interface IFileService
{
    Task<string> SaveAsync(Stream contents, string filename);
    Task DeleteAsync(string filePath);
}
```

## Local Implementation

**Class**: LocalFileService
**Location**: Bookstore.Data/FileServices/LocalFileService.cs

### Configuration
```csharp
var webRootPath = Path.Combine(HttpRuntime.AppDomainAppPath, "Content");
builder.RegisterInstance(new LocalFileService(webRootPath)).As<IFileService>();
```

### SaveAsync
- Generates unique filename
- Saves to Content directory
- Returns relative path (/Content/images/filename.jpg)

### DeleteAsync
- Deletes file from Content directory
- Handles missing files gracefully

## AWS S3 Implementation

**Class**: S3FileService
**Location**: Bookstore.Data/FileServices/S3FileService.cs

### Dependencies
- Amazon.S3 SDK
- IAmazonS3 client

### Configuration
```csharp
builder.RegisterType<AmazonS3Client>().As<IAmazonS3>();
builder.RegisterType<S3FileService>().As<IFileService>();
```

### SaveAsync
- Generates unique filename
- Uploads to S3 bucket
- Returns CloudFront URL (https://cdn.example.com/filename.jpg)

### DeleteAsync
- Deletes object from S3 bucket
- Extracts key from full URL

### AWS Configuration
- **Bucket Name**: From Parameter Store (Files/BucketName)
- **CloudFront Domain**: From Parameter Store (Files/CloudFrontDomain)
- **IAM Permissions**: s3:PutObject, s3:DeleteObject, s3:GetObject

## Usage in Controllers

```csharp
public async Task<ActionResult> UploadImage(HttpPostedFileBase file)
{
    using var stream = file.InputStream;
    var url = await fileService.SaveAsync(stream, file.FileName);
    
    // Save URL to database
    book.CoverImageUrl = url;
}
```

## Migration Considerations

- Strategy pattern already in place
- Can easily add Azure Blob Storage implementation
- Consider using IFormFile (ASP.NET Core) instead of HttpPostedFileBase
