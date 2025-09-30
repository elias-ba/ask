#!/usr/bin/env bash

# batch-analyze.sh
# Batch analysis of log files with AI-powered insights
# Usage: ./batch-analyze.sh [log-directory] [pattern]

set -e

LOG_DIR="${1:-.}"
PATTERN="${2:-*.log}"
OUTPUT_FILE="analysis-$(date +%Y%m%d-%H%M%S).txt"
MODEL="claude-sonnet-4-5-20250929"
PROVIDER="anthropic"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}Batch Log Analysis${NC}"
echo -e "${CYAN}Directory: ${LOG_DIR}${NC}"
echo -e "${CYAN}Pattern: ${PATTERN}${NC}"
echo -e "${CYAN}Output: ${OUTPUT_FILE}${NC}\n"

if [ ! -d "$LOG_DIR" ]; then
    echo -e "${RED}Error: Directory '$LOG_DIR' does not exist${NC}"
    exit 1
fi

log_files=$(find "$LOG_DIR" -name "$PATTERN" -type f)

if [ -z "$log_files" ]; then
    echo -e "${YELLOW}No log files found matching pattern: $PATTERN${NC}"
    exit 0
fi

file_count=$(echo "$log_files" | wc -l)
echo -e "${GREEN}Found $file_count log files${NC}\n"

{
    echo "Batch Log Analysis Report"
    echo "Generated: $(date)"
    echo "Directory: $LOG_DIR"
    echo "Pattern: $PATTERN"
    echo "=" | awk '{printf "%0.s=", $(seq 1 80)}'; echo
    echo
} > "$OUTPUT_FILE"

file_num=0
for log_file in $log_files; do
    file_num=$((file_num + 1))
    
    echo -e "${BLUE}[$file_num/$file_count] Analyzing: $log_file${NC}"
    
    file_size=$(du -h "$log_file" | cut -f1)
    
    line_count=$(wc -l < "$log_file")
    
    echo -e "${CYAN}  Size: $file_size | Lines: $line_count${NC}"
    
    echo -e "${CYAN}  → Extracting statistics...${NC}"
    
    error_count=$(grep -ci "error" "$log_file" || echo "0")
    warning_count=$(grep -ci "warning" "$log_file" || echo "0")
    critical_count=$(grep -ci "critical\|fatal" "$log_file" || echo "0")
    
    echo -e "${CYAN}  → Errors: $error_count | Warnings: $warning_count | Critical: $critical_count${NC}"
    
    {
        echo
        echo "File: $log_file"
        echo "-" | awk '{printf "%0.s-", $(seq 1 80)}'; echo
        echo "Size: $file_size | Lines: $line_count"
        echo "Errors: $error_count | Warnings: $warning_count | Critical: $critical_count"
        echo
    } >> "$OUTPUT_FILE"
    
    if [ "$line_count" -eq 0 ]; then
        echo -e "${YELLOW}  ⊘ Empty file, skipping${NC}\n"
        echo "Status: Empty file, skipped" >> "$OUTPUT_FILE"
        continue
    fi
    
    if [ "$error_count" -eq 0 ] && [ "$warning_count" -eq 0 ] && [ "$critical_count" -eq 0 ]; then
        echo -e "${GREEN}  ✓ No issues found${NC}\n"
        echo "Status: Clean - no errors or warnings detected" >> "$OUTPUT_FILE"
        continue
    fi
    
    echo -e "${CYAN}  → Running AI analysis...${NC}"
    
    if [ "$line_count" -gt 500 ]; then
        analysis_content=$(tail -500 "$log_file")
        echo -e "${YELLOW}  (Analyzing last 500 lines due to file size)${NC}"
    else
        analysis_content=$(cat "$log_file")
    fi
    
    analysis=$(echo "$analysis_content" | ask -p "$PROVIDER" -m "$MODEL" --no-stream \
        --system "You are a log analysis expert. Analyze logs for:
1. Critical issues and errors
2. Patterns and trends
3. Root causes
4. Actionable recommendations

Be concise and focus on actionable insights." \
        "Analyze this log file. What are the key issues and recommendations?" 2>/dev/null || echo "Analysis failed")
    
    {
        echo "Analysis:"
        echo "$analysis"
        echo
    } >> "$OUTPUT_FILE"
    
    echo -e "${GREEN}  ✓ Analysis complete${NC}\n"
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Generating Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

total_errors=0
total_warnings=0
total_critical=0

for log_file in $log_files; do
    error_count=$(grep -ci "error" "$log_file" || echo "0")
    warning_count=$(grep -ci "warning" "$log_file" || echo "0")
    critical_count=$(grep -ci "critical\|fatal" "$log_file" || echo "0")
    
    total_errors=$((total_errors + error_count))
    total_warnings=$((total_warnings + warning_count))
    total_critical=$((total_critical + critical_count))
done

summary=$(ask -p "$PROVIDER" -m "$MODEL" --no-stream \
    --system "You are a system administrator. Provide an executive summary." \
    "Based on $file_count log files with $total_critical critical issues, $total_errors errors, and $total_warnings warnings, provide:
1. Overall system health assessment
2. Top 3 priorities to address
3. Recommended next actions

Be concise and actionable." 2>/dev/null || echo "Summary generation failed")

{
    echo
    echo "=" | awk '{printf "%0.s=", $(seq 1 80)}'; echo
    echo "EXECUTIVE SUMMARY"
    echo "=" | awk '{printf "%0.s=", $(seq 1 80)}'; echo
    echo
    echo "Files Analyzed: $file_count"
    echo "Total Critical: $total_critical"
    echo "Total Errors: $total_errors"
    echo "Total Warnings: $total_warnings"
    echo
    echo "$summary"
    echo
} >> "$OUTPUT_FILE"

echo -e "${GREEN}✓ Batch analysis complete!${NC}"
echo -e "${BLUE}Files analyzed: $file_count${NC}"
echo -e "${BLUE}Total issues: $((total_critical + total_errors + total_warnings))${NC}"
echo -e "${CYAN}Report saved to: ${BOLD}$OUTPUT_FILE${NC}\n"

echo -e "${YELLOW}View report now? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    if command -v less &> /dev/null; then
        less "$OUTPUT_FILE"
    else
        cat "$OUTPUT_FILE"
    fi
fi
