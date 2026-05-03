dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE, showWarnings=FALSE)
.libPaths(Sys.getenv("R_LIBS_USER"))
install.packages(c("readxl","ggplot2","dplyr","tidyr","car","agricolae","emmeans","forecast","lme4","ggpubr","nortest","moments","writexl"), repos="https://cloud.r-project.org", quiet=TRUE, lib=Sys.getenv("R_LIBS_USER"))
cat("All packages installed!\n")
