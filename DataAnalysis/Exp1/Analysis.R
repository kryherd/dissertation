setwd("~/dissertation/DataAnalysis/Exp1")
dat <- read.table("fulldata.tsv", header = TRUE)
library(tidyverse)
library(lme4)
library(car)
library(neuropsychology)
library(influence.ME)
library(lmerTest)
library(caret)
library(ggcorrplot)
library(grid)
library(gridExtra)

############### DATA CLEANING

orders <- data.frame(dat$Subject, dat$Order)
ord <- unique(orders)
names(ord) <- c("Subject", "Order")

# rename blocks
dat$Block <- plyr::revalue(dat$Block, c("SupervisedSparse"="Supervised\nSparse",
                                        "SupervisedDense"="Supervised\nDense",
                                        "UnsupervisedSparse"="Unsupervised\nSparse",
                                        "UnsupervisedDense"="Unsupervised\nDense"))

#### ACCURACY

## calculate d' (hit - false alarm)

# label each response type
dat$response_type <- NA
dat$response_type[dat$RESP == "None"] <- "NoResponse"
dat$response_type[dat$StimType == "target" & dat$RESP == "target"] <- "Hit"
dat$response_type[dat$StimType == "target" & dat$RESP == "nottarget"] <- "Miss"
dat$response_type[dat$StimType == "nottarget" & dat$RESP == "nottarget"] <- "CorRej"
dat$response_type[dat$StimType == "nottarget" & dat$RESP == "target"] <- "FalseAlarm"
dat$response_type[substr(dat$Stimulus,1,5) == "catch" & dat$Accuracy == 1] <- "CatchGood"
dat$response_type[substr(dat$Stimulus,1,5) == "catch" & dat$Accuracy == 0] <- "CatchBad"

# create wide data frame of each type
acc_counts <- dat %>%
  dplyr::count(Subject, Block, response_type) %>%
  spread(key = response_type, value = n) %>%
  mutate_all(funs(replace(.,is.na(.),0))) %>%
  filter(CatchGood > 5) # remove blocks that have less than 6 correct catch trials

# how many subjects had not enough too few correct catch trials?
dat %>%
  dplyr::count(Subject, Block, response_type) %>%
  spread(key = response_type, value = n) %>%
  mutate_all(funs(replace(.,is.na(.),0))) %>%
  filter(CatchGood <= 5) %>%
  group_by(Block) %>%
  summarise(count = n_distinct(Subject))

# calculate dprime and put into a data frame
dprime <- acc_counts %>%
  group_by(Subject, Block) %>%
  dplyr::summarise(d.prime = dprime(Hit, Miss, FalseAlarm, CorRej)[[1]]) %>%
  inner_join(.,ord, by = "Subject")

dprime$Order <- as.factor(dprime$Order)

dprime <- dprime %>%
  mutate(Order = fct_recode(Order, "Group 1" = "1", "Group 2" = "2", "Group 3" = "3", "Group 4" = "4", "Group 5" = "5", "Group 6" = "6"))

#### REACTION TIME

rt <- dat %>%
  filter(substr(Stimulus,1,5) == "catch") %>%
  group_by(Subject, Block) %>%
  summarise(catchpct = mean(Accuracy)) %>%
  full_join(.,dat, by=c("Subject", "Block")) %>%
  filter(catchpct >= 0.75) %>%
  filter(Accuracy == 1) %>%
  mutate(subj_block = paste0(as.character(Subject), as.character(Block))) %>%
  group_by(Subject, Block) %>%
  mutate(mean_rt = mean(RT),
         sd_rt = sd(RT),
         diff = RT-mean_rt,
         remove = ifelse(abs(diff) > 2*sd_rt, 1, 0)) %>%
  dplyr::filter(remove == 0)

rt$Order <- as.factor(rt$Order)

rt <- rt %>%
  mutate(Order = fct_recode(Order, "Group 1" = "1", "Group 2" = "2", "Group 3" = "3", "Group 4" = "4", "Group 5" = "5", "Group 6" = "6"))
#### ID MEASURES

# read in behavioral data
beh <- read.csv("beh_data.csv")

# read in KTEA v1 subjects
kteav1 <- read.csv("ktea_v1_data.csv")
kteav1_sums <- kteav1 %>% select(Subject, ends_with(".ACC")) %>%
  gather(key = "Question", value = "ACC", -Subject) %>%
  dplyr::filter(!grepl("PRAC", Question)) %>%
  group_by(Subject) %>%
  summarise(total_correct = sum(ACC, na.rm = TRUE))

# read in KTEA v2 subjects
kteav2 <- read.csv("ktea_v2_data.csv")
kteav2_sums <- kteav2 %>% group_by(Subject) %>%
  summarise(total_correct = sum(Question.ACC, na.rm = TRUE))

# bind together
ktea_sums <- rbind(kteav1_sums, kteav2_sums)

# read in ND scores
nd <- read.csv("nd_scores.csv")

# check for duplicates
nd %>% group_by(Subject) %>%
  summarise(count = n()) %>%
  filter(count > 1)
nd %>% filter(Subject == "7010" | Subject == "7217")
# definitely an error
nd$Score[nd$Subject == "7010" & nd$Score == 0] <- NA
# taking the first score; this subject completed it twice
nd$Score[nd$Subject == "7217" & nd$Score == 72] <- NA
# remove those rows
nd <- nd[complete.cases(nd),]
# read in norms
nd_norms <- read.csv("nd_norms.csv")
nd <- merge(nd, nd_norms, by.x = "Score", by.y = "Raw.Score")

# merge KTEA and ND
ktea_nd <- merge(ktea_sums, nd, by = "Subject", all = TRUE)
names(ktea_nd) <- c("SubjectID", "ktea", "nd_raw", "nd_ss")

# merge with the other behavior
all_beh <- merge(ktea_nd, beh, by = "SubjectID", all = TRUE)

# change >120 to just 120
all_beh$towre_pde_ss[all_beh$towre_pde_ss == ">120"] <- "120"
all_beh$towre_pde_ss <- as.numeric(levels(all_beh$towre_pde_ss))[all_beh$towre_pde_ss]

# grab only the behavioral data for the subjects we are using
beh_data <- acc_counts %>%
  inner_join(all_beh, by = c("Subject" = "SubjectID")) %>%
  inner_join(ord, by = "Subject") %>%
  select(Subject, ktea:Order) %>%
  distinct()

# figure out which measures need to be transformed
for (i in 2:11){
  name <- names(all_beh)[i]
  plot <- hist(all_beh[,i], main = name)
  plot
  dago <- fBasics::dagoTest(all_beh[,i])
  skewp <- dago@test$p.value[[2]]
  if (skewp <= 0.05){
    cat(name, " is skewed. p = ", round(skewp, 6), "\n")
  } else{
    cat(name, " is not skewed. p = ", round(skewp, 6), "\n")
  }
}

# transform ktea, nd_ss, celf_rs_ss and raven's
vars_tf <- c("ktea", "nd_ss", "celf_rs_ss", "ravens")
pp_md_tf <- preProcess(all_beh[,vars_tf], method = c("center", "scale", "YeoJohnson"), na.remove=T)
tf_data <- predict(pp_md_tf, all_beh[,vars_tf])
names(tf_data) <- c("ktea_tf", "nd_tf", "celf_rs_tf", "ravens_tf")
all_beh <- cbind(all_beh,tf_data)

# scale and center towre_pde_ss, wa_ss

all_beh$towre_pde_sc <- scale(all_beh$towre_pde_ss)[,1]
all_beh$wa_sc <- scale(all_beh$wa_ss)[,1]

# merge in order
all_beh <- merge(all_beh, ord, by.x = "SubjectID", by.y = "Subject")

################################ END OF DATA CLEANING

################################ DATA ANALYSIS PART 1: Descriptives

#### DEMOGRAPHICS
# Demographic information for the sample
mean(all_beh$age, na.rm = TRUE)
table(all_beh$gender)
table(all_beh$Order)

#### ACCURACY
# descriptives by block
acc_counts %>%
  inner_join(., ord, by = "Subject") %>%
  group_by(Subject, Block, Order) %>%
  filter(CatchGood > 5) %>%
  summarise(acc = Hit/16 - FalseAlarm/16) %>%
  group_by(Order, Block) %>%
  summarise(m_acc = mean(acc),
            sd_acc = sd(acc))

# plot accuracies by block (percentages)
acc_counts %>%
  group_by(Subject, Block) %>%
  filter(CatchGood > 5) %>%
  summarise(acc = Hit/16 - FalseAlarm/16) %>%
  inner_join(.,ord, by = "Subject") %>%
  ggplot(aes(Block, acc)) + geom_violin() + geom_jitter(width = 0.25) + theme_bw() + 
  ylab("Accuracy (Hit - FA)")  + ggtitle("Performance by block (collapsed across orders)")

#### REACTION TIME
# descriptives by block (across orders)
rt %>%
  group_by(Order, Block) %>%
  summarise(m_rt = mean(RT)*1000,
            sd_rt = sd(RT)*1000)

# plot RTs by block (across orders)
rt %>%
  group_by(Subject, Block) %>%
  summarise(m_rt = mean(RT)) %>%
  ggplot(aes(Block, m_rt)) + geom_violin() + geom_jitter(width = 0.25) + theme_bw() + 
  ylab("Mean Reaction Time (seconds) by Block and Subject")  + ggtitle("Performance by block (collapsed across orders)")

#### ID MEASURES
# descriptives
beh_data %>%
  select(ktea:wa_ss) %>%
  gather(key = "measure", value = "value") %>%
  group_by(measure) %>%
  summarise(m = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            min = min(value, na.rm = TRUE),
            max = max(value, na.rm = TRUE))

# make correlation matrices
# rounded
cor.mat <- round(cor(all_beh[,c(14:19)], use = "complete.obs"), 1)
p.mat <- round(cor_pmat(all_beh[,c(14:19)]),4)
# unrounded
cor.mat.full <- cor(all_beh[,c(14:19)], use = "complete.obs")
p.mat.full <- cor_pmat(all_beh[,c(14:19)])
# plot
ggcorrplot(cor.mat, type = "lower", p.mat = p.mat)
ggcorrplot(cor.mat, type = "lower", lab = TRUE)

## Running PCA to see if it's OK to make a language composite
# select data
pca_dat <- all_beh[,c(14,15,16,18,19)]
pca_dat <- pca_dat[complete.cases(pca_dat),]
# check if the data is suitable for a PCA
psych::KMO(pca_dat)
cor.mat <- cor(pca_dat)
psych::cortest.bartlett(cor.mat, n = 218)
# run PCA
beh.pca <- prcomp(pca_dat)
# view eigenvalues for componenets
eigen(cor.mat)
# view prop of variance for components
summary(beh.pca)
# view factor loadings
print(beh.pca)
# scree plot
plot(beh.pca, type = "l")

# create language composite
all_beh$lang_composite <- rowMeans(all_beh[,c(14,15,16,18,19)], na.rm = TRUE)
# scale but don't center composite
all_beh$lang_composite <- scale(all_beh$lang_composite, center = FALSE)
hist(all_beh$lang_composite)

################################ END OF DATA ANALYSIS PART 1: Descriptives

################################ DATA ANALYSIS PART 2: Order Effects

##################### Effect 1
######### ACCURACY
#### Experimental Effects

# select data
acc1 <- base::subset(dprime, dprime$Order == "Group 1" | dprime$Order == "Group 2")

# build up model
m1 <- lmer(d.prime ~ 1 + (1|Subject), data = acc1) # base model
m2 <- lmer(d.prime ~ Block + (1|Subject), data = acc1) # add effect of block
anova(m1,m2)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = acc1) # add effect of order
anova(m1,m3)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = acc1) # final model
anova(m3,m4)
anova(m4)

# investigate interaction between block and order
ud.dat <- acc1$Order=="1"
ss.dat <- acc1$Order=="2"

m4.1 <- lmer(d.prime ~ Block + (1|Subject), data = acc1, subset = ud.dat)
anova(m4.1)
m4.2 <- lmer(d.prime ~ Block + (1|Subject), data = acc1, subset = ss.dat)
anova(m4.2)

#### Individual Differences

acc1_beh <- merge(acc1, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <-  lmer(d.prime ~ ravens + Block * Order.x + (1|Subject), data = acc1_beh)
m1 <- lmer(d.prime ~ ravens + Block * Order.x + lang_composite + (1|Subject), data = acc1_beh)
anova(m0,m1)
anova(m1)

######### REACTION TIME
#### Experimental Effects

# select data
rt1 <- base::subset(rt, rt$Order == "Group 1" | rt$Order == "Group 2")

# build up model
m1 <- lmer(RT ~ 1 + (1|Subject)+ (1|Subject:Block), data = rt1) # base model
m2 <- lmer(RT ~ Block + (1|Subject), data = rt1) # add effect of block
m3 <-  lmer(RT ~ Block + Order + (1|Subject) + (1|Subject:Block), data = rt1) # add effect of order
anova(m1,m3)
m4 <-  lmer(RT ~ Block * Order + (1|Subject) + (1|Subject:Block), data = rt1) # final model
anova(m3,m4)
anova(m4)

# investigate interaction between block and order
ud.dat <- rt1$Order=="1"
ss.dat <- rt1$Order=="2"

m4.1 <- lmer(RT ~ Block + (1|Subject) + (1|Subject:Block), data = rt1, subset = ud.dat)
anova(m4.1)
m4.2 <- lmer(RT ~ Block + (1|Subject) + (1|Subject:Block), data = rt1, subset = ss.dat)
anova(m4.2)

#### Individual Differences

rt1_beh <- merge(rt1, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <-  lmer(RT ~ ravens + Block * Order.x + (1|Subject) + (1|Subject:Block), data = rt1_beh)
m1 <- lmer(RT ~ ravens + Block * Order.x + lang_composite + (1|Subject) + (1|Subject:Block), data = rt1_beh)
anova(m0,m1)
anova(m1)

##################### Effect 2
######### ACCURACY
#### Experimental Effects

# select data
acc2 <- base::subset(dprime, dprime$Order == "Group 3" | dprime$Order == "Group 4")

# build up model
m1 <- lmer(d.prime ~ 1 + (1|Subject), data = acc2) # base model
m2 <- lmer(d.prime ~ Block + (1|Subject), data = acc2) # add effect of block
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = acc2) # add effect of order
anova(m1,m3)
anova(m3)

#### Individual Differences

acc2_beh <- merge(acc2, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <-  lmer(d.prime ~ ravens + Block + Order.x + (1|Subject), data = acc2_beh)
m1 <- lmer(d.prime ~ ravens + Block + Order.x + lang_composite + (1|Subject), data = acc2_beh)
anova(m0,m1)
anova(m1)

######### REACTION TIME
#### Experimental Effects

# select data
rt2 <- base::subset(rt,  rt$Order == "Group 3" | rt$Order == "Group 4")

# build up model
m1 <- lmer(RT ~ 1 + (1|Subject) + (1|Subject:Block), data = rt2) # base model
m2 <- lmer(RT ~ Block + (1|Subject) + (1|Subject:Block), data = rt2) # add effect of block
m3 <-  lmer(RT ~ Block + Order + (1|Subject) + (1|Subject:Block), data = rt2) # add effect of order
anova(m1,m3)
anova(m3)

#### Individual Differences

rt2_beh <- merge(rt2, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <-  lmer(RT ~ ravens + Block + Order.x + (1|Subject) + (1|Subject:Block), data = rt2_beh)
m1 <- lmer(RT ~ ravens + Block + Order.x + lang_composite + (1|Subject) + (1|Subject:Block), data = rt2_beh)
anova(m0,m1)
anova(m1)

##################### Effect 3
######### ACCURACY
#### Experimental Effects

# select data
acc3 <- base::subset(dprime,  dprime$Order == "Group 5" | dprime$Order == "Group 6")

# build up model
m1 <- lmer(d.prime ~ 1 + (1|Subject), data = acc3) # base model
m2 <- lmer(d.prime ~ Block + (1|Subject), data = acc3) # add effect of block
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = acc3) # add effect of order
anova(m1,m3)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = acc3) # final model
anova(m3,m4)
anova(m3)

#### Individual Differences

acc3_beh <- merge(acc3, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <-  lmer(d.prime ~ ravens + Block + Order.x + (1|Subject), data = acc3_beh)
m1 <- lmer(d.prime ~ ravens + Block + Order.x + lang_composite + (1|Subject), data = acc3_beh)
anova(m0,m1)
m2 <- lmer(d.prime ~ ravens + (Block + Order.x) * lang_composite + (1|Subject), data = acc3_beh)
anova(m1,m2)
anova(m1)

######### REACTION TIME
#### Experimental Effects

# select data
rt3 <- base::subset(rt, rt$Order == "Group 5" | rt$Order == "Group 6")

# build up model
m1 <- lmer(RT ~ 1 + (1|Subject) + (1|Subject:Block), data = rt3) # base model
m2 <- lmer(RT ~ Block + (1|Subject) + (1|Subject:Block), data = rt3) # add effect of block
m3 <-  lmer(RT ~ Block + Order + (1|Subject) + (1|Subject:Block), data = rt3) # add effect of order
anova(m1,m3)
m4 <-  lmer(RT ~ Block * Order + (1|Subject) + (1|Subject:Block), data = rt3) # final model
anova(m3,m4)
anova(m4)

# investigate interaction between block and order
ss.dat <- rt3$Order=="5"
sd.dat <- rt3$Order=="6"

m4.1 <- lmer(RT ~ Block + (1|Subject) + (1|Subject:Block), data = rt3, subset = ss.dat)
anova(m4.1)
m4.2 <- lmer(RT ~ Block + (1|Subject) + (1|Subject:Block), data = rt3, subset = sd.dat)
anova(m4.2)

#### Individual Differences
rt3_beh <- merge(rt3, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <-  lmer(RT ~ ravens + Block * Order.x + (1|Subject) + (1|Subject:Block), data = rt3_beh)
m1 <- lmer(RT ~ ravens + Block * Order.x + lang_composite + (1|Subject) + (1|Subject:Block), data = rt3_beh)
anova(m0,m1)
anova(m1)

################################ END OF DATA ANALYSIS PART 2: Order Effects

################################ DATA ANALYSIS PART 3: Exploratory Analyses

### Comparing UD after SS and SD

dat5 <- base::subset(dprime, dprime$Order == "Group 2" | dprime$Order == "Group 4")
dat5_ud <- base::subset(dat5, dat5$Block == "Unsupervised\nDense")

t.test(dat5_ud$d.prime ~ dat5_ud$Order)

### Comparing SS after UD and US

dat6 <- base::subset(dprime, dprime$Order == "Group 1" | dprime$Order == "Group 5")
dat6_ss <- base::subset(dat6, dat6$Block == "Supervised\nSparse")

t.test(dat6_ss$d.prime ~ dat6_ss$Order)

### Comparing UD before SS and SD

dat7 <- base::subset(dprime, dprime$Order == "Group 1" | dprime$Order == "Group 3")
dat7_ud <- base::subset(dat7, dat7$Block == "Unsupervised\nDense")

t.test(dat7_ud$d.prime ~ dat7_ud$Order)

### Comparing SS before UD and US

dat8 <- base::subset(dprime, dprime$Order == "Group 2" | dprime$Order == "Group 6")
dat8_ss <- base::subset(dat8, dat8$Block == "Supervised\nSparse")

t.test(dat8_ss$d.prime ~ dat8_ss$Order)

################################ END OF DATA ANALYSIS PART 3: Exploratory Analyses

################################ DATA ANALYSIS PART 4: Plots

# function to extract legends
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}

# set up plot for effect 1
acc1$FirstBlock <- NA
acc1$FirstBlock[acc1$Order == "Group 1" & acc1$Block == "Unsupervised\nDense"] <- "First"
acc1$FirstBlock[acc1$Order == "Group 2" & acc1$Block == "Unsupervised\nDense"] <- "Second"
acc1$FirstBlock[acc1$Order == "Group 2" & acc1$Block == "Supervised\nSparse"] <- "First"
acc1$FirstBlock[acc1$Order == "Group 1" & acc1$Block == "Supervised\nSparse"] <- "Second"

acc1_plot <- acc1 %>%
  group_by(Block, Order, FirstBlock) %>%
  summarise(sd_dpr = sd(d.prime),
            se_dpr = sd_dpr/sqrt(n()),
            d.prime = mean(d.prime))

oe1 <- ggplot(acc1, aes(FirstBlock, d.prime, fill = Block)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw(15) + geom_point(aes(y=d.prime), data=acc1_plot) +
  geom_errorbar(aes(ymin=d.prime-se_dpr, ymax=d.prime+se_dpr), width = 0.2, data=acc1_plot) +
  ylab("d'") + xlab("Block Order") + ggtitle("Sensitivity") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Block")
oe1

rt1$FirstBlock <- NA
rt1$FirstBlock[rt1$Order == "Group 1" & rt1$Block == "Unsupervised\nDense"] <- "First"
rt1$FirstBlock[rt1$Order == "Group 2" & rt1$Block == "Unsupervised\nDense"] <- "Second"
rt1$FirstBlock[rt1$Order == "Group 2" & rt1$Block == "Supervised\nSparse"] <- "First"
rt1$FirstBlock[rt1$Order == "Group 1" & rt1$Block == "Supervised\nSparse"] <- "Second"

rt1_plot <- rt1 %>%
  group_by(Block, Order, FirstBlock) %>%
  summarise(sd_rt = sd(RT),
            se_rt = sd_rt/sqrt(n()),
            RT = mean(RT))

rt_oe1 <- ggplot(rt1, aes(FirstBlock, RT, fill = Block)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw(15) + geom_point(aes(y=RT), data=rt1_plot) +
  geom_errorbar(aes(ymin=RT-se_rt, ymax=RT+se_rt), width = 0.2, data=rt1_plot) +
  ylab("Reaction Time (s)") + xlab("Block Order") + ggtitle("Reaction Time") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Block")
rt_oe1

mylegend<-g_legend(oe1)
p3 <- grid.arrange(arrangeGrob(oe1 + theme(legend.position="none"),
                               rt_oe1 + theme(legend.position="none"),
                               nrow=2),
                   mylegend, ncol=2, widths = c(5,2), top = textGrob("Order Analysis 1: Matching Conditions",gp=gpar(fontsize=20)))

# set up plot for effect 2
acc2$FirstBlock <- NA
acc2$FirstBlock[acc2$Order == "Group 3" & acc2$Block == "Unsupervised\nDense"] <- "First"
acc2$FirstBlock[acc2$Order == "Group 4" & acc2$Block == "Unsupervised\nDense"] <- "Second"
acc2$FirstBlock[acc2$Order == "Group 4" & acc2$Block == "Supervised\nDense"] <- "First"
acc2$FirstBlock[acc2$Order == "Group 3" & acc2$Block == "Supervised\nDense"] <- "Second"

acc2_plot <- acc2 %>%
  group_by(Block, Order, FirstBlock) %>%
  summarise(sd_dpr = sd(d.prime),
            se_dpr = sd_dpr/sqrt(n()),
            d.prime = mean(d.prime))

oe2 <- ggplot(acc2, aes(FirstBlock, d.prime, fill = Block)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw(15) + geom_point(aes(y=d.prime), data=acc2_plot) +
  geom_errorbar(aes(ymin=d.prime-se_dpr, ymax=d.prime+se_dpr), width = 0.2, data=acc2_plot) +
  ylab("d'") + xlab("Block Order") + ggtitle("Sensitivity") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Block")
oe2

rt2$FirstBlock <- NA
rt2$FirstBlock[rt2$Order == "Group 3" & rt2$Block == "Unsupervised\nDense"] <- "First"
rt2$FirstBlock[rt2$Order == "Group 4" & rt2$Block == "Unsupervised\nDense"] <- "Second"
rt2$FirstBlock[rt2$Order == "Group 4" & rt2$Block == "Supervised\nDense"] <- "First"
rt2$FirstBlock[rt2$Order == "Group 3" & rt2$Block == "Supervised\nDense"] <- "Second"

rt2_plot <- rt2 %>%
  group_by(Block, Order, FirstBlock) %>%
  summarise(sd_rt = sd(RT),
            se_rt = sd_rt/sqrt(n()),
            RT = mean(RT))

rt_oe2 <- ggplot(rt2, aes(FirstBlock, RT, fill = Block)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw(15) + geom_point(aes(y=RT), data=rt2_plot) +
  geom_errorbar(aes(ymin=RT-se_rt, ymax=RT+se_rt), width = 0.2, data=rt2_plot) +
  ylab("Reaction Time (s)") + xlab("Block Order") + ggtitle("Reaction Time") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Block")
rt_oe2

mylegend<-g_legend(oe2)
p3 <- grid.arrange(arrangeGrob(oe2 + theme(legend.position="none"),
                               rt_oe2 + theme(legend.position="none"),
                               nrow=2),
                   mylegend, ncol=2, widths = c(5,2), top = textGrob("Order Analysis 2: Dense Stimuli",gp=gpar(fontsize=20)))

# set up plot for effect 3
acc3$FirstBlock <- NA
acc3$FirstBlock[acc3$Order == "Group 5" & acc3$Block == "Unsupervised\nSparse"] <- "First"
acc3$FirstBlock[acc3$Order == "Group 6" & acc3$Block == "Unsupervised\nSparse"] <- "Second"
acc3$FirstBlock[acc3$Order == "Group 6" & acc3$Block == "Supervised\nSparse"] <- "First"
acc3$FirstBlock[acc3$Order == "Group 5" & acc3$Block == "Supervised\nSparse"] <- "Second"

acc3_plot <- acc3 %>%
  group_by(Block, Order, FirstBlock) %>%
  summarise(sd_dpr = sd(d.prime),
            se_dpr = sd_dpr/sqrt(n()),
            d.prime = mean(d.prime))

oe3 <- ggplot(acc3, aes(FirstBlock, d.prime, fill = Block)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw(15) + geom_point(aes(y=d.prime), data=acc3_plot) +
  geom_errorbar(aes(ymin=d.prime-se_dpr, ymax=d.prime+se_dpr), width = 0.2, data=acc3_plot) +
  ylab("d'") + xlab("Block Order") + ggtitle("Sensitivity") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Block")
oe3

rt3$FirstBlock <- NA
rt3$FirstBlock[rt3$Order == "Group 5" & rt3$Block == "Unsupervised\nSparse"] <- "First"
rt3$FirstBlock[rt3$Order == "Group 6" & rt3$Block == "Unsupervised\nSparse"] <- "Second"
rt3$FirstBlock[rt3$Order == "Group 6" & rt3$Block == "Supervised\nSparse"] <- "First"
rt3$FirstBlock[rt3$Order == "Group 5" & rt3$Block == "Supervised\nSparse"] <- "Second"

rt3_plot <- rt3 %>%
  group_by(Block, Order, FirstBlock) %>%
  summarise(sd_rt = sd(RT),
            se_rt = sd_rt/sqrt(n()),
            RT = mean(RT))

rt_oe3 <- ggplot(rt3, aes(FirstBlock, RT, fill = Block)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw(15) + geom_point(aes(y=RT), data=rt3_plot) +
  geom_errorbar(aes(ymin=RT-se_rt, ymax=RT+se_rt), width = 0.2, data=rt3_plot) +
  ylab("Reaction Time (s)") + xlab("Block Order") + ggtitle("Reaction Time") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Block")
rt_oe3

mylegend<-g_legend(oe3)
p3 <- grid.arrange(arrangeGrob(oe3 + theme(legend.position="none"),
                               rt_oe3 + theme(legend.position="none"),
                               nrow=2),
                   mylegend, ncol=2, widths = c(5,2), top = textGrob("Order Analysis 3: Sparse Stimuli",gp=gpar(fontsize=20)))

## Language ability & Accuracy in effect 3

acc3_beh %>%
  group_by(Subject, lang_composite) %>%
  summarise(d.prime = mean(d.prime)) %>%
  ggplot(aes(lang_composite, d.prime)) + geom_point() + geom_smooth(method = "lm", se = FALSE) +
  theme_bw(15) + xlab("Language Ability") + ylab("d'") + ggtitle("Language Ability and Sensitivity in Sparse Blocks")

cor.test(acc3_beh$lang_composite, acc3_beh$d.prime)


################################ END OF DATA ANALYSIS PART 4: Plots
