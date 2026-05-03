# run_all.R
# This script executes the entire data analysis pipeline in the correct sequence.
# It ensures reproducibility by running all components from raw data to final plots.

cat("Starting Aquaculture Data Analysis Pipeline...\n")
cat("==============================================\n")

# Part 0: Data Cleaning
cat("\n[0/5] Running Part 0: Extracting and Cleaning Raw Data...\n")
source("data_cleaning.R")

# Part 1: Sea cucumber growth analysis, normality, t-tests, predictions
cat("\n[1/5] Running Part 1: Sea Cucumber Growth Analysis...\n")
source("analysis_part1.R")

# Part 2: Seaweed biomass, water quality, nutrients, and soil
cat("\n[2/5] Running Part 2: Environmental and Biomass Analysis...\n")
source("analysis_part2.R")

# Part 3: Generating primary visualization plots
cat("\n[3/5] Generating Primary Plots...\n")
source("analysis_plots.R")

# Part 4: Enhanced analysis (power analysis, P anomaly, correlations)
cat("\n[4/5] Running Enhanced Statistical Analysis...\n")
source("enhanced_analysis.R")

# Part 5: Generating enhanced visualization plots
cat("\n[5/5] Generating Enhanced Plots...\n")
source("enhanced_plots.R")

cat("\n==============================================\n")
cat("PIPELINE COMPLETE! All results are saved in the 'R_output/' directory.\n")
