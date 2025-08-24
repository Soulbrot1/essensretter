#!/bin/bash
# Flutter Pre-Commit Hook Script
# This script runs Flutter-specific checks before allowing a commit

set -e

echo "🔍 Running Flutter pre-commit checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we have Dart files to commit
if git diff --cached --name-only | grep -q '\.dart$'; then

    echo "📝 Checking code formatting..."
    if ! dart format --set-exit-if-changed lib/ test/; then
        echo -e "${RED}❌ Code formatting issues found!${NC}"
        echo "Run 'dart format lib/ test/' to fix formatting"
        exit 1
    fi
    echo -e "${GREEN}✅ Code formatting check passed${NC}"

    echo "🔬 Running static analysis..."
    if ! flutter analyze; then
        echo -e "${RED}❌ Static analysis found issues!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Static analysis passed${NC}"

    echo "🧪 Running tests..."
    if ! flutter test; then
        echo -e "${RED}❌ Tests failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ All tests passed${NC}"

    echo "🔎 Checking for debug print statements..."
    if grep -r "print(" lib/ --include="*.dart" | grep -v "// ignore:"; then
        echo -e "${YELLOW}⚠️  Found print statements in code${NC}"
        echo "Consider using proper logging instead of print statements"
        read -p "Continue with commit anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    echo -e "${GREEN}🎉 All pre-commit checks passed!${NC}"
else
    echo "No Dart files to check, skipping Flutter checks"
fi
