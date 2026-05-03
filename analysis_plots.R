dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(ggplot2); library(dplyr); library(tidyr); library(ggpubr)

outdir <- "d:/Varthy/R_output"

# Data
weeks_data <- data.frame(Week=1:5,
  IMTA_W=c(331.83,272.3,345,333.67,408.43),
  Mono_W=c(310.8,281.64,364.6,226.56,351.25),
  IMTA_L=c(16.58,14.9,17.38,16.83,17.29),
  Mono_L=c(15.5,15.43,16.7,14.78,16.69))

# 1. Sea cucumber weight comparison
wt_long <- weeks_data %>% select(Week, IMTA_W, Mono_W) %>%
  pivot_longer(-Week, names_to="Treatment", values_to="Weight") %>%
  mutate(Treatment=ifelse(Treatment=="IMTA_W","IMTA","Monoculture"))

p1 <- ggplot(wt_long, aes(x=Week, y=Weight, color=Treatment, linetype=Treatment)) +
  geom_line(linewidth=1.2) + geom_point(size=3) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Sea Cucumber Mean Body Weight Over Time",
       subtitle="IMTA vs Monoculture Treatment",
       x="Week", y="Mean Body Weight (g)") +
  theme_minimal(base_size=14) +
  theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"01_sea_cucumber_weight.png"), p1, width=10, height=7, dpi=300)

# 2. Sea cucumber length comparison
lt_long <- weeks_data %>% select(Week, IMTA_L, Mono_L) %>%
  pivot_longer(-Week, names_to="Treatment", values_to="Length") %>%
  mutate(Treatment=ifelse(Treatment=="IMTA_L","IMTA","Monoculture"))

p2 <- ggplot(lt_long, aes(x=Week, y=Length, color=Treatment, linetype=Treatment)) +
  geom_line(linewidth=1.2) + geom_point(size=3) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Sea Cucumber Mean Body Length Over Time",
       x="Week", y="Mean Body Length (cm)") +
  theme_minimal(base_size=14) +
  theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"02_sea_cucumber_length.png"), p2, width=10, height=7, dpi=300)

# 3. Boxplot comparison
imta_w <- c(278,292,367,359,373,279,435,436,272,138,396,357,
            248,276,260,316,123,262,435,241,280,265,
            368,338,351,393,395,277,422,321,305,389,343,271,
            305,270,348,439,498,396,495,278)
mono_w <- c(315,263,405,260,360,329,255,249,351,321,
            447,361,228,147,213,349,236,293,324,
            405,349,432,346,399,280,290,168,
            370,318,257,430,355,233,411,248,162,
            325,341,316,290,409,297,334,169,295,371)

box_df <- data.frame(
  Treatment=c(rep("IMTA",length(imta_w)),rep("Monoculture",length(mono_w))),
  Weight=c(imta_w, mono_w))

p3 <- ggplot(box_df, aes(x=Treatment, y=Weight, fill=Treatment)) +
  geom_boxplot(alpha=0.7, outlier.color="red") +
  geom_jitter(width=0.2, alpha=0.4, size=2) +
  scale_fill_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Body Weight Distribution: IMTA vs Monoculture",
       y="Body Weight (g)") +
  stat_compare_means(method="t.test", label.x=1.5, label.y=520) +
  theme_minimal(base_size=14) +
  theme(legend.position="none", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"03_boxplot_weight.png"), p3, width=8, height=7, dpi=300)

# 4. AGR comparison
agr_df <- data.frame(
  Period=rep(c("Wk2-3","Wk3-4","Wk4-5","Wk5-6"),2),
  Treatment=rep(c("IMTA","Monoculture"),each=4),
  AGR=c(-5.953,9.087,-2.266,8.307,-2.916,10.370,-27.608,13.854))

p4 <- ggplot(agr_df, aes(x=Period, y=AGR, fill=Treatment)) +
  geom_bar(stat="identity", position="dodge", alpha=0.85) +
  scale_fill_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  geom_hline(yintercept=0, linetype="dashed") +
  labs(title="Absolute Growth Rate (AGR) Comparison", y="AGR (g/day)") +
  theme_minimal(base_size=14) +
  theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"04_agr_comparison.png"), p4, width=10, height=7, dpi=300)

# 5. Water quality multi-panel
wq_imta <- data.frame(Week=c(2,3,4,5,7), pH=c(8.19,8.20,8.35,8.12,8.22),
  DO=c(5.90,7.79,7.08,7.22,6.39), Salinity=c(20.66,22.90,21.77,20.94,23.00),
  TDS=c(16.51,18.13,17.32,16.66,18.18), Trt=rep("IMTA",5))
wq_mono <- data.frame(Week=c(2,3,4,5,7), pH=c(8.15,8.23,8.37,8.23,8.24),
  DO=c(4.89,8.05,7.64,7.68,5.71), Salinity=c(20.64,23.53,21.76,21.34,24.02),
  TDS=c(16.51,18.58,17.31,16.99,18.93), Trt=rep("Monoculture",5))
wq <- rbind(wq_imta, wq_mono)

p5a <- ggplot(wq, aes(Week, pH, color=Trt)) + geom_line(linewidth=1) + geom_point(size=2.5) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="pH") + theme_minimal() + theme(legend.position="none")
p5b <- ggplot(wq, aes(Week, DO, color=Trt)) + geom_line(linewidth=1) + geom_point(size=2.5) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Dissolved Oxygen (mg/L)") + theme_minimal() + theme(legend.position="none")
p5c <- ggplot(wq, aes(Week, Salinity, color=Trt)) + geom_line(linewidth=1) + geom_point(size=2.5) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Salinity (ppt)") + theme_minimal() + theme(legend.position="none")
p5d <- ggplot(wq, aes(Week, TDS, color=Trt)) + geom_line(linewidth=1) + geom_point(size=2.5) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="TDS (ppt)") + theme_minimal() + theme(legend.position="bottom")

p5 <- ggarrange(p5a, p5b, p5c, p5d, ncol=2, nrow=2, common.legend=TRUE, legend="bottom")
p5 <- annotate_figure(p5, top=text_grob("Water Quality Parameters: IMTA vs Monoculture",
                                          face="bold", size=16))
ggsave(file.path(outdir,"05_water_quality_panel.png"), p5, width=12, height=10, dpi=300)

# 6. Nutrient comparison
nutr_long <- data.frame(
  Week=rep(c("Week 3","Week 7"),each=4),
  Treatment=rep(rep(c("IMTA","Mono"),each=2),1),
  Parameter=rep(c("Nitrite","Phosphorus"),4),
  Value=c(57.33,28, 62,32, 49.67,42, 49,22.67))

# Simpler: just nitrite and phosphorus bars
nutr_df <- data.frame(
  Week=factor(rep(c("Week 3","Week 7"),each=2)),
  Treatment=rep(c("IMTA","Monoculture"),2),
  Nitrite=c(57.33,62,49.67,49),
  Phosphorus=c(28,32,42,22.67),
  Phosphate=c(86.33,98.33,127.33,70.67))

p6a <- ggplot(nutr_df, aes(Week, Nitrite, fill=Treatment)) +
  geom_bar(stat="identity", position="dodge", alpha=0.85) +
  scale_fill_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Nitrite (NO₂⁻) Concentration", y="µg/L") +
  theme_minimal(base_size=13) + theme(legend.position="bottom")

p6b <- ggplot(nutr_df, aes(Week, Phosphorus, fill=Treatment)) +
  geom_bar(stat="identity", position="dodge", alpha=0.85) +
  scale_fill_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Phosphorus (P) Concentration", y="µg/L") +
  theme_minimal(base_size=13) + theme(legend.position="bottom")

p6 <- ggarrange(p6a, p6b, ncol=2, common.legend=TRUE, legend="bottom")
p6 <- annotate_figure(p6, top=text_grob("Nutrient Dynamics: IMTA vs Monoculture",face="bold",size=16))
ggsave(file.path(outdir,"06_nutrient_comparison.png"), p6, width=12, height=7, dpi=300)

# 7. Prediction plot with confidence intervals
weeks_ext <- data.frame(Week=1:12)
lm_iw <- lm(IMTA_W ~ Week, data=weeks_data)
lm_mw <- lm(Mono_W ~ Week, data=weeks_data)
pred_i <- as.data.frame(predict(lm_iw, weeks_ext, interval="prediction"))
pred_m <- as.data.frame(predict(lm_mw, weeks_ext, interval="prediction"))
pred_i$Week <- 1:12; pred_i$Treatment <- "IMTA"
pred_m$Week <- 1:12; pred_m$Treatment <- "Monoculture"
pred_all <- rbind(pred_i, pred_m)

p7 <- ggplot() +
  geom_ribbon(data=pred_all, aes(x=Week, ymin=lwr, ymax=upr, fill=Treatment), alpha=0.2) +
  geom_line(data=pred_all, aes(x=Week, y=fit, color=Treatment), linewidth=1.2, linetype="dashed") +
  geom_point(data=wt_long, aes(x=Week, y=Weight, color=Treatment), size=3) +
  geom_line(data=wt_long, aes(x=Week, y=Weight, color=Treatment), linewidth=1) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  scale_fill_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  geom_vline(xintercept=5.5, linetype="dotted", color="gray40") +
  annotate("text", x=3, y=500, label="Observed", fontface="italic", color="gray30") +
  annotate("text", x=9, y=500, label="Predicted", fontface="italic", color="gray30") +
  labs(title="Sea Cucumber Weight: Observed & Predicted Growth",
       subtitle="Linear regression with 95% prediction intervals",
       x="Week", y="Mean Body Weight (g)") +
  theme_minimal(base_size=14) +
  theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"07_growth_prediction.png"), p7, width=12, height=8, dpi=300)

# 8. QQ plots
imta_l <- c(17,15,18,14,17.5,16.5,17,20,17,12,17,18,
            13.5,14,14.5,17,11.5,14,17,14.5,17,15,
            18,17,17.5,18,18,16,17,16.5,15,17,16,16.5,
            17.5,15.5,17,18,19.5,18.5,19,14)
mono_l <- c(17,15.5,15,14.5,15.5,15.5,16,13.5,17.5,15,
            17,17.5,14,13,13.5,18,15,15,16.5,
            16,14,20,16.5,19,14.5,15,13,
            18.5,17.5,13.5,18,17,14,18,17,12,
            17,17,17,15.5,19.5,16,17,14,18.5,17)

qq_df <- data.frame(
  Weight=c(imta_w,mono_w),
  Treatment=c(rep("IMTA",length(imta_w)),rep("Mono",length(mono_w))))

p8 <- ggplot(qq_df, aes(sample=Weight)) +
  stat_qq(aes(color=Treatment), size=2) + stat_qq_line(aes(color=Treatment)) +
  scale_color_manual(values=c("IMTA"="#2196F3","Mono"="#FF5722")) +
  facet_wrap(~Treatment) +
  labs(title="Q-Q Normality Plots: Sea Cucumber Body Weight") +
  theme_minimal(base_size=14) +
  theme(legend.position="none", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"08_qq_plots.png"), p8, width=10, height=6, dpi=300)

# 9. Seaweed biomass bar chart
sw_bio <- data.frame(Replicate=factor(1:3),
  Initial=c(509,544,513), Final=c(671,710,618))
sw_long <- sw_bio %>% pivot_longer(-Replicate, names_to="Stage", values_to="Biomass")
sw_long$Stage <- factor(sw_long$Stage, levels=c("Initial","Final"))

p9 <- ggplot(sw_long, aes(x=Replicate, y=Biomass, fill=Stage)) +
  geom_bar(stat="identity", position="dodge", alpha=0.85) +
  scale_fill_manual(values=c("Initial"="#78909C","Final"="#4CAF50")) +
  labs(title="Seaweed Biomass: Initial vs Final",
       subtitle="Kappaphycus alvarezii across 3 replicates (51 days)",
       y="Total Biomass (g)") +
  theme_minimal(base_size=14) +
  theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"09_seaweed_biomass.png"), p9, width=9, height=7, dpi=300)

cat("All plots saved to:", outdir, "\n")
