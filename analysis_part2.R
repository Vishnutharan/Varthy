dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(readxl); library(ggplot2); library(dplyr); library(tidyr)
library(car); library(nortest); library(agricolae); library(ggpubr)

outdir <- "d:/Varthy/R_output"
sink(file.path(outdir, "analysis_results.txt"), append=TRUE)

cat("\n\nSECTION 2: SEAWEED BIOMASS ANALYSIS\n")
cat("====================================\n\n")

# Seaweed weight gain per replicate
rep1_gain <- c(10,10,4,9,5,8,6,6,7,-18)
rep2_gain <- c(4,9,6,7,7,6,9,7,12,7)
rep3_gain <- c(8,6,9,10,7,10,-16,9,10,9)

# Remove dead (0 final weight) seedlings for cleaner analysis
rep1_wg <- c(10,10,4,9,5,8,6,6,7)
rep2_wg <- c(7,9,7,6,7,9,8,12,7)
rep3_wg <- c(8,6,9,10,7,10,9,10,9,7,8,6,7)

cat("--- 2.1 Normality Tests (Shapiro-Wilk) ---\n")
sw1 <- shapiro.test(rep1_gain); cat("Rep1: W=",sw1$statistic,"p=",sw1$p.value,"\n")
sw2 <- shapiro.test(rep2_gain); cat("Rep2: W=",sw2$statistic,"p=",sw2$p.value,"\n")
sw3 <- shapiro.test(rep3_gain); cat("Rep3: W=",sw3$statistic,"p=",sw3$p.value,"\n")

cat("\n--- 2.2 ANOVA: Weight Gain Across Replicates ---\n")
sw_df <- data.frame(
  Replicate = factor(rep(c("Rep1","Rep2","Rep3"), c(length(rep1_gain),length(rep2_gain),length(rep3_gain)))),
  WeightGain = c(rep1_gain, rep2_gain, rep3_gain)
)
aov_sw <- aov(WeightGain ~ Replicate, data=sw_df)
cat("ANOVA Summary:\n"); print(summary(aov_sw))

cat("\n--- 2.3 Kruskal-Wallis Test (non-parametric) ---\n")
kw <- kruskal.test(WeightGain ~ Replicate, data=sw_df)
cat("H=",kw$statistic,"p=",kw$p.value,"\n")

cat("\n--- 2.4 Tukey HSD Post-hoc ---\n")
print(TukeyHSD(aov_sw))

cat("\n--- 2.5 Seaweed Biomass Summary ---\n")
cat("Rep1: Initial=509g, Final=671g, Gain=162g, %=31.83, Survival=90%\n")
cat("Rep2: Initial=544g, Final=710g, Gain=166g, %=30.51, Survival=90%\n")
cat("Rep3: Initial=513g, Final=618g, Gain=105g, %=20.47, Survival=83.33%\n")
cat("Overall: Initial=1566g, Final=1999g, Gain=433g, AGR=8.49g/day, SGR=0.49%/day\n")

cat("\n\nSECTION 3: WATER QUALITY ANALYSIS\n")
cat("==================================\n\n")

# Water quality data: IMTA
wq_imta <- data.frame(
  Week=c(2,3,4,5,7),
  pH=c(8.19,8.20,8.35,8.12,8.22),
  TDS=c(16.51,18.13,17.32,16.66,18.18),
  Salinity=c(20.66,22.90,21.77,20.94,23.00),
  Temp=c(28.20,26.37,25.67,28.23,28.10),
  DO=c(5.90,7.79,7.08,7.22,6.39),
  Conductivity=c(24.33,26.67,25.47,24.33,26.73),
  Treatment=rep("IMTA",5)
)
wq_mono <- data.frame(
  Week=c(2,3,4,5,7),
  pH=c(8.15,8.23,8.37,8.23,8.24),
  TDS=c(16.51,18.58,17.31,16.99,18.93),
  Salinity=c(20.64,23.53,21.76,21.34,24.02),
  Temp=c(28.67,26.60,25.90,28.10,28.10),
  DO=c(4.89,8.05,7.64,7.68,5.71),
  Conductivity=c(24.27,27.33,25.47,25.00,27.80),
  Treatment=rep("Monoculture",5)
)
wq <- rbind(wq_imta, wq_mono)

cat("--- 3.1 Paired t-tests for Water Quality Parameters ---\n")
params <- c("pH","TDS","Salinity","Temp","DO","Conductivity")
for(p in params) {
  tt <- t.test(wq_imta[[p]], wq_mono[[p]], paired=TRUE)
  cat(p,": t=",tt$statistic," p=",tt$p.value,
      " IMTA_mean=",mean(wq_imta[[p]])," Mono_mean=",mean(wq_mono[[p]]),"\n")
}

cat("\n--- 3.2 Correlation Matrix (IMTA) ---\n")
cor_imta <- cor(wq_imta[,2:7])
print(round(cor_imta, 3))

cat("\n--- 3.3 Correlation Matrix (Monoculture) ---\n")
cor_mono <- cor(wq_mono[,2:7])
print(round(cor_mono, 3))

cat("\n--- 3.4 Water Quality Predictions (Linear Trend) ---\n")
for(p in params) {
  lm_i <- lm(wq_imta[[p]] ~ wq_imta$Week)
  lm_m <- lm(wq_mono[[p]] ~ wq_mono$Week)
  pred_i8 <- predict(lm_i, data.frame(x=8), interval="prediction")
  pred_m8 <- predict(lm_m, data.frame(x=8), interval="prediction")
  cat(p,"Week 8 prediction - IMTA:",coef(lm_i)[1]+coef(lm_i)[2]*8,
      " Mono:",coef(lm_m)[1]+coef(lm_m)[2]*8,"\n")
}

cat("\n\nSECTION 4: NUTRIENT ANALYSIS (N/P)\n")
cat("====================================\n\n")

# Nutrient data
nutr <- data.frame(
  Week=rep(c(3,7),each=2), Treatment=rep(c("IMTA","Mono"),2),
  NO2=c(57.33,62,49.67,49), NaNO2=c(86,105,74,73.33),
  NO2_N=c(17.33,21.5,15,15), P2O5=c(64.33,73.67,95.33,53),
  P=c(28,32,42,22.67), PO4=c(86.33,98.33,127.33,70.67)
)
cat("Nutrient Summary:\n"); print(nutr)

cat("\n--- 4.1 Nutrient Change Over Time ---\n")
cat("Nitrite (NO2-): IMTA decreased from 57.3 to 49.7 (-13.3%)\n")
cat("Nitrite (NO2-): Mono decreased from 62.0 to 49.0 (-21.0%)\n")
cat("Phosphorus (P): IMTA increased from 28.0 to 42.0 (+50.0%)\n")
cat("Phosphorus (P): Mono decreased from 32.0 to 22.7 (-29.1%)\n")
cat("Phosphate (PO4): IMTA increased from 86.3 to 127.3 (+47.5%)\n")
cat("Phosphate (PO4): Mono decreased from 98.3 to 70.7 (-28.1%)\n")

cat("\n\nSECTION 5: SOIL ORGANIC CONTENT\n")
cat("================================\n\n")
soil <- data.frame(
  Sample=c("Site1_R1","Site1_R2","Site2_R1","Site2_R2"),
  Moisture=c(0.0909,0.0671,0.1349,0.0929),
  OM=c(0.070,0.075,0.068,0.0912)
)
cat("Soil Data:\n"); print(soil)
cat("\nSite 1 - Moisture mean:",mean(c(0.0909,0.0671)),"OM mean:",mean(c(0.070,0.075)),"\n")
cat("Site 2 - Moisture mean:",mean(c(0.1349,0.0929)),"OM mean:",mean(c(0.068,0.0912)),"\n")
tt_m <- t.test(c(0.0909,0.0671), c(0.1349,0.0929))
cat("Moisture Site1 vs Site2: t=",tt_m$statistic,"p=",tt_m$p.value,"\n")

cat("\n\nSECTION 6: PROXIMATE ANALYSIS (Seaweed)\n")
cat("========================================\n\n")
prox <- data.frame(Sample=c("R1","R2","R3"),Moisture=c(0.0074,0.011,0.0113),OM=c(0.6335,0.631,0.6413))
cat("Proximate Analysis:\n"); print(prox)
cat("Moisture - Mean:",mean(prox$Moisture),"SD:",sd(prox$Moisture),"\n")
cat("Organic Matter - Mean:",mean(prox$OM),"SD:",sd(prox$OM),"\n")

cat("\n\nSECTION 7: COMPREHENSIVE PREDICTIONS\n")
cat("======================================\n\n")

# Sea cucumber weight prediction
weeks_data <- data.frame(Week=1:5,
  IMTA_W=c(331.83,272.3,345,333.67,408.43),
  Mono_W=c(310.8,281.64,364.6,226.56,351.25))

lm1 <- lm(IMTA_W ~ Week, data=weeks_data)
lm2 <- lm(Mono_W ~ Week, data=weeks_data)

cat("--- 7.1 Sea Cucumber Weight Predictions (Weeks 6-12) ---\n")
future <- data.frame(Week=6:12)
p1 <- predict(lm1, future, interval="prediction")
p2 <- predict(lm2, future, interval="prediction")
cat("\nIMTA Predictions:\n")
print(data.frame(Week=6:12, Fit=p1[,1], Lower=p1[,2], Upper=p1[,3]))
cat("\nMonoculture Predictions:\n")
print(data.frame(Week=6:12, Fit=p2[,1], Lower=p2[,2], Upper=p2[,3]))

cat("\n--- 7.2 Growth Stability Index ---\n")
cv_imta <- sd(weeks_data$IMTA_W)/mean(weeks_data$IMTA_W)*100
cv_mono <- sd(weeks_data$Mono_W)/mean(weeks_data$Mono_W)*100
cat("CV IMTA:",cv_imta,"%\n")
cat("CV Mono:",cv_mono,"%\n")
cat("IMTA is",ifelse(cv_imta<cv_mono,"more","less"),"stable\n")

cat("\n--- 7.3 Predicted Harvest Weight at Week 12 ---\n")
cat("IMTA:",predict(lm1,data.frame(Week=12)),"g\n")
cat("Mono:",predict(lm2,data.frame(Week=12)),"g\n")

cat("\n--- 7.4 Seaweed Biomass Prediction ---\n")
sw_biomass <- data.frame(Rep=1:3, Initial=c(509,544,513), Final=c(671,710,618))
sw_biomass$Gain <- sw_biomass$Final - sw_biomass$Initial
sw_biomass$DailyRate <- sw_biomass$Gain / 51
cat("Predicted biomass at Day 75:\n")
sw_biomass$Pred_75 <- sw_biomass$Initial + sw_biomass$DailyRate * 75
sw_biomass$Pred_100 <- sw_biomass$Initial + sw_biomass$DailyRate * 100
print(sw_biomass)

cat("\n--- 7.5 Water Quality Forecasting ---\n")
for(p in c("pH","DO","Salinity","TDS")) {
  lm_i <- lm(wq_imta[[p]] ~ wq_imta$Week)
  cat(p,"IMTA Week 8:",coef(lm_i)[1]+coef(lm_i)[2]*8,
      "Week 10:",coef(lm_i)[1]+coef(lm_i)[2]*10,"\n")
}

cat("\n\n============================================================\n")
cat("ANALYSIS COMPLETE - All results saved to R_output folder\n")
cat("============================================================\n")
sink()
cat("Part 2 analysis complete!\n")
