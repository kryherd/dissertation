setwd("~/dissertation/DataAnalysis/Exp1_Sloutsky")
dat <- read.table("fulldata.tsv", header = TRUE)
library(tidyverse)
library(lme4)
library(car)
library(neuropsychology)
library(influence.ME)
library(lmerTest)
library(caret)
library(ggcorrplot)

orders <- data.frame(dat$Subject, dat$Order)
ord <- unique(orders)
names(ord) <- c("Subject", "Order")

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

# plot each order effect
ggplot(dprime, aes(Block, d.prime, fill = Block)) + geom_violin() + facet_grid(.~Order) + theme_bw()

# plot with percentages
acc_counts %>%
  group_by(Subject, Block) %>%
  filter(CatchGood > 5) %>%
  summarise(acc = Hit/16 - FalseAlarm/16) %>%
  inner_join(.,ord, by = "Subject") %>%
  ggplot(aes(Block, acc)) + geom_violin() + geom_jitter(width = 0.25) + theme_bw() + 
  ylab("Accuracy (Hit - FA)")  + ggtitle("Performance by block (collapsed across orders)")

acc_counts %>%
  group_by(Subject, Block) %>%
  filter(CatchGood > 5) %>%
  summarise(acc = Hit/16 - FalseAlarm/16) %>%
  group_by(Block) %>%
  summarise(m_acc = mean(acc))

### basic info

beh_data <- acc_counts %>%
  inner_join(beh, by = c("Subject" = "SubjectID")) %>%
  inner_join(ord, by = "Subject") %>%
  select(Subject, celf_rs_raw:Order) %>%
  distinct()

mean(beh_data$age, na.rm = TRUE)
table(beh_data$gender)
table(beh_data$Order)


### Effect 1
dat1 <- base::subset(dprime, dprime$Order <=2)

p1 <- ggplot(dat1, aes(Block, d.prime, fill = Block)) + geom_boxplot() + facet_grid(.~Order) + theme_bw()
p1

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat1)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat1)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat1)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat1)
anova(m4)

ud.dat <- base::subset(dat1, dat1$Order==1)
ss.dat <- base::subset(dat1, dat1$Order==2)

m4.1 <- lmer(d.prime ~ Block + (1|Subject), data = ud.dat)
m4.2 <- lmer(d.prime ~ Block + (1|Subject), data = ss.dat)

summary(m4.1)
summary(m4.2)

infl <- influence(m4, obs = TRUE)
max(cooks.distance(infl))
mean(cooks.distance(infl))
plot(infl, which = "cook")

dat1$FirstBlock <- NA
dat1$FirstBlock[dat1$Order == 1 & dat1$Block == "Unsupervised\nDense"] <- "First"
dat1$FirstBlock[dat1$Order == 2 & dat1$Block == "Unsupervised\nDense"] <- "Second"
dat1$FirstBlock[dat1$Order == 2 & dat1$Block == "Supervised\nSparse"] <- "First"
dat1$FirstBlock[dat1$Order == 1 & dat1$Block == "Supervised\nSparse"] <- "Second"

p1 <- ggplot(dat1, aes(Block, d.prime, fill = FirstBlock)) + geom_boxplot() + facet_grid(.~Order) + theme_bw()
p1


dat1$Order <- as.factor(dat1$Order)
dat1$Order <- plyr::revalue(dat1$Order, c("1"="Group 1",
                                  "2"="Group 2"))

dat1$`Block Order` <- NA
dat1$`Block Order` <- dat1$FirstBlock

dat1_plot <- dat1 %>%
  group_by(Block, Order, `Block Order`) %>%
  summarise(sd_dpr = sd(d.prime),
            se_dpr = sd_dpr/sqrt(n()),
            d.prime = mean(d.prime))

p1 <- ggplot(dat1, aes(Block, d.prime, fill = `Block Order`)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw() + geom_point(aes(y=d.prime), data=dat1_plot) +
  geom_errorbar(aes(ymin=d.prime-se_dpr, ymax=d.prime+se_dpr), width = 0.2, data=dat1_plot) +
  ylab("d'") + xlab("Block") + ggtitle("Order Effect 1: Matching Conditions") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Order")
p1


### Effect 2

dat2 <- base::subset(dprime, dprime$Order == 3 | dprime$Order == 4)

p1 <- ggplot(dat2, aes(Block, d.prime, fill = Block)) + geom_boxplot() + facet_grid(.~Order) + theme_bw()
p1

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat2)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat2)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat2)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat2)

infl <- influence(m4, obs = TRUE)
max(cooks.distance(infl))
mean(cooks.distance(infl))
plot(infl, which = "cook")

# no big outliers

dat2$FirstBlock <- NA
dat2$FirstBlock[dat2$Order == 3 & dat2$Block == "Unsupervised\nDense"] <- "First"
dat2$FirstBlock[dat2$Order == 4 & dat2$Block == "Unsupervised\nDense"] <- "Second"
dat2$FirstBlock[dat2$Order == 4 & dat2$Block == "Supervised\nDense"] <- "First"
dat2$FirstBlock[dat2$Order == 3 & dat2$Block == "Supervised\nDense"] <- "Second"

p1 <- ggplot(dat2, aes(Block, d.prime, fill = FirstBlock)) + geom_boxplot() + facet_grid(.~Order) + theme_bw()
p1


dat2$`Block Order` <- NA
dat2$`Block Order` <- dat2$FirstBlock
dat2_plot <- dat2 %>%
  group_by(Block, Order, `Block Order`) %>%
  summarise(sd_dpr = sd(d.prime),
            se_dpr = sd_dpr/sqrt(n()),
            d.prime = mean(d.prime))

p1 <- ggplot(dat2, aes(Block, d.prime, fill = `Block Order`)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw() + geom_point(aes(y=d.prime), data=dat2_plot) +
  geom_errorbar(aes(ymin=d.prime-se_dpr, ymax=d.prime+se_dpr), width = 0.2, data=dat2_plot) +
  ylab("d'") + xlab("Block") + ggtitle("Order Effect 2: Dense Stimuli") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Order")
p1

### Effect 3

dat3 <- base::subset(dprime, dprime$Order == 5 | dprime$Order == 6)

p1 <- ggplot(dat3, aes(Block, d.prime, fill = Block)) + geom_boxplot() + facet_grid(.~Order) + theme_bw()
p1

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat3)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat3)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat3)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat3)

infl <- influence(m4, obs = TRUE)
max(cooks.distance(infl))
mean(cooks.distance(infl))
plot(infl, which = "cook")

# no big outliers

dat3$FirstBlock <- NA
dat3$FirstBlock[dat3$Order == 5 & dat3$Block == "Unsupervised\nSparse"] <- "First"
dat3$FirstBlock[dat3$Order == 6 & dat3$Block == "Unsupervised\nSparse"] <- "Second"
dat3$FirstBlock[dat3$Order == 6 & dat3$Block == "Supervised\nSparse"] <- "First"
dat3$FirstBlock[dat3$Order == 5 & dat3$Block == "Supervised\nSparse"] <- "Second"

p1 <- ggplot(dat3, aes(Block, d.prime, fill = FirstBlock)) + geom_boxplot() + facet_grid(.~Order) + theme_bw() 
p1

dat3$`Block Order` <- NA
dat3$`Block Order` <- dat3$FirstBlock
dat3_plot <- dat3 %>%
  group_by(Block, Order, `Block Order`) %>%
  summarise(sd_dpr = sd(d.prime),
            se_dpr = sd_dpr/sqrt(n()),
            d.prime = mean(d.prime))

p1 <- ggplot(dat3, aes(Block, d.prime, fill = `Block Order`)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw() + geom_point(aes(y=d.prime), data=dat3_plot) +
  geom_errorbar(aes(ymin=d.prime-se_dpr, ymax=d.prime+se_dpr), width = 0.2, data=dat3_plot) +
  ylab("d'") + xlab("Block") + ggtitle("Order Effect 3: Sparse Stimuli") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"), name = "Order")
p1



### Comparing UD after SS and SD

dat5 <- base::subset(dprime, dprime$Order == 2 | dprime$Order == 4)
dat5_ud <- base::subset(dat5, dat5$Block == "Unsupervised\nDense")

t.test(dat5_ud$d.prime ~ dat5_ud$Order)

### Comparing SS after UD and US

dat6 <- base::subset(dprime, dprime$Order == 1 | dprime$Order == 5)
dat6_ss <- base::subset(dat6, dat6$Block == "Supervised\nSparse")

t.test(dat6_ss$d.prime ~ dat6_ss$Order)

### Comparing UD before SS and SD

dat7 <- base::subset(dprime, dprime$Order == 1 | dprime$Order == 3)
dat7_ud <- base::subset(dat7, dat7$Block == "Unsupervised\nDense")

t.test(dat7_ud$d.prime ~ dat7_ud$Order)

### Comparing SS before UD and US

dat8 <- base::subset(dprime, dprime$Order == 2 | dprime$Order == 6)
dat8_ss <- base::subset(dat8, dat8$Block == "Supervised\nSparse")

t.test(dat8_ss$d.prime ~ dat8_ss$Order)

########### Individual Differences & ACC

# read in KTEA v1 subjects

kteav1 <- read.csv("ktea_v1_data.csv")
kteav1_sums <- kteav1 %>% select(Subject, ends_with(".ACC")) %>%
  gather(key = "Question", value = "ACC", -Subject) %>%
  dplyr::filter(!grepl("PRAC", Question)) %>%
  group_by(Subject) %>%
  summarise(total_correct = sum(ACC, na.rm = TRUE))

kteav2 <- read.csv("ktea_v2_data.csv")
kteav2_sums <- kteav2 %>% group_by(Subject) %>%
  summarise(total_correct = sum(Question.ACC, na.rm = TRUE))

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

ktea_nd <- merge(ktea_sums, nd, by = "Subject", all = TRUE)
names(ktea_nd) <- c("SubjectID", "ktea", "nd_raw", "nd_ss")

beh <- read.csv("beh_data.csv")
all_beh <- merge(ktea_nd, beh, by = "SubjectID", all = TRUE)

## looking at individual difference measures 1st

all_beh$towre_pde_ss[all_beh$towre_pde_ss == ">120"] <- "120"
all_beh$towre_pde_ss <- as.numeric(levels(all_beh$towre_pde_ss))[all_beh$towre_pde_ss]

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

# look at correlations
cor.mat <- round(cor(all_beh[,c(14:19)], use = "complete.obs"), 1)
p.mat <- cor_pmat(all_beh[,c(14:19)])
ggcorrplot(cor.mat, type = "lower", p.mat = p.mat)
ggcorrplot(cor.mat, type = "lower", lab = TRUE)


library(psych)
pca_dat <- all_beh[,c(14,15,16,18,19)]
pca_dat <- pca_dat[complete.cases(pca_dat),]
KMO(pca_dat)
cor.mat <- cor(pca_dat)
cortest.bartlett(cor.mat, n = 218)
beh.pca <- prcomp(pca_dat)
eigen(cor.mat)
summary(beh.pca)
print(beh.pca)
plot(beh.pca, type = "l")

# they all load on the same factor. so I'll just make a simple composite.

all_beh$lang_composite <- rowMeans(all_beh[,c(14,15,16,18,19)], na.rm = TRUE)
all_beh$lang_composite <- scale(all_beh$lang_composite, center = FALSE)
hist(all_beh$lang_composite)

## effect 1

dat1 <- base::subset(dprime, dprime$Order <=2)
dat1_beh <- merge(dat1, all_beh, by.x = "Subject", by.y = "SubjectID")

m0 <- lmer(d.prime ~ 1 + (1|Subject), data = dat1_beh)
m1 <- lmer(d.prime ~ ravens_tf + (1|Subject), data = dat1_beh)
m2 <- lmer(d.prime ~ ravens + Block + (1|Subject), data = dat1_beh)
m3 <-  lmer(d.prime ~ ravens + Block + Order + (1|Subject), data = dat1_beh)
m4 <-  lmer(d.prime ~ ravens + Block * Order + (1|Subject), data = dat1_beh)
m5 <- lmer(d.prime ~ ravens + Block * Order + lang_composite + (1|Subject), data = dat1_beh)
anova(m4,m5)

## effect 2

dat2 <- base::subset(dprime, dprime$Order == 3 | dprime$Order == 4)
dat2_beh <- merge(dat2, all_beh, by.x = "Subject", by.y = "SubjectID")

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat2_beh)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat2_beh)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat2_beh)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat2_beh)
m5 <- lmer(d.prime ~ Block * Order + lang_composite + (1|Subject), data = dat2_beh)
anova(m4,m5)

## effect 2

dat3 <- base::subset(dprime, dprime$Order >= 5)
dat3_beh <- merge(dat3, all_beh, by.x = "Subject", by.y = "SubjectID")

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat3_beh)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat3_beh)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat3_beh)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat3_beh)
m5 <- lmer(d.prime ~ Block * Order + lang_composite + (1|Subject), data = dat3_beh)
anova(m4,m5)

ggplot(dat3_beh, aes(lang_composite, d.prime)) + geom_point() + geom_smooth(method = "lm", se = FALSE) + theme_bw() +
  facet_grid(Order~Block)

#### RT

test <- data.frame(tapply(dat$RT, list(dat$Subject, dat$Block), mean, na.rm = TRUE))
test$Subject <- row.names(test)

merge <- merge(test, ord, by = "Subject")
merge.melt <- melt.data.frame(merge, id.vars = c("Subject", "Order"), variable.name = "Block", na.rm = TRUE)
names(merge.melt) <- c("Subject", "Order", "Block", "RT")

p1 <- ggplot(merge.melt, aes(Block, RT, fill = Block)) + geom_violin() + facet_grid(.~Order) + theme_bw()
p1

### Effect 1

dat1 <- base::subset(merge.melt, merge.melt$Order <=2)

m1 <- lmer(RT ~ 1 + (1|Subject), data = dat1)
m2 <- lmer(RT ~ Block + (1|Subject), data = dat1)
m3 <-  lmer(RT ~ Block + Order + (1|Subject), data = dat1)
m4 <-  lmer(RT ~ Block * Order + (1|Subject), data = dat1)

### Effect 2

dat2 <- base::subset(merge.melt, merge.melt$Order == 3 | merge.melt$Order == 4)

m1 <- lmer(RT ~ 1 + (1|Subject), data = dat2)
m2 <- lmer(RT ~ Block + (1|Subject), data = dat2)
m3 <-  lmer(RT ~ Block + Order + (1|Subject), data = dat2)
m4 <-  lmer(RT ~ Block * Order + (1|Subject), data = dat2)

### Effect 4

dat3 <- base::subset(merge.melt, merge.melt$Order == 5 | merge.melt$Order == 6)

m1 <- lmer(RT ~ 1 + (1|Subject), data = dat3)
m2 <- lmer(RT ~ Block + (1|Subject), data = dat3)
m3 <-  lmer(RT ~ Block + Order + (1|Subject), data = dat3)
m4 <-  lmer(RT ~ Block * Order + (1|Subject), data = dat3)







