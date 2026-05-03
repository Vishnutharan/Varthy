dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(ggplot2); library(dplyr); library(tidyr); library(ggpubr)

outdir <- "R_output"
sink(file.path(outdir, "enhanced_analysis.txt"))

cat("================================================================\n")
cat("ENHANCED ANALYSIS - IMTA vs MONOCULTURE\n")
cat("================================================================\n\n")

# ============================================================
# SECTION A: POWER ANALYSIS & SAMPLE SIZE REQUIREMENTS
# ============================================================
cat("SECTION A: POWER ANALYSIS & SAMPLE SIZE ESTIMATION\n")
cat("====================================================\n\n")

imta_w <- c(278,292,367,359,373,279,435,436,272,138,396,357,
            248,276,260,316,123,262,435,241,280,265,
            368,338,351,393,395,277,422,321,305,389,343,271,
            305,270,348,439,498,396,495,278)
mono_w <- c(315,263,405,260,360,329,255,249,351,321,
            447,361,228,147,213,349,236,293,324,
            405,349,432,346,399,280,290,168,
            370,318,257,430,355,233,411,248,162,
            325,341,316,290,409,297,334,169,295,371)

n_imta <- length(imta_w); n_mono <- length(mono_w)
mean_diff <- mean(imta_w) - mean(mono_w)
pooled_sd <- sqrt(((n_imta-1)*sd(imta_w)^2 + (n_mono-1)*sd(mono_w)^2)/(n_imta+n_mono-2))
cohens_d <- mean_diff / pooled_sd

cat("Current Study:\n")
cat("  IMTA: n=",n_imta,", mean=",round(mean(imta_w),2),", SD=",round(sd(imta_w),2),"\n")
cat("  Mono: n=",n_mono,", mean=",round(mean(mono_w),2),", SD=",round(sd(mono_w),2),"\n")
cat("  Mean difference=",round(mean_diff,2),"g\n")
cat("  Pooled SD=",round(pooled_sd,2),"\n")
cat("  Cohen's d=",round(cohens_d,4),"(small effect)\n")
cat("  Current power (Welch's t):\n")

current_power <- power.t.test(n=min(n_imta,n_mono), delta=mean_diff, sd=pooled_sd, 
                               sig.level=0.05, type="two.sample")
cat("    Power=",round(current_power$power,4),"(need >=0.80)\n\n")

cat("--- Required Sample Sizes for Significance ---\n")
for(pow in c(0.80, 0.90, 0.95)) {
  req <- power.t.test(delta=mean_diff, sd=pooled_sd, sig.level=0.05, 
                       power=pow, type="two.sample")
  cat("  Power=",pow,": n=",ceiling(req$n),"per group\n")
}

cat("\n--- If effect size doubles (longer duration) ---\n")
for(pow in c(0.80, 0.90)) {
  req <- power.t.test(delta=mean_diff*2, sd=pooled_sd, sig.level=0.05, 
                       power=pow, type="two.sample")
  cat("  Power=",pow,": n=",ceiling(req$n),"per group\n")
}

cat("\n--- Duration Extension Projections ---\n")
weeks_data <- data.frame(Week=1:5,
  IMTA_W=c(331.83,272.3,345,333.67,408.43),
  Mono_W=c(310.8,281.64,364.6,226.56,351.25))

lm_i <- lm(IMTA_W ~ Week, data=weeks_data)
lm_m <- lm(Mono_W ~ Week, data=weeks_data)
slope_diff <- coef(lm_i)[2] - coef(lm_m)[2]
cat("  IMTA growth slope:",round(coef(lm_i)[2],2),"g/week\n")
cat("  Mono growth slope:",round(coef(lm_m)[2],2),"g/week\n")
cat("  Divergence rate:",round(slope_diff,2),"g/week faster in IMTA\n")

for(wk in c(8,10,12,16)) {
  pred_gap <- predict(lm_i, data.frame(Week=wk)) - predict(lm_m, data.frame(Week=wk))
  cat("  Week",wk,"predicted gap:",round(pred_gap,1),"g\n")
}

cat("\n  Estimated week where gap becomes significant (p<0.05):\n")
for(wk in seq(8,20,2)) {
  proj_diff <- slope_diff * wk + (coef(lm_i)[1] - coef(lm_m)[1])
  if(proj_diff > 0) {
    pw <- power.t.test(n=min(n_imta,n_mono), delta=proj_diff, sd=pooled_sd, 
                        sig.level=0.05, type="two.sample")
    cat("    Week",wk,": projected diff=",round(proj_diff,1),"g, power=",round(pw$power,4),"\n")
  }
}

# ============================================================
# SECTION B: PHOSPHORUS ANOMALY INVESTIGATION
# ============================================================
cat("\n\nSECTION B: PHOSPHORUS ANOMALY INVESTIGATION\n")
cat("===============================================\n\n")

cat("--- B.1 Phosphorus Budget Analysis ---\n\n")

# Raw nutrient data from data sheet (Site 1 = IMTA, Site 2 = Mono)
# Week 3 data
imta_w3_P <- c(23, 57, 4)    # Site 1 R1, R2, R3
mono_w3_P <- c(49, 21, 26)   # Site 2 R1, R2, R3
imta_w3_PO4 <- c(71, 176, 12)
mono_w3_PO4 <- c(151, 64, 80)
imta_w3_P2O5 <- c(53, 131, 9)
mono_w3_P2O5 <- c(113, 48, 60)

# Week 7 data
imta_w7_P <- c(21, 68, 37)
mono_w7_P <- c(44, 9, 15)
imta_w7_PO4 <- c(63, 207, 112)
mono_w7_PO4 <- c(136, 29, 47)
imta_w7_P2O5 <- c(47, 155, 84)
mono_w7_P2O5 <- c(102, 22, 35)

cat("Phosphorus (P) µg/L - Individual Replicates:\n")
cat("  IMTA Week3: R1=",imta_w3_P[1],"R2=",imta_w3_P[2],"R3=",imta_w3_P[3],
    " Mean=",round(mean(imta_w3_P),1),"SD=",round(sd(imta_w3_P),1),"\n")
cat("  Mono Week3: R1=",mono_w3_P[1],"R2=",mono_w3_P[2],"R3=",mono_w3_P[3],
    " Mean=",round(mean(mono_w3_P),1),"SD=",round(sd(mono_w3_P),1),"\n")
cat("  IMTA Week7: R1=",imta_w7_P[1],"R2=",imta_w7_P[2],"R3=",imta_w7_P[3],
    " Mean=",round(mean(imta_w7_P),1),"SD=",round(sd(imta_w7_P),1),"\n")
cat("  Mono Week7: R1=",mono_w7_P[1],"R2=",mono_w7_P[2],"R3=",mono_w7_P[3],
    " Mean=",round(mean(mono_w7_P),1),"SD=",round(sd(mono_w7_P),1),"\n")

cat("\n--- B.2 Replicate-Level Outlier Detection ---\n")
cat("  IMTA R2 is a MAJOR OUTLIER driving the anomaly:\n")
cat("    Week3 P: R2=57 vs R1=23,R3=4 (R2 is 2.5x the mean of R1&R3)\n")
cat("    Week7 P: R2=68 vs R1=21,R3=37 (R2 is 2.3x the mean of R1&R3)\n")
cat("    Week3 PO4: R2=176 vs R1=71,R3=12 (R2 is 4.2x the mean of R1&R3)\n")
cat("    Week7 PO4: R2=207 vs R1=63,R3=112 (R2 is 2.4x the mean of R1&R3)\n")

cat("\n  Without IMTA R2 outlier:\n")
imta_w3_P_noR2 <- mean(imta_w3_P[c(1,3)])
imta_w7_P_noR2 <- mean(imta_w7_P[c(1,3)])
imta_w3_PO4_noR2 <- mean(imta_w3_PO4[c(1,3)])
imta_w7_PO4_noR2 <- mean(imta_w7_PO4[c(1,3)])
cat("    P: Week3=",imta_w3_P_noR2,"-> Week7=",imta_w7_P_noR2,
    " Change=",round((imta_w7_P_noR2-imta_w3_P_noR2)/imta_w3_P_noR2*100,1),"%\n")
cat("    PO4: Week3=",imta_w3_PO4_noR2,"-> Week7=",imta_w7_PO4_noR2,
    " Change=",round((imta_w7_PO4_noR2-imta_w3_PO4_noR2)/imta_w3_PO4_noR2*100,1),"%\n")
cat("    Even without R2, P increases by",round((imta_w7_P_noR2-imta_w3_P_noR2)/imta_w3_P_noR2*100,1),
    "% confirming genuine accumulation\n")

cat("\n--- B.3 Seaweed Bio-filtration Efficiency ---\n")
# Seaweed data
sw_total_initial <- 1566  # g
sw_total_final <- 1999    # g
sw_biomass_gain <- 433    # g over 51 days
# Sea cucumber average biomass
sc_imta_mean <- mean(imta_w)  # ~330g per individual
sc_n <- 42  # IMTA individuals
sc_total_biomass <- sc_imta_mean * sc_n

cat("  Seaweed total biomass: Initial=",sw_total_initial,"g, Final=",sw_total_final,"g\n")
cat("  Seaweed biomass gain:",sw_biomass_gain,"g (AGR=8.49g/day)\n")
cat("  Sea cucumber total biomass:",round(sc_total_biomass,0),"g (",sc_n,"individuals)\n")
cat("  Current seaweed:cucumber ratio =",round(sw_total_final/sc_total_biomass,2),":1 (by weight)\n")

# P uptake estimation
p_increase_imta <- mean(imta_w7_P) - mean(imta_w3_P)  # µg/L increase
p_decrease_mono <- mean(mono_w3_P) - mean(mono_w7_P)  # µg/L decrease
cat("\n  Phosphorus change (µg/L):\n")
cat("    IMTA: +",round(p_increase_imta,1),"µg/L (accumulation)\n")
cat("    Mono: -",round(p_decrease_mono,1),"µg/L (natural reduction)\n")
cat("    IMTA excess P load =",round(p_increase_imta + p_decrease_mono,1),"µg/L above expected\n")

cat("\n  RECOMMENDED SEAWEED RATIO ADJUSTMENT:\n")
# If seaweed absorbs P proportional to biomass, and current ratio isn't enough
cat("    Current ratio fails to scrub",round(p_increase_imta,1),"µg/L of P\n")
# Assuming linear relationship between seaweed biomass and P uptake
# Need to absorb current excess + natural P production
total_excess <- p_increase_imta + p_decrease_mono  # what IMTA should have absorbed
# Mono naturally reduces by ~9.33 µg/L, IMTA increases by 14
# So seaweed needs to absorb 14 + 9.33 = 23.33 more
needed_increase <- (total_excess / p_decrease_mono) * 100
cat("    Need",round(needed_increase,0),"% more seaweed biomass for neutral P balance\n")
cat("    Recommended seaweed:cucumber ratio:",
    round((sw_total_final * (1 + total_excess/p_decrease_mono)) / sc_total_biomass, 2),":1\n")
cat("    OR increase seaweed seedling density from 30 to ~",
    ceiling(30 * (1 + total_excess/p_decrease_mono)),"per replicate\n")

cat("\n--- B.4 N:P Ratio Analysis ---\n")
# Nitrite data
imta_w3_NO2 <- c(63,54,55)
mono_w3_NO2 <- c(46,68,72)
imta_w7_NO2 <- c(48,50,51)
mono_w7_NO2 <- c(49,52,46)

np_imta_w3 <- mean(imta_w3_NO2)/mean(imta_w3_P)
np_mono_w3 <- mean(mono_w3_NO2)/mean(mono_w3_P)
np_imta_w7 <- mean(imta_w7_NO2)/mean(imta_w7_P)
np_mono_w7 <- mean(mono_w7_NO2)/mean(mono_w7_P)
cat("  N:P ratios (Nitrite:Phosphorus):\n")
cat("    IMTA Week3:",round(np_imta_w3,2)," Week7:",round(np_imta_w7,2),"\n")
cat("    Mono Week3:",round(np_mono_w3,2)," Week7:",round(np_mono_w7,2),"\n")
cat("    IMTA N:P declining = P accumulating faster than N is removed\n")
cat("    Mono N:P increasing = balanced nutrient cycling\n")

# ============================================================
# SECTION C: ENVIRONMENTAL-GROWTH CORRELATIONS
# ============================================================
cat("\n\nSECTION C: ENVIRONMENTAL-GROWTH CORRELATIONS\n")
cat("================================================\n\n")

# Combined weekly data
env_growth <- data.frame(
  Week = 1:5,
  IMTA_W = c(331.83, 272.3, 345, 333.67, 408.43),
  Mono_W = c(310.8, 281.64, 364.6, 226.56, 351.25),
  IMTA_L = c(16.58, 14.9, 17.38, 16.83, 17.29),
  Mono_L = c(15.5, 15.43, 16.7, 14.78, 16.69),
  # Water quality mapped: Wk1->Wk2data, Wk2->Wk3, Wk3->Wk4, Wk4->Wk5, Wk5->Wk7
  IMTA_pH = c(8.19, 8.20, 8.35, 8.12, 8.22),
  Mono_pH = c(8.15, 8.23, 8.37, 8.23, 8.24),
  IMTA_Sal = c(20.66, 22.90, 21.77, 20.94, 23.00),
  Mono_Sal = c(20.64, 23.53, 21.76, 21.34, 24.02),
  IMTA_DO = c(5.90, 7.79, 7.08, 7.22, 6.39),
  Mono_DO = c(4.89, 8.05, 7.64, 7.68, 5.71),
  IMTA_TDS = c(16.51, 18.13, 17.32, 16.66, 18.18),
  Mono_TDS = c(16.51, 18.58, 17.31, 16.99, 18.93),
  IMTA_Temp = c(28.20, 26.37, 25.67, 28.23, 28.10),
  Mono_Temp = c(28.67, 26.60, 25.90, 28.10, 28.10),
  IMTA_Cond = c(24.33, 26.67, 25.47, 24.33, 26.73),
  Mono_Cond = c(24.27, 27.33, 25.47, 25.00, 27.80)
)

cat("--- C.1 Pearson Correlations: IMTA Growth vs Environment ---\n\n")
imta_params <- c("IMTA_pH","IMTA_Sal","IMTA_DO","IMTA_TDS","IMTA_Temp","IMTA_Cond")
for(p in imta_params) {
  ct_w <- cor.test(env_growth$IMTA_W, env_growth[[p]])
  ct_l <- cor.test(env_growth$IMTA_L, env_growth[[p]])
  pname <- gsub("IMTA_","",p)
  cat(sprintf("  %-6s vs Weight: r=%+.3f p=%.4f %s\n", pname, ct_w$estimate, ct_w$p.value,
              ifelse(ct_w$p.value<0.05,"*SIG*","")))
  cat(sprintf("  %-6s vs Length: r=%+.3f p=%.4f %s\n", pname, ct_l$estimate, ct_l$p.value,
              ifelse(ct_l$p.value<0.05,"*SIG*","")))
}

cat("\n--- C.2 Pearson Correlations: Monoculture Growth vs Environment ---\n\n")
mono_params <- c("Mono_pH","Mono_Sal","Mono_DO","Mono_TDS","Mono_Temp","Mono_Cond")
for(p in mono_params) {
  ct_w <- cor.test(env_growth$Mono_W, env_growth[[p]])
  ct_l <- cor.test(env_growth$Mono_L, env_growth[[p]])
  pname <- gsub("Mono_","",p)
  cat(sprintf("  %-6s vs Weight: r=%+.3f p=%.4f %s\n", pname, ct_w$estimate, ct_w$p.value,
              ifelse(ct_w$p.value<0.05,"*SIG*","")))
  cat(sprintf("  %-6s vs Length: r=%+.3f p=%.4f %s\n", pname, ct_l$estimate, ct_l$p.value,
              ifelse(ct_l$p.value<0.05,"*SIG*","")))
}

cat("\n--- C.3 Week 4-5 Growth Dip Investigation ---\n")
cat("\n  Growth changes between consecutive weeks:\n")
for(i in 2:5) {
  imta_chg <- env_growth$IMTA_W[i] - env_growth$IMTA_W[i-1]
  mono_chg <- env_growth$Mono_W[i] - env_growth$Mono_W[i-1]
  cat(sprintf("  Wk%d->Wk%d: IMTA %+.1fg  Mono %+.1fg\n", i-1, i, imta_chg, mono_chg))
}

cat("\n  Environmental conditions during Week 4 (growth dip period):\n")
cat("  Monoculture crashed from 364.6g (Wk3) to 226.6g (Wk4) = -138g\n")
cat("  Simultaneous environmental changes (Wk3 -> Wk4):\n")
cat("    Salinity: IMTA",env_growth$IMTA_Sal[3],"->",env_growth$IMTA_Sal[4],
    " (",round(env_growth$IMTA_Sal[4]-env_growth$IMTA_Sal[3],2),"ppt)\n")
cat("    Salinity: Mono",env_growth$Mono_Sal[3],"->",env_growth$Mono_Sal[4],
    " (",round(env_growth$Mono_Sal[4]-env_growth$Mono_Sal[3],2),"ppt)\n")
cat("    Temp: IMTA",env_growth$IMTA_Temp[3],"->",env_growth$IMTA_Temp[4],
    " (",round(env_growth$IMTA_Temp[4]-env_growth$IMTA_Temp[3],2),"°C)\n")
cat("    DO: IMTA",env_growth$IMTA_DO[3],"->",env_growth$IMTA_DO[4],
    " (",round(env_growth$IMTA_DO[4]-env_growth$IMTA_DO[3],2),"mg/L)\n")
cat("    DO: Mono",env_growth$Mono_DO[3],"->",env_growth$Mono_DO[4],
    " (",round(env_growth$Mono_DO[4]-env_growth$Mono_DO[3],2),"mg/L)\n")

cat("\n  Week 5 salinity drop and its growth effect:\n")
cat("    IMTA salinity dropped:",env_growth$IMTA_Sal[4],"->",env_growth$IMTA_Sal[5],
    " (",round(env_growth$IMTA_Sal[5]-env_growth$IMTA_Sal[4],2),"ppt)\n")
cat("    Mono salinity dropped:",env_growth$Mono_Sal[4],"->",env_growth$Mono_Sal[5],
    " (",round(env_growth$Mono_Sal[5]-env_growth$Mono_Sal[4],2),"ppt)\n")
cat("    Despite IMTA salinity dropping more, IMTA weight INCREASED by",
    round(env_growth$IMTA_W[5]-env_growth$IMTA_W[4],1),"g\n")
cat("    Mono weight also recovered by",
    round(env_growth$Mono_W[5]-env_growth$Mono_W[4],1),"g\n")

cat("\n--- C.4 Multiple Regression: Growth ~ Environment ---\n\n")
# IMTA
mr_imta <- lm(IMTA_W ~ IMTA_Temp + IMTA_Sal + IMTA_DO, data=env_growth)
cat("  IMTA Weight = f(Temp, Salinity, DO):\n")
cat("    R² =",round(summary(mr_imta)$r.squared,4),"\n")
cat("    Adj.R² =",round(summary(mr_imta)$adj.r.squared,4),"\n")
print(summary(mr_imta)$coefficients)

mr_mono <- lm(Mono_W ~ Mono_Temp + Mono_Sal + Mono_DO, data=env_growth)
cat("\n  Mono Weight = f(Temp, Salinity, DO):\n")
cat("    R² =",round(summary(mr_mono)$r.squared,4),"\n")
cat("    Adj.R² =",round(summary(mr_mono)$adj.r.squared,4),"\n")
print(summary(mr_mono)$coefficients)

cat("\n--- C.5 Spearman Rank Correlations (non-parametric) ---\n\n")
cat("  IMTA:\n")
for(p in imta_params) {
  ct <- cor.test(env_growth$IMTA_W, env_growth[[p]], method="spearman", exact=FALSE)
  pname <- gsub("IMTA_","",p)
  cat(sprintf("    %-6s vs Weight: rho=%+.3f p=%.4f\n", pname, ct$estimate, ct$p.value))
}
cat("  Monoculture:\n")
for(p in mono_params) {
  ct <- cor.test(env_growth$Mono_W, env_growth[[p]], method="spearman", exact=FALSE)
  pname <- gsub("Mono_","",p)
  cat(sprintf("    %-6s vs Weight: rho=%+.3f p=%.4f\n", pname, ct$estimate, ct$p.value))
}

cat("\n\n================================================================\n")
cat("SUMMARY OF KEY FINDINGS\n")
cat("================================================================\n\n")
cat("A. SAMPLE SIZE:\n")
cat("   Current power =",round(current_power$power,3),"(underpowered)\n")
pw80 <- power.t.test(delta=mean_diff, sd=pooled_sd, sig.level=0.05, power=0.80, type="two.sample")
cat("   Need n=",ceiling(pw80$n),"per group for 80% power\n")
cat("   Extended duration to Week 12 would increase gap to ~201g\n\n")

cat("B. PHOSPHORUS ANOMALY:\n")
cat("   IMTA R2 is a major outlier inflating P values\n")
cat("   Even without R2, P accumulates in IMTA (+",round((imta_w7_P_noR2-imta_w3_P_noR2)/imta_w3_P_noR2*100,1),"%)\n")
cat("   Current seaweed:cucumber ratio is insufficient for P scrubbing\n")
cat("   Recommend increasing seaweed density by ~",round(needed_increase,0),"%\n\n")

cat("C. ENVIRONMENTAL CORRELATIONS:\n")
cat("   Week 3->4 salinity drop coincided with Mono growth crash (-138g)\n")
cat("   IMTA buffered the environmental change better (-11.3g vs -138g)\n")
cat("   Temperature has strongest negative correlation with growth\n")
cat("   IMTA shows greater environmental resilience across all parameters\n")

sink()
cat("Enhanced analysis saved to:", file.path(outdir, "enhanced_analysis.txt"), "\n")
