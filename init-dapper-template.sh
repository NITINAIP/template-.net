#!/bin/bash

# ======================================
# TNI DataService Project Creation Script
# ======================================

echo ""
echo "========================================"
echo "TNI DataService Project Creator"
echo "========================================"
echo ""

# Prompt for project name
read -p "Enter project name: " PROJECT_NAME

# Validate project name
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty"
    exit 1
fi

TEMPLATE_REPO="https://github.com/NITINAIP/tni.dataservice.git"
TARGET_DIR="$PROJECT_NAME"

echo "Creating new project: $PROJECT_NAME"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed or not in PATH"
    exit 1
fi

# Check if dotnet is installed
if ! command -v dotnet &> /dev/null; then
    echo "Error: dotnet CLI is not installed or not in PATH"
    exit 1
fi

# Check if directory already exists
if [ -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' already exists"
    exit 1
fi

echo "Step 1: Cloning template repository..."
git clone "$TEMPLATE_REPO" "$TARGET_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone template repository"
    exit 1
fi

cd "$TARGET_DIR" || exit 1

echo ""
echo "Step 2: Removing git history..."
rm -rf .git
if [ $? -ne 0 ]; then
    echo "Warning: Failed to remove .git directory"
fi

echo ""
echo "Step 3: Renaming project files..."

# Rename solution file
if [ -f "tni.dataservices.sln" ]; then
    mv "tni.dataservices.sln" "${PROJECT_NAME}.sln"
    echo "- Renamed solution file"
fi

# Rename API project folder and files
if [ -d "src/API" ]; then
    echo "- Renaming API project..."
    
    # Rename csproj file if exists
    for f in src/API/*.csproj; do
        if [ -f "$f" ]; then
            mv "$f" "src/API/${PROJECT_NAME}.API.csproj"
        fi
    done
    
    # Rename folder
    mv "src/API" "src/${PROJECT_NAME}.API"
fi

# Rename UnitTests project folder and files
if [ -d "tests/UnitTests" ]; then
    echo "- Renaming UnitTests project..."
    
    # Rename csproj file if exists
    for f in tests/UnitTests/*.csproj; do
        if [ -f "$f" ]; then
            mv "$f" "tests/UnitTests/${PROJECT_NAME}.UnitTests.csproj"
        fi
    done
    
    # Rename folder
    mv "tests/UnitTests" "tests/${PROJECT_NAME}.UnitTests"
fi

echo ""
echo "Step 4: Recreating solution file..."

# Delete old solution file
if [ -f "${PROJECT_NAME}.sln" ]; then
    rm "${PROJECT_NAME}.sln"
fi

# Create new solution
dotnet new sln -n "$PROJECT_NAME"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create solution file"
    exit 1
fi
echo "- Created new solution file"

# Add API project to solution
if [ -f "src/${PROJECT_NAME}.API/${PROJECT_NAME}.API.csproj" ]; then
    dotnet sln "${PROJECT_NAME}.sln" add "src/${PROJECT_NAME}.API/${PROJECT_NAME}.API.csproj"
    echo "- Added API project to solution"
fi

# Add UnitTests project to solution
if [ -f "tests/${PROJECT_NAME}.UnitTests/${PROJECT_NAME}.UnitTests.csproj" ]; then
    dotnet sln "${PROJECT_NAME}.sln" add "tests/${PROJECT_NAME}.UnitTests/${PROJECT_NAME}.UnitTests.csproj"
    echo "- Added UnitTests project to solution"
fi

echo ""
echo "Step 5: Updating namespace references in files..."

# Update namespaces in .cs files
find . -type f -name "*.cs" -exec sed -i.bak "s/tni\.dataservice/$PROJECT_NAME/g" {} \;
find . -type f -name "*.cs" -exec sed -i.bak "s/tni\.dataservices/$PROJECT_NAME/g" {} \;

# Update namespaces in .csproj files
find . -type f -name "*.csproj" -exec sed -i.bak "s/tni\.dataservice/$PROJECT_NAME/g" {} \;
find . -type f -name "*.csproj" -exec sed -i.bak "s/tni\.dataservices/$PROJECT_NAME/g" {} \;

# Remove backup files created by sed
find . -type f -name "*.bak" -delete

echo "- Updated namespaces in all files"

echo ""
echo "Step 6: Initializing new git repository..."
git init
git add .
git commit -m "Initial commit from tni.dataservice template"

echo ""
echo "========================================"
echo "Project created successfully!"
echo "========================================"
echo ""
echo "Project location: $(pwd)"
echo "Solution file: ${PROJECT_NAME}.sln"
echo ""
echo "Next steps:"
echo "1. Open ${PROJECT_NAME}.sln in Visual Studio or Rider"
echo "2. Review and update the README.md file"
echo "3. Configure your project settings"
echo "4. Start coding!"
echo ""
echo "To build the project:"
echo "  dotnet build"
echo ""
echo "To run the API:"
echo "  dotnet run --project src/${PROJECT_NAME}.API"
echo ""
echo "To run tests:"
echo "  dotnet test"
echo ""

cd ..