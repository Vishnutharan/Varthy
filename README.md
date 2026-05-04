# IMTA vs Monoculture Aquaculture Statistical Analysis

## Overview
Comprehensive R-based statistical analysis comparing **Integrated Multi-Trophic Aquaculture (IMTA)** and **Monoculture** systems for sea cucumber growth and seaweed production.

## Project Structure
- `README.md`: This file.
- `results_analysis_cleaned.xlsx`: Cleaned data with dynamic AGR/SGR.
- `analysis_part1.R`: Growth analysis (Type III ANOVA for unbalanced n).
- `analysis_part2.R`: Water quality, nutrients, and narrative corrections.
- `clean_excel.js`: Utility to generate the cleaned Excel file.
- `result.docx`: Research report (Synchronized with corrected findings).

## Key Improvements & Reproducibility
1. **Unbalanced n**: Handled via Type III ANOVA in `analysis_part1.R` to account for sea cucumber mortality.
2. **Phosphate Contradiction**: The written report and code now correctly conclude that the IMTA ratio was insufficient for phosphate removal.
3. **Nutrient Limitations**: Formally acknowledged the 2-timepoint sampling gap as a study limitation.
4. **Dynamic Data**: Removed all hardcoded AGR/SGR values; they are now calculated in real-time.

## Execution
Run all analysis scripts:
```bash
node clean_excel.js
Rscript analysis_part1.R
Rscript analysis_part2.R
```
