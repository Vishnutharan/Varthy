dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(readxl); library(ggplot2); library(dplyr); library(tidyr)
library(car); library(nortest); library(moments); library(ggpubr)

outdir <- "R_output"
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
sink(file.path(outdir, "analysis_results.txt"))

resfile_clean <- "results_analysis_cleaned.xlsx"

cat("============================================================\n")
cat("COMPREHENSIVE STATISTICAL ANALYSIS - IMTA vs MONOCULTURE\n")
cat("============================================================\n\n")

# ---- SEA CUCUMBER GROWTH DATA ----
cat("SECTION 1: SEA CUCUMBER GROWTH ANALYSIS\n")
cat("========================================\n\n")

# Read cleaned raw individual data
sc_ind <- read_excel(resfile_clean, sheet="Sea Cucumber Raw")
# Read computed weekly summaries (which includes correctly computed AGR/SGR)
sc_summary <- read_excel(resfile_clean, sheet="Sea Cucumber Summary")

cat("Weekly Mean Summaries (including dynamically computed AGR & SGR in Excel):\n")
print(sc_summary)

imta_w <- sc_ind$Weight[sc_ind$Treatment=="IMTA"]
mono_w <- sc_ind$Weight[sc_ind$Treatment=="Monoculture"]
imta_l <- sc_ind$Length[sc_ind$Treatment=="IMTA"]
mono_l <- sc_ind$Length[sc_ind$Treatment=="Monoculture"]

cat("\n--- 1.1 Normality Tests ---\n")
cat("\nShapiro-Wilk Test:\n")
sw_iw <- shapiro.test(imta_w); cat("IMTA Weight: W=",sw_iw$statistic,"p=",sw_iw$p.value,"\n")
sw_mw <- shapiro.test(mono_w); cat("Mono Weight: W=",sw_mw$statistic,"p=",sw_mw$p.value,"\n")

cat("\n--- 1.2 Addressing Unequal Sample Sizes Across Weeks (Type III ANOVA) ---\n")
cat("Sample sizes vary significantly across weeks (e.g. Week 2: IMTA n=12, Mono n=10; Week 4: IMTA n=4, Mono n=5).\n")
cat("To account for this unbalanced design, a linear model with Type III Sums of Squares is used.\n")
sc_ind$Week <- as.factor(sc_ind$Week)
sc_ind$Treatment <- as.factor(sc_ind$Treatment)
# Fit linear model
lm_model <- lm(Weight ~ Treatment * Week, data=sc_ind)
anova_type3 <- car::Anova(lm_model, type="III")
print(anova_type3)

cat("\n--- 1.3 Overall Welch's t-test (Robust to unequal variance and n) ---\n")
tt_w <- t.test(imta_w, mono_w)
cat("Body Weight: t=",tt_w$statistic,"df=",tt_w$parameter,"p=",tt_w$p.value,"\n")
cat("IMTA mean=",mean(imta_w),"SD=",sd(imta_w),"\n")
cat("Mono mean=",mean(mono_w),"SD=",sd(mono_w),"\n")

cat("\n--- 1.4 Growth Rate Analysis (from Computed Excel Summaries) ---\n")
agr_imta <- sc_summary$AGR_g_per_day[sc_summary$Treatment=="IMTA" & !is.na(sc_summary$AGR_g_per_day)]
agr_mono <- sc_summary$AGR_g_per_day[sc_summary$Treatment=="Monoculture" & !is.na(sc_summary$AGR_g_per_day)]
sgr_imta <- sc_summary$SGR_percent_per_day[sc_summary$Treatment=="IMTA" & !is.na(sc_summary$SGR_percent_per_day)]
sgr_mono <- sc_summary$SGR_percent_per_day[sc_summary$Treatment=="Monoculture" & !is.na(sc_summary$SGR_percent_per_day)]

cat("AGR (g/day) - IMTA mean:",mean(agr_imta),"SD:",sd(agr_imta),"\n")
cat("AGR (g/day) - Mono mean:",mean(agr_mono),"SD:",sd(agr_mono),"\n")
cat("SGR (%/day) - IMTA mean:",mean(sgr_imta),"SD:",sd(sgr_imta),"\n")
cat("SGR (%/day) - Mono mean:",mean(sgr_mono),"SD:",sd(sgr_mono),"\n")

sink()
cat("Part 1 analysis complete!\n")
