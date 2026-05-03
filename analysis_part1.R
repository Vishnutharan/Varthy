dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(readxl); library(ggplot2); library(dplyr); library(tidyr)
library(car); library(nortest); library(moments); library(ggpubr)

outdir <- "d:/Varthy/R_output"
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
sink(file.path(outdir, "analysis_results.txt"))

datafile <- "C:/Users/karun/OneDrive/Desktop/Var/data sheet.xlsx"
resfile <- "C:/Users/karun/OneDrive/Desktop/Var/results analysis.xlsx"

cat("============================================================\n")
cat("COMPREHENSIVE STATISTICAL ANALYSIS - IMTA vs MONOCULTURE\n")
cat("============================================================\n\n")

# ---- SEA CUCUMBER GROWTH DATA ----
cat("SECTION 1: SEA CUCUMBER GROWTH ANALYSIS\n")
cat("========================================\n\n")

sc <- read_excel(resfile, sheet="sea cucumber growth ")
wk_cols <- c("mean weight IMTA","mean weight Monoculture","mean length IMTA","mean length Monoculture")

# Build weekly summary
weeks_data <- data.frame(
  Week = 1:5,
  IMTA_Weight = c(331.83, 272.3, 345, 333.67, 408.43),
  Mono_Weight = c(310.8, 281.64, 364.6, 226.56, 351.25),
  IMTA_Length = c(16.58, 14.9, 17.38, 16.83, 17.29),
  Mono_Length = c(15.5, 15.43, 16.7, 14.78, 16.69)
)

cat("Weekly Mean Body Weight (g):\n")
print(weeks_data[,1:3])
cat("\nWeekly Mean Body Length (cm):\n")
print(weeks_data[,c(1,4,5)])

# Build individual-level data from raw sheet
sc_raw <- read_excel(resfile, sheet="sea cucumber growth ")

# Individual sea cucumber data
imta_w <- c(278,292,367,359,373,279,435,436,272,138,396,357,
            248,276,260,316,123,262,435,241,280,265,
            368,338,351,393,395,277,422,321,305,389,343,271,
            305,270,348,439,498,396,495,278)
mono_w <- c(315,263,405,260,360,329,255,249,351,321,
            447,361,228,147,213,349,236,293,324,
            405,349,432,346,399,280,290,168,
            370,318,257,430,355,233,411,248,162,
            325,341,316,290,409,297,334,169,295,371)

imta_l <- c(17,15,18,14,17.5,16.5,17,20,17,12,17,18,
            13.5,14,14.5,17,11.5,14,17,14.5,17,15,
            18,17,17.5,18,18,16,17,16.5,15,17,16,16.5,
            17.5,15.5,17,18,19.5,18.5,19,14)
mono_l <- c(17,15.5,15,14.5,15.5,15.5,16,13.5,17.5,15,
            17,17.5,14,13,13.5,18,15,15,16.5,
            16,14,20,16.5,19,14.5,15,13,
            18.5,17.5,13.5,18,17,14,18,17,12,
            17,17,17,15.5,19.5,16,17,14,18.5,17)

cat("\n--- 1.1 Normality Tests ---\n")
cat("\nShapiro-Wilk Test:\n")
sw_iw <- shapiro.test(imta_w); cat("IMTA Weight: W=",sw_iw$statistic,"p=",sw_iw$p.value,"\n")
sw_mw <- shapiro.test(mono_w); cat("Mono Weight: W=",sw_mw$statistic,"p=",sw_mw$p.value,"\n")
sw_il <- shapiro.test(imta_l); cat("IMTA Length: W=",sw_il$statistic,"p=",sw_il$p.value,"\n")
sw_ml <- shapiro.test(mono_l); cat("Mono Length: W=",sw_ml$statistic,"p=",sw_ml$p.value,"\n")

cat("\nAnderson-Darling Test:\n")
ad_iw <- ad.test(imta_w); cat("IMTA Weight: A=",ad_iw$statistic,"p=",ad_iw$p.value,"\n")
ad_mw <- ad.test(mono_w); cat("Mono Weight: A=",ad_mw$statistic,"p=",ad_mw$p.value,"\n")

cat("\nDescriptive Statistics:\n")
cat("Skewness - IMTA Weight:",skewness(imta_w),"Mono Weight:",skewness(mono_w),"\n")
cat("Kurtosis - IMTA Weight:",kurtosis(imta_w),"Mono Weight:",kurtosis(mono_w),"\n")

cat("\n--- 1.2 Welch's t-test ---\n")
tt_w <- t.test(imta_w, mono_w)
cat("Body Weight: t=",tt_w$statistic,"df=",tt_w$parameter,"p=",tt_w$p.value,"\n")
cat("IMTA mean=",mean(imta_w),"SD=",sd(imta_w),"\n")
cat("Mono mean=",mean(mono_w),"SD=",sd(mono_w),"\n")
cat("Mean difference=",mean(imta_w)-mean(mono_w),"\n")
cat("95% CI: [",tt_w$conf.int[1],",",tt_w$conf.int[2],"]\n")
d_w <- (mean(imta_w)-mean(mono_w))/sqrt((sd(imta_w)^2+sd(mono_w)^2)/2)
cat("Cohen's d (effect size)=",d_w,"\n")

tt_l <- t.test(imta_l, mono_l)
cat("\nBody Length: t=",tt_l$statistic,"df=",tt_l$parameter,"p=",tt_l$p.value,"\n")
cat("IMTA mean=",mean(imta_l),"SD=",sd(imta_l),"\n")
cat("Mono mean=",mean(mono_l),"SD=",sd(mono_l),"\n")
cat("Cohen's d=", (mean(imta_l)-mean(mono_l))/sqrt((sd(imta_l)^2+sd(mono_l)^2)/2),"\n")

cat("\n--- 1.3 Mann-Whitney U Test (non-parametric) ---\n")
mw_w <- wilcox.test(imta_w, mono_w)
cat("Weight: W=",mw_w$statistic,"p=",mw_w$p.value,"\n")
mw_l <- wilcox.test(imta_l, mono_l)
cat("Length: W=",mw_l$statistic,"p=",mw_l$p.value,"\n")

cat("\n--- 1.4 Growth Rate Analysis ---\n")
agr_imta <- c(-5.953, 9.087, -2.266, 8.307)
agr_mono <- c(-2.916, 10.370, -27.608, 13.854)
sgr_imta <- c(-1.977, 2.958, -0.668, 2.246)
sgr_mono <- c(-0.985, 3.227, -9.516, 4.872)

cat("AGR (g/day) - IMTA mean:",mean(agr_imta),"SD:",sd(agr_imta),"\n")
cat("AGR (g/day) - Mono mean:",mean(agr_mono),"SD:",sd(agr_mono),"\n")
cat("SGR (%/day) - IMTA mean:",mean(sgr_imta),"SD:",sd(sgr_imta),"\n")
cat("SGR (%/day) - Mono mean:",mean(sgr_mono),"SD:",sd(sgr_mono),"\n")
cat("CV AGR IMTA:",sd(agr_imta)/abs(mean(agr_imta))*100,"%\n")
cat("CV AGR Mono:",sd(agr_mono)/abs(mean(agr_mono))*100,"%\n")

cat("\n--- 1.5 Growth Predictions ---\n")
# Linear regression for weight over weeks
lm_iw <- lm(IMTA_Weight ~ Week, data=weeks_data)
lm_mw <- lm(Mono_Weight ~ Week, data=weeks_data)
cat("IMTA Weight ~ Week: slope=",coef(lm_iw)[2],"R²=",summary(lm_iw)$r.squared,"\n")
cat("Mono Weight ~ Week: slope=",coef(lm_mw)[2],"R²=",summary(lm_mw)$r.squared,"\n")

# Predict weeks 6-10
future <- data.frame(Week=6:10)
pred_iw <- predict(lm_iw, future, interval="prediction")
pred_mw <- predict(lm_mw, future, interval="prediction")
cat("\nPredicted IMTA Weight (Weeks 6-10):\n")
print(data.frame(Week=6:10, pred_iw))
cat("\nPredicted Mono Weight (Weeks 6-10):\n")
print(data.frame(Week=6:10, pred_mw))

# Polynomial fit
poly_iw <- lm(IMTA_Weight ~ poly(Week,2), data=weeks_data)
poly_mw <- lm(Mono_Weight ~ poly(Week,2), data=weeks_data)
cat("\nPolynomial (2nd order) R²: IMTA=",summary(poly_iw)$r.squared,"Mono=",summary(poly_mw)$r.squared,"\n")

pred_poly_iw <- predict(poly_iw, future, interval="prediction")
pred_poly_mw <- predict(poly_mw, future, interval="prediction")
cat("\nPolynomial Predicted IMTA Weight:\n"); print(data.frame(Week=6:10, pred_poly_iw))
cat("\nPolynomial Predicted Mono Weight:\n"); print(data.frame(Week=6:10, pred_poly_mw))

sink()
cat("Part 1 analysis complete!\n")
