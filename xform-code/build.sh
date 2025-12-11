#!/bin/bash

echo "=== Building Bob's Bookstore (.NET 8.0) ==="

# Build Domain Layer
echo ""
echo "Building Bookstore.Domain..."
cd Bookstore.Domain
dotnet build -c Release
if [ $? -ne 0 ]; then
    echo "Error building Bookstore.Domain"
    exit 1
fi
cd ..

# Build Data Layer
echo ""
echo "Building Bookstore.Data..."
cd Bookstore.Data
dotnet build -c Release
if [ $? -ne 0 ]; then
    echo "Error building Bookstore.Data"
    exit 1
fi
cd ..

# Build Web Layer
echo ""
echo "Building Bookstore.Web..."
cd Bookstore.Web
dotnet build -c Release
if [ $? -ne 0 ]; then
    echo "Error building Bookstore.Web"
    exit 1
fi
cd ..

echo ""
echo "=== Build completed successfully! ==="
