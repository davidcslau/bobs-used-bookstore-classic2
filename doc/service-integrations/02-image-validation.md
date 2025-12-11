# Image Validation Service

## Overview

Validates uploaded images for content appropriateness with local and AWS Rekognition implementations.

## Interface

```csharp
public interface IImageValidationService
{
    Task<bool> ValidateImageAsync(Stream imageStream);
}
```

## Local Implementation

**Class**: LocalImageValidationService

### Validation
- Basic file format check
- File size validation
- Always returns true (no content moderation)

## AWS Rekognition Implementation

**Class**: RekognitionImageValidationService

### Features
- Content moderation using AWS Rekognition
- Detects inappropriate content
- Configurable confidence threshold

### AWS Configuration
- **Service**: Amazon Rekognition
- **IAM Permissions**: rekognition:DetectModerationLabels

### Validation Process
1. Upload image to Rekognition
2. Analyze for inappropriate content
3. Return false if confidence > threshold

## Usage
```csharp
var isValid = await imageValidationService.ValidateImageAsync(imageStream);
if (!isValid)
{
    return BadRequest("Image contains inappropriate content");
}
```
