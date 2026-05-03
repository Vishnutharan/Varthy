# IMTA vs Monoculture Aquaculture Statistical Analysis

## Overview
Comprehensive R-based statistical analysis comparing **Integrated Multi-Trophic Aquaculture (IMTA)** and **Monoculture** systems for sea cucumber (*Holothuria scabra*) growth performance, seaweed (*Kappaphycus alvarezii*) biomass production, water quality dynamics, and nutrient cycling.

## Project Structure
```
Varthy/
├── README.md
├── data sheet.xlsx          # Raw experimental data (water quality, growth metrics)
├── results analysis.xlsx    # Summary statistical tables
├── result.docx              # Research report documentation
├── csv_data/                # Exported CSV files for R processing
├── R Scripts:
│   ├── analysis_part1.R     # Sea cucumber growth: normality, t-tests, predictions
│   ├── analysis_part2.R     # Seaweed, water quality, nutrients, soil analysis
│   ├── analysis_plots.R     # 9 publication-quality visualizations
│   ├── enhanced_analysis.R  # Power analysis, P anomaly, env correlations
│   └── enhanced_plots.R     # 6 enhanced diagnostic plots
├── R_output/
│   ├── analysis_results.txt     # Core statistical results
│   ├── enhanced_analysis.txt    # Enhanced analysis results
│   └── *.png                    # 15 publication-quality plots (300 DPI)
└── Utility Scripts:
    ├── export_csv.js        # Excel to CSV converter
    ├── read_data.js         # Data exploration
    ├── read_datasheet.js    # Data sheet reader
    ├── read_results.js      # Results reader
    └── read_doc.js          # Document extractor
```

## Statistical Methods
- **Normality**: Shapiro-Wilk, Anderson-Darling tests
- **Parametric**: Welch's t-test, paired t-tests, ANOVA, Tukey HSD
- **Non-parametric**: Mann-Whitney U, Kruskal-Wallis, Spearman rank
- **Regression**: Linear, polynomial (2nd order), multiple regression
- **Power Analysis**: Sample size estimation for future studies
- **Effect Size**: Cohen's d, Coefficient of Variation (CV)

## Key Findings

### Sea Cucumber Growth
- IMTA mean weight: **328.05g** vs Mono: **299.72g** (p=0.1695)
- IMTA growth is **more stable** (CV: 14.3% vs 18.1%)
- **Exploratory Prediction**: Week 12 weight forecast suggests IMTA **531g** vs Mono **330g**, however, 95% prediction intervals are very wide (e.g. IMTA 144–919g), meaning this projection should be treated as a theoretical trajectory rather than a strong forecast.
- Current study is **underpowered** (power=0.206); need n=249/group or extend to Week 12

### Phosphorus Anomaly
- IMTA R2 replicate identified as **major outlier** inflating P values
- Genuine P accumulation confirmed even after outlier removal (+115%)
- Current seaweed:cucumber ratio (**0.14:1**) insufficient for bio-filtration
- **Recommendation**: Increase seaweed density by 250% (ratio to 0.50:1)

### Environmental Resilience
- Week 4: Monoculture crashed **-138g** while IMTA lost only **-11g**
- IMTA demonstrates **12x greater environmental resilience**
- Temperature spike (+2.56°C) was the primary stress driver

## Plots Generated (15 total)
1. Sea cucumber weight trends
2. Sea cucumber length trends
3. Body weight boxplot with t-test
4. Absolute Growth Rate comparison
5. Water quality 4-panel (pH, DO, Salinity, TDS)
6. Nutrient dynamics (Nitrite & Phosphorus)
7. Growth prediction with 95% CI
8. Q-Q normality plots
9. Seaweed biomass comparison
10. Salinity vs weight correlation
11. Temperature vs weight correlation
12. Phosphorus anomaly replicate breakdown
13. Statistical power curve
14. Correlation heatmap
15. Week 4 growth crash analysis

## Limitations
- **High Individual Variance**: Sea cucumber growth showed high individual variability, leading to non-significant p-values despite observable positive trends in the IMTA system.
- **Short Duration**: A 5-week monitoring period for sea cucumber growth may be insufficient to fully capture divergent growth trajectories.
- **Prediction Uncertainty**: The polynomial and linear regression predictions for Week 12 have very wide confidence intervals due to small sample sizes and high variance. These should be interpreted as exploratory models only.

## Requirements
- **R** ≥ 4.6.0
- R packages: `ggplot2`, `dplyr`, `tidyr`, `readxl`, `car`, `moments`, `nortest`, `agricolae`, `emmeans`, `ggpubr`, `lme4`

## How to Run
```r
# The easiest way is to run the master script from the terminal:
Rscript run_all.R

# Alternatively, run them step-by-step:
Rscript analysis_part1.R
Rscript analysis_part2.R
Rscript analysis_plots.R
Rscript enhanced_analysis.R
Rscript enhanced_plots.R
```

## Author
Varthy - Aquaculture Research Project
