# IMTA vs Monoculture Aquaculture Statistical Analysis

## Overview
Comprehensive R-based statistical analysis comparing **Integrated Multi-Trophic Aquaculture (IMTA)** and **Monoculture** systems for sea cucumber growth and seaweed production.

## Project Structure
- `README.md`: This file.
- `scripts/generate_study_area_map.js`: Generates the study-area map from coordinates.
- `assets/study_area_map.svg`: Code-generated study-area map with a square marker at the sample collection location.
- `results_analysis_cleaned.xlsx`: Cleaned data with dynamic AGR/SGR.
- `analysis_part1.R`: Growth analysis (Type III ANOVA for unbalanced n).
- `analysis_part2.R`: Water quality, nutrients, and narrative corrections.
- `clean_excel.js`: Utility to generate the cleaned Excel file.
- `result.docx`: Research report (Synchronized with corrected findings).

## Study Area
Samples were collected from the coastal waters of the Jaffna Peninsula, Sri Lanka, associated with the Palk Strait near Velanai/Thurayoor, Jaffna. The specific sampling position is shown with a square marker at approximately `9°40'01.6"N, 80°01'52.9"E` (`9.6671°N, 80.0314°E`). The broader study area is within the northern coastal region of Sri Lanka, approximately `79.50°E-81.25°E` and `9.25°N-10.00°N`.

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
