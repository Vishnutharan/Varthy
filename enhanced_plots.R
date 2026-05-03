dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
library(ggplot2); library(dplyr); library(tidyr); library(ggpubr)

outdir <- "d:/Varthy/R_output"

env_growth <- data.frame(
  Week=1:5, IMTA_W=c(331.83,272.3,345,333.67,408.43), Mono_W=c(310.8,281.64,364.6,226.56,351.25),
  IMTA_L=c(16.58,14.9,17.38,16.83,17.29), Mono_L=c(15.5,15.43,16.7,14.78,16.69),
  IMTA_Sal=c(20.66,22.90,21.77,20.94,23.00), Mono_Sal=c(20.64,23.53,21.76,21.34,24.02),
  IMTA_DO=c(5.90,7.79,7.08,7.22,6.39), Mono_DO=c(4.89,8.05,7.64,7.68,5.71),
  IMTA_Temp=c(28.20,26.37,25.67,28.23,28.10), Mono_Temp=c(28.67,26.60,25.90,28.10,28.10))

# Plot 1: Salinity vs Weight scatter with trend
sal_df <- data.frame(
  Salinity=c(env_growth$IMTA_Sal, env_growth$Mono_Sal),
  Weight=c(env_growth$IMTA_W, env_growth$Mono_W),
  Treatment=rep(c("IMTA","Monoculture"), each=5),
  Week=rep(1:5, 2))

p1 <- ggplot(sal_df, aes(x=Salinity, y=Weight, color=Treatment)) +
  geom_point(size=4) + geom_smooth(method="lm", se=TRUE, alpha=0.15, linewidth=1) +
  geom_text(aes(label=paste0("Wk",Week)), vjust=-1, size=3) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Salinity vs Sea Cucumber Weight",
       subtitle="Environmental correlation analysis", x="Salinity (ppt)", y="Weight (g)") +
  theme_minimal(base_size=14) + theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"10_salinity_vs_weight.png"), p1, width=10, height=8, dpi=300)

# Plot 2: Temperature vs Weight
temp_df <- data.frame(
  Temp=c(env_growth$IMTA_Temp, env_growth$Mono_Temp),
  Weight=c(env_growth$IMTA_W, env_growth$Mono_W),
  Treatment=rep(c("IMTA","Monoculture"), each=5), Week=rep(1:5, 2))

p2 <- ggplot(temp_df, aes(x=Temp, y=Weight, color=Treatment)) +
  geom_point(size=4) + geom_smooth(method="lm", se=TRUE, alpha=0.15, linewidth=1) +
  geom_text(aes(label=paste0("Wk",Week)), vjust=-1, size=3) +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Temperature vs Sea Cucumber Weight", x="Temperature (°C)", y="Weight (g)") +
  theme_minimal(base_size=14) + theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"11_temp_vs_weight.png"), p2, width=10, height=8, dpi=300)

# Plot 3: Phosphorus anomaly - replicate breakdown
p_df <- data.frame(
  Replicate=rep(c("R1","R2","R3"), 4),
  Week=factor(rep(rep(c("Week 3","Week 7"), each=3), 2)),
  Treatment=rep(c("IMTA","Monoculture"), each=6),
  P=c(23,57,4, 21,68,37, 49,21,26, 44,9,15))

p3 <- ggplot(p_df, aes(x=Replicate, y=P, fill=Week)) +
  geom_bar(stat="identity", position="dodge", alpha=0.85) +
  facet_wrap(~Treatment) +
  scale_fill_manual(values=c("Week 3"="#78909C","Week 7"="#E91E63")) +
  geom_hline(yintercept=mean(c(23,57,4,21,68,37)), linetype="dashed", color="blue", alpha=0.5) +
  labs(title="Phosphorus Anomaly: Replicate-Level Analysis",
       subtitle="IMTA R2 outlier driving apparent P accumulation",
       y="Phosphorus (µg/L)") +
  theme_minimal(base_size=14) + theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"12_phosphorus_anomaly.png"), p3, width=11, height=7, dpi=300)

# Plot 4: Power analysis curve
n_range <- seq(20, 500, 5)
imta_w <- c(278,292,367,359,373,279,435,436,272,138,396,357,248,276,260,316,123,262,435,241,280,265,
            368,338,351,393,395,277,422,321,305,389,343,271,305,270,348,439,498,396,495,278)
mono_w <- c(315,263,405,260,360,329,255,249,351,321,447,361,228,147,213,349,236,293,324,
            405,349,432,346,399,280,290,168,370,318,257,430,355,233,411,248,162,
            325,341,316,290,409,297,334,169,295,371)
md <- mean(imta_w)-mean(mono_w)
psd <- sqrt(((length(imta_w)-1)*sd(imta_w)^2+(length(mono_w)-1)*sd(mono_w)^2)/(length(imta_w)+length(mono_w)-2))

powers <- sapply(n_range, function(n) {
  power.t.test(n=n, delta=md, sd=psd, sig.level=0.05, type="two.sample")$power
})
pow_df <- data.frame(N=n_range, Power=powers)

p4 <- ggplot(pow_df, aes(x=N, y=Power)) +
  geom_line(color="#2196F3", linewidth=1.5) +
  geom_hline(yintercept=0.80, linetype="dashed", color="red") +
  geom_vline(xintercept=n_range[which(powers>=0.80)[1]], linetype="dotted", color="red") +
  annotate("text", x=n_range[which(powers>=0.80)[1]]+20, y=0.75,
           label=paste0("n=",n_range[which(powers>=0.80)[1]]), color="red", size=5) +
  annotate("text", x=400, y=0.82, label="80% Power Threshold", color="red", size=4) +
  annotate("point", x=42, y=powers[which.min(abs(n_range-42))], color="orange", size=4) +
  annotate("text", x=70, y=0.25, label="Current\nn=42", color="orange", size=4) +
  labs(title="Statistical Power vs Sample Size",
       subtitle=paste0("Effect size d=",round(md/psd,3),", α=0.05"),
       x="Sample Size per Group (n)", y="Power (1-β)") +
  theme_minimal(base_size=14) + theme(plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"13_power_analysis.png"), p4, width=10, height=7, dpi=300)

# Plot 5: Correlation heatmap
cor_vars <- c("IMTA_Sal","IMTA_DO","IMTA_Temp")
cor_mat <- data.frame(
  Parameter=rep(c("Salinity","DO","Temperature"), 2),
  Outcome=rep(c("Weight","Length"), each=3),
  r=c(cor(env_growth$IMTA_W, env_growth$IMTA_Sal),
      cor(env_growth$IMTA_W, env_growth$IMTA_DO),
      cor(env_growth$IMTA_W, env_growth$IMTA_Temp),
      cor(env_growth$IMTA_L, env_growth$IMTA_Sal),
      cor(env_growth$IMTA_L, env_growth$IMTA_DO),
      cor(env_growth$IMTA_L, env_growth$IMTA_Temp)))

# Mono correlations
cor_mat2 <- data.frame(
  Parameter=rep(c("Salinity","DO","Temperature"), 2),
  Outcome=rep(c("Weight","Length"), each=3),
  r=c(cor(env_growth$Mono_W, env_growth$Mono_Sal),
      cor(env_growth$Mono_W, env_growth$Mono_DO),
      cor(env_growth$Mono_W, env_growth$Mono_Temp),
      cor(env_growth$Mono_L, env_growth$Mono_Sal),
      cor(env_growth$Mono_L, env_growth$Mono_DO),
      cor(env_growth$Mono_L, env_growth$Mono_Temp)))
cor_mat$Treatment <- "IMTA"; cor_mat2$Treatment <- "Monoculture"
cor_mat <- cor_mat[,c("Parameter","Outcome","r","Treatment")]
cor_all <- rbind(cor_mat, cor_mat2)

p5 <- ggplot(cor_all, aes(x=Parameter, y=Outcome, fill=r)) +
  geom_tile(color="white", linewidth=1) +
  geom_text(aes(label=sprintf("%.2f",r)), size=5, fontface="bold") +
  facet_wrap(~Treatment) +
  scale_fill_gradient2(low="#D32F2F", mid="white", high="#1976D2", midpoint=0, limits=c(-1,1)) +
  labs(title="Environment-Growth Correlation Heatmap", fill="Pearson r") +
  theme_minimal(base_size=14) +
  theme(plot.title=element_text(face="bold"), axis.title=element_blank())
ggsave(file.path(outdir,"14_correlation_heatmap.png"), p5, width=12, height=6, dpi=300)

# Plot 6: Growth dip timeline
wt_long <- env_growth %>% select(Week, IMTA_W, Mono_W) %>%
  pivot_longer(-Week, names_to="Trt", values_to="Weight") %>%
  mutate(Trt=ifelse(Trt=="IMTA_W","IMTA","Monoculture"))

p6 <- ggplot(wt_long, aes(x=Week, y=Weight, color=Trt)) +
  geom_line(linewidth=1.2) + geom_point(size=3.5) +
  annotate("rect", xmin=3.5, xmax=4.5, ymin=200, ymax=420, alpha=0.1, fill="red") +
  annotate("text", x=4, y=210, label="Growth\nCrash", color="red", size=3.5, fontface="bold") +
  annotate("segment", x=4, xend=4, y=364.6, yend=226.56,
           arrow=arrow(length=unit(0.2,"cm")), color="red", linewidth=1) +
  annotate("text", x=4.3, y=295, label="-138g", color="red", fontface="bold") +
  scale_color_manual(values=c("IMTA"="#2196F3","Monoculture"="#FF5722")) +
  labs(title="Week 4 Growth Crash: IMTA Resilience vs Monoculture Vulnerability",
       subtitle="Monoculture lost 138g while IMTA lost only 11g during same environmental stress",
       x="Week", y="Mean Body Weight (g)") +
  theme_minimal(base_size=14) + theme(legend.position="bottom", plot.title=element_text(face="bold"))
ggsave(file.path(outdir,"15_growth_dip_analysis.png"), p6, width=11, height=7, dpi=300)

cat("All enhanced plots saved!\n")
