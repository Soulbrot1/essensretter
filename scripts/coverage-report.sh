#!/bin/bash
# Flutter Test Coverage Report Script
# Generates a detailed coverage report and checks minimum thresholds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MIN_COVERAGE=80
MIN_DOMAIN_COVERAGE=90

echo -e "${BLUE}📊 Flutter Test Coverage Report${NC}"
echo "================================"
echo ""

# Run tests with coverage
echo -e "${YELLOW}Running tests with coverage...${NC}"
flutter test --coverage

# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo -e "${YELLOW}Installing lcov...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install lcov
    else
        sudo apt-get install -y lcov
    fi
fi

# Generate HTML report
echo -e "${YELLOW}Generating HTML coverage report...${NC}"
genhtml coverage/lcov.info -o coverage/html

# Get coverage summary
echo ""
echo -e "${BLUE}Coverage Summary:${NC}"
lcov --summary coverage/lcov.info

# Extract overall coverage percentage
COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | sed 's/.*: \([0-9.]*\)%.*/\1/')

echo ""
echo -e "${BLUE}Overall Coverage: ${COVERAGE}%${NC}"

# Check minimum coverage threshold
if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo -e "${RED}❌ Coverage is below minimum threshold of ${MIN_COVERAGE}%${NC}"
    EXIT_CODE=1
else
    echo -e "${GREEN}✅ Coverage meets minimum threshold of ${MIN_COVERAGE}%${NC}"
    EXIT_CODE=0
fi

# Analyze coverage by feature
echo ""
echo -e "${BLUE}Coverage by Feature:${NC}"
echo "--------------------"

for feature_dir in lib/features/*; do
    if [ -d "$feature_dir" ]; then
        feature_name=$(basename "$feature_dir")

        # Filter coverage for this feature
        lcov --extract coverage/lcov.info "*$feature_name*" -o coverage/feature_temp.info 2>/dev/null || continue

        if [ -s coverage/feature_temp.info ]; then
            feature_coverage=$(lcov --summary coverage/feature_temp.info 2>&1 | grep "lines" | sed 's/.*: \([0-9.]*\)%.*/\1/')

            if [ ! -z "$feature_coverage" ]; then
                printf "%-20s: %s%%\n" "$feature_name" "$feature_coverage"

                # Check domain layer coverage
                if [[ "$feature_dir" == *"domain"* ]]; then
                    if (( $(echo "$feature_coverage < $MIN_DOMAIN_COVERAGE" | bc -l) )); then
                        echo -e "  ${YELLOW}⚠️  Domain layer below ${MIN_DOMAIN_COVERAGE}%${NC}"
                    fi
                fi
            fi
        fi
    fi
done

rm -f coverage/feature_temp.info

# Find uncovered files
echo ""
echo -e "${BLUE}Files with Low Coverage (<50%):${NC}"
echo "-------------------------------"

lcov --list coverage/lcov.info | while read line; do
    if [[ $line == *"|"* ]]; then
        file=$(echo $line | cut -d'|' -f1 | xargs)
        coverage=$(echo $line | cut -d'|' -f2 | sed 's/%//' | xargs)

        if [ ! -z "$coverage" ] && [ "$coverage" != "Rate" ]; then
            if (( $(echo "$coverage < 50" | bc -l) )); then
                echo "  $file: $coverage%"
            fi
        fi
    fi
done

# Open HTML report
echo ""
echo -e "${BLUE}Opening HTML report...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open coverage/html/index.html
fi

echo ""
echo -e "${GREEN}Coverage report generated at: coverage/html/index.html${NC}"

# Generate badge
echo ""
echo -e "${BLUE}Generating coverage badge...${NC}"
if (( $(echo "$COVERAGE >= 90" | bc -l) )); then
    BADGE_COLOR="brightgreen"
elif (( $(echo "$COVERAGE >= 80" | bc -l) )); then
    BADGE_COLOR="green"
elif (( $(echo "$COVERAGE >= 70" | bc -l) )); then
    BADGE_COLOR="yellow"
elif (( $(echo "$COVERAGE >= 60" | bc -l) )); then
    BADGE_COLOR="orange"
else
    BADGE_COLOR="red"
fi

echo "Coverage: ${COVERAGE}% - Color: ${BADGE_COLOR}"
echo "Badge URL: https://img.shields.io/badge/coverage-${COVERAGE}%25-${BADGE_COLOR}"

exit $EXIT_CODE
