# Image Resize Service

## Overview

Resizes uploaded images to standard dimensions for consistent display.

## Interface

```csharp
public interface IImageResizeService
{
    Task<Stream> ResizeImageAsync(Stream imageStream, int width, int height);
}
```

## Implementation

**Class**: ImageResizeService
**Location**: Bookstore.Data/ImageResizeService/ImageResizeService.cs

### Features
- Resize to specified dimensions
- Maintain aspect ratio option
- Quality compression

### Usage
```csharp
var resizedStream = await imageResizeService.ResizeImageAsync(
    originalStream, 
    width: 400, 
    height: 600);
```

## Configuration
- Standard sizes: 400x600 for book covers
- Thumbnail: 100x150
- Quality: 85%
