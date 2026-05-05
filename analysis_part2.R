dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(readxl)
library(dplyr)

outdir <- "R_output"
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
sink(file.path(outdir, "analysis_results_part2.txt"))

clean_file <- "results_analysis_cleaned.xlsx"
if (!file.exists(clean_file)) {
  stop("Missing results_analysis_cleaned.xlsx. Run `node clean_excel.js` before this script.")
}

cat("SECTION 2: SEAWEED, WATER QUALITY, NUTRIENT, SOIL, AND PROXIMATE ANALYSIS\n")
cat("=========================================================================\n\n")

seaweed_raw <- read_excel(clean_file, sheet="Seaweed Raw")
seaweed_summary <- read_excel(clean_file, sheet="Seaweed Summary")
water_quality <- read_excel(clean_file, sheet="Water Quality Summary")
nutrients <- read_excel(clean_file, sheet="Nutrient Summary")
soil <- read_excel(clean_file, sheet="Soil Organic Content")
proximate <- read_excel(clean_file, sheet="Proximate Seaweed")

cat("--- 2.1 Seaweed Biomass Summary ---\n")
print(seaweed_summary)

cat("\n--- 2.2 ANOVA: Seaweed Weight Gain Across Replicates ---\n")
seaweed_anova <- aov(Weight_Gain_g ~ Replicate, data=seaweed_raw)
print(summary(seaweed_anova))

cat("\n--- 2.3 Water Quality Summary ---\n")
print(water_quality)

cat("\n--- 2.4 Paired t-tests for Water Quality Parameters ---\n")
parameters <- c("pH", "TDS_ppt", "Salinity_ppt", "Temperature_C", "DO_mg_L", "Conductivity_mS_cm")
for (parameter in parameters) {
  imta <- water_quality %>% filter(Treatment == "IMTA") %>% arrange(SampleWeek) %>% pull(parameter)
  mono <- water_quality %>% filter(Treatment == "Monoculture") %>% arrange(SampleWeek) %>% pull(parameter)
  test <- t.test(imta, mono, paired=TRUE)
  cat(parameter, ": t=", test$statistic, " p=", test$p.value,
      " IMTA_mean=", mean(imta), " Mono_mean=", mean(mono), "\n")
}

cat("\n--- 2.5 Nutrient Change Over Time ---\n")
print(nutrients)

get_value <- function(treatment, week, parameter) {
  nutrients %>%
    filter(Treatment == treatment, SampleWeek == week) %>%
    pull(parameter)
}

imta_p_start <- get_value("IMTA", 3, "P_ug_L")
imta_p_end <- get_value("IMTA", 7, "P_ug_L")
mono_p_start <- get_value("Monoculture", 3, "P_ug_L")
mono_p_end <- get_value("Monoculture", 7, "P_ug_L")
imta_po4_start <- get_value("IMTA", 3, "PO4_ug_L")
imta_po4_end <- get_value("IMTA", 7, "PO4_ug_L")
mono_po4_start <- get_value("Monoculture", 3, "PO4_ug_L")
mono_po4_end <- get_value("Monoculture", 7, "PO4_ug_L")

cat(sprintf("Phosphorus (P): IMTA %.2f -> %.2f (%+.1f%%)\n",
            imta_p_start, imta_p_end, (imta_p_end - imta_p_start) / imta_p_start * 100))
cat(sprintf("Phosphorus (P): Monoculture %.2f -> %.2f (%+.1f%%)\n",
            mono_p_start, mono_p_end, (mono_p_end - mono_p_start) / mono_p_start * 100))
cat(sprintf("Phosphate (PO4): IMTA %.2f -> %.2f (%+.1f%%)\n",
            imta_po4_start, imta_po4_end, (imta_po4_end - imta_po4_start) / imta_po4_start * 100))
cat(sprintf("Phosphate (PO4): Monoculture %.2f -> %.2f (%+.1f%%)\n",
            mono_po4_start, mono_po4_end, (mono_po4_end - mono_po4_start) / mono_po4_start * 100))

cat("\nCorrection: IMTA is not superior for phosphate removal in the current setup.\n")
cat("Phosphorus and phosphate accumulated in IMTA from Week 3 to Week 7,\n")
cat("while both decreased in Monoculture. Nutrients were sampled at only two\n")
cat("time points, so this finding should be presented as a limitation rather\n")
cat("than as a complete nutrient-cycle model.\n")

cat("\n--- 2.6 Soil Organic Content ---\n")
print(soil)

cat("\n--- 2.7 Proximate Analysis of Seaweed ---\n")
print(proximate)

sink()
cat("Part 2 analysis complete!\n")
