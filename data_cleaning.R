# data_cleaning.R
# This script extracts raw data directly from the original Excel files and structures it
# into clean, analysis-ready CSV files. It ensures full transparency and reproducibility
# from the source data to the final statistical results without any manual scaling or hardcoding.

dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(readxl)
library(dplyr)
library(tidyr)

dir.create("csv_data", showWarnings=FALSE)
cat("Starting data cleaning pipeline...\n")

# ---------------------------------------------------------
# 1. SEA CUCUMBER GROWTH DATA
# ---------------------------------------------------------
cat("Extracting Sea Cucumber growth data...\n")
sc_raw <- read_excel("results analysis.xlsx", sheet="sea cucumber growth ", col_names=FALSE)

# IMTA data is in columns 2 (Weight) and 3 (Length). Monoculture is in 6 (Weight) and 7 (Length)
# We filter out rows that contain summary labels ("Mean", "SD", "weeks", "sea cucumber") in column 1 or 5
imta_clean <- sc_raw %>%
  filter(!is.na(...1)) %>%
  filter(!grepl("Mean|SD|weeks|sea cucumber", ...1, ignore.case=TRUE)) %>%
  mutate(
    Weight = as.numeric(...2),
    Length = as.numeric(...3),
    Treatment = "IMTA"
  ) %>%
  filter(!is.na(Weight)) %>%
  select(Treatment, Weight, Length)

mono_clean <- sc_raw %>%
  filter(!is.na(...5)) %>%
  filter(!grepl("Mean|SD|weeks|sea cucumber", ...5, ignore.case=TRUE)) %>%
  mutate(
    Weight = as.numeric(...6),
    Length = as.numeric(...7),
    Treatment = "Monoculture"
  ) %>%
  filter(!is.na(Weight)) %>%
  select(Treatment, Weight, Length)

sc_combined <- bind_rows(imta_clean, mono_clean)
write.csv(sc_combined, "csv_data/sea_cucumber_individual.csv", row.names=FALSE)

# ---------------------------------------------------------
# 2. SEAWEED BIOMASS DATA
# ---------------------------------------------------------
cat("Extracting Seaweed biomass data...\n")
sw_raw <- read_excel("results analysis.xlsx", sheet="sea weed growth ", col_names=FALSE)

# Replicate 1 is in cols 2 (Initial) and 5 (Final)
# Replicate 2 is in cols 9 (Initial) and 12 (Final)
# Replicate 3 is in cols 16 (Initial) and 19 (Final)
# Each replicate has 3 ropes (R1, R2, R3) of 10 seedlings, meaning 30 seedlings per replicate.

extract_seaweed <- function(data, init_col, final_col, rep_name) {
  # Filter rows that contain "S" in the first column of the block (e.g., "R1 S1")
  # For Replicate 1, labels are in col 1; Rep 2 in col 8; Rep 3 in col 15
  label_col <- init_col - 1
  
  clean_data <- data %>%
    filter(!is.na(.[[label_col]])) %>%
    filter(grepl("S", .[[label_col]])) %>%
    mutate(
      Initial = as.numeric(.[[init_col]]),
      Final = as.numeric(.[[final_col]]),
      Gain = Final - Initial,
      Replicate = rep_name
    ) %>%
    filter(!is.na(Initial) & !is.na(Final)) %>%
    select(Replicate, Initial, Final, Gain)
  
  return(clean_data)
}

sw_rep1 <- extract_seaweed(sw_raw, 2, 5, "Rep1")
sw_rep2 <- extract_seaweed(sw_raw, 9, 12, "Rep2")
sw_rep3 <- extract_seaweed(sw_raw, 16, 19, "Rep3")

sw_combined <- bind_rows(sw_rep1, sw_rep2, sw_rep3)
write.csv(sw_combined, "csv_data/seaweed_biomass.csv", row.names=FALSE)

cat("Data cleaning complete. Cleaned datasets saved to 'csv_data/'.\n")
