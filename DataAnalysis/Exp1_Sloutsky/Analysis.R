setwd("~/dissertation/DataAnalysis/Exp1_Sloutsky")
dat <- read.table("fulldata.tsv", header = TRUE)
library(ggplot2)
library(reshape2)
library(reshape)
library(lme4)
library(car)
library(neuropsychology)
library(plyr)
library(influence.ME)
library(lmerTest)
library(Rmisc)
library(dplyr)
orders <- data.frame(dat$Subject, dat$Order)
ord <- unique(orders)
names(ord) <- c("Subject", "Order")
sub_info <- read.csv("subject_info.csv")

dat$Block <- revalue(dat$Block, c("SupervisedSparse"="Supervised\nSparse",
               "SupervisedDense"="Supervised\nDense",
               "UnsupervisedSparse"="Unsupervised\nSparse",
               "UnsupervisedDense"="Unsupervised\nDense"))

#### ACCURACY

## calculate d' (hit - false alarm)

dat$response_type <- NA
dat$response_type[dat$StimType == "target" & dat$RESP == "target"] <- "Hit"
dat$response_type[dat$StimType == "target" & dat$RESP == "nottarget"] <- "Miss"
dat$response_type[dat$StimType == "nottarget" & dat$RESP == "nottarget"] <- "CorRej"
dat$response_type[dat$StimType == "nottarget" & dat$RESP == "target"] <- "FalseAlarm"
dat$response_type[substr(dat$Stimulus,1,5) == "catch" & dat$Accuracy == 1] <- "CatchGood"

counts <- plyr::count(dat, c('Subject', 'Block', 'response_type'))
counts_cast <- data.frame(dcast(data = counts, formula = Subject + Block ~ response_type, value.var="freq"))
counts_cast <- counts_cast[,-8]
counts_cast[is.na(counts_cast)] <- 0

dprime <- data.frame(dprime(counts_cast$Hit, counts_cast$Miss, counts_cast$FalseAlarm, counts_cast$CorRej))
dprime <- cbind(dprime, counts_cast$Subject, counts_cast$Block)

dprime_all <- dprime[,c(6,7,1)]
names(dprime_all) <- c("Subject", "Block", "d.prime")
dprime_all <- merge(dprime_all, ord, by = "Subject")

dat_catch <- dat[substr(dat$Stimulus,1,5) == "catch",]
catch_acc <- data.frame(tapply(dat_catch$Accuracy, list(dat_catch$Subject, dat_catch$Block), mean, na.rm = TRUE))
catch_acc$Subject <- row.names(catch_acc)
catch_acc_melt <- melt.data.frame(catch_acc, id.vars = "Subject", na.rm = TRUE)
catch_remove <- catch_acc_melt[catch_acc_melt$value < 0.75,]
names(catch_remove) <- c("Subject", "Block", "Acc")
catch_remove$Block <- revalue(catch_remove$Block, c("Supervised.Sparse"="Supervised\nSparse",
                                  "Supervised.Dense"="Supervised\nDense",
                                  "Unsupervised.Sparse"="Unsupervised\nSparse",
                                  "Unsupervised.Dense"="Unsupervised\nDense"))

dprime_all$Subject <- as.character(dprime_all$Subject)
dprime_all$key <- NA
dprime_all$key <- paste0(dprime_all$Subject, dprime_all$Block)

catch_remove$key <- NA
catch_remove$key <- paste0(catch_remove$Subject, catch_remove$Block)

dprime_all$d.prime[dprime_all$key %in% catch_remove$key] <- NA

p1 <- ggplot(dprime_all, aes(Block, d.prime, fill = Block)) + geom_violin() + facet_grid(.~Order) + theme_bw()
p1

dprime_ages <- merge(dprime_all, sub_info, by.x = "Subject", by.y = "Subject.Number")

catch_remove_ord <- merge(catch_remove, ord, by = "Subject")
table(catch_remove_ord$Order, catch_remove_ord$Block)


pcts <- data.frame(counts_cast$Hit, counts_cast$Miss, counts_cast$FalseAlarm, counts_cast$CorRej, counts_cast$CatchGood)
pcts <- cbind(pcts, counts_cast$Subject, counts_cast$Block)
pcts$Hit.p <- pcts$counts_cast.Hit/16
pcts$FA.p <- pcts$counts_cast.FalseAlarm/16
pcts$Miss.p <- pcts$counts_cast.Miss/16
pcts$CorRej.p <- pcts$counts_cast.CorRej/16
pcts$acc <- pcts$Hit.p - pcts$FA.p
pcts$catch.p <- pcts$counts_cast.CatchGood/8
names(pcts) <- c("Hit", "Miss","FA", "CorRej", "CatchGood", "Subject", "Block", "Hit.p" ,"FA.p", "Miss.p", "CorRej.p", "acc", "catch.p")

pcts.good <- subset(pcts, catch.p >=0.75)
p1 <- ggplot(aes(Block, acc), data = pcts.good) + geom_violin() + geom_point()
p1

by(pcts.good$acc, pcts.good$Block, mean, na.rm= TRUE)


### basic info
demo <- dprime_ages[,c(1,4,6:7)]
demo <- unique(demo)

mean(demo$Age, na.rm = TRUE)
table(demo$Gender)
table(demo$Order)


### Effect 1
dat1 <- subset(dprime_all, dprime_all$Order <=2)

p1 <- ggplot(dat1, aes(Block, d.prime, fill = Block)) + geom_boxplot() + facet_grid(.~Order) + theme_bw()
p1

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat1)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat1)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat1)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat1)

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

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat1)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat1)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat1)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat1)

ud.dat <- subset(dat1, dat1$Order==1)
ss.dat <- subset(dat1, dat1$Order==2)

m4.1 <- lmer(d.prime ~ Block + (1|Subject), data = ud.dat)
m4.2 <- lmer(d.prime ~ Block + (1|Subject), data = ss.dat)

summary(m4.1)
summary(m4.2)

dat1$Order <- as.factor(dat1$Order)
dat1$Order <- revalue(dat1$Order, c("1"="Group 1",
                                  "2"="Group 2"))
dat1$`Block Order` <- NA
dat1$`Block Order` <- dat1$FirstBlock
dat1_sum <- summarySE(dat1, measurevar = "d.prime", 
                      groupvars = c("Block", "Order", "`Block Order`"), na.rm = TRUE)


p1 <- ggplot(dat1, aes(Block, d.prime, fill = `Block Order`)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw() + geom_point(aes(y=d.prime), data=dat1_sum) +
  geom_errorbar(aes(ymin=d.prime-se, ymax=d.prime+se), width = 0.2, data=dat1_sum) +
  ylab("d'") + xlab("Block") + ggtitle("Order Effect 1: Matching Conditions") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"))
p1


### Effect 2

dat2 <- subset(dprime_all, dprime_all$Order == 3 | dprime_all$Order == 4)

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

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat2)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat2)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat2)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat2)

dat2$`Block Order` <- NA
dat2$`Block Order` <- dat2$FirstBlock
dat2_sum <- summarySE(dat2, measurevar = "d.prime", 
                      groupvars = c("Block", "Order", "`Block Order`"), na.rm = TRUE)


p1 <- ggplot(dat2, aes(Block, d.prime, fill = `Block Order`)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw() + geom_point(aes(y=d.prime), data=dat2_sum) +
  geom_errorbar(aes(ymin=d.prime-se, ymax=d.prime+se), width = 0.2, data=dat2_sum) +
  ylab("d'") + xlab("Block") + ggtitle("Order Effect 2: Dense Stimuli") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"))
p1


### Effect 3

dat3 <- subset(dprime_all, dprime_all$Order == 5 | dprime_all$Order == 6)

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

m1 <- lmer(d.prime ~ 1 + (1|Subject), data = dat3)
m2 <- lmer(d.prime ~ Block + (1|Subject), data = dat3)
m3 <-  lmer(d.prime ~ Block + Order + (1|Subject), data = dat3)
m4 <-  lmer(d.prime ~ Block * Order + (1|Subject), data = dat3)

dat3$`Block Order` <- NA
dat3$`Block Order` <- dat3$FirstBlock
dat3_sum <- summarySE(dat3, measurevar = "d.prime", 
                      groupvars = c("Block", "Order", "`Block Order`"), na.rm = TRUE)


p1 <- ggplot(dat3, aes(Block, d.prime, fill = `Block Order`)) + geom_violin() + 
  facet_grid(.~Order) + theme_bw() + geom_point(aes(y=d.prime), data=dat3_sum) +
  geom_errorbar(aes(ymin=d.prime-se, ymax=d.prime+se), width = 0.2, data=dat3_sum) +
  ylab("d'") + xlab("Block") + ggtitle("Order Effect 3: Sparse Stimuli") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_manual(values=c("#e69f00", "#009e73"))
p1


### Comparing UD after SS and SD

dat5 <- subset(dprime_all, dprime_all$Order == 2 | dprime_all$Order == 4)
dat5_ud <- subset(dat5, dat5$Block == "Unsupervised\nDense")

t.test(dat5_ud$d.prime ~ dat5_ud$Order)

### Comparing SS after UD and US

dat6 <- subset(dprime_all, dprime_all$Order == 1 | dprime_all$Order == 5)
dat6_ss <- subset(dat6, dat6$Block == "Supervised\nSparse")

t.test(dat6_ss$d.prime ~ dat6_ss$Order)

### Comparing UD before SS and SD

dat7 <- subset(dprime_all, dprime_all$Order == 1 | dprime_all$Order == 3)
dat7_ud <- subset(dat7, dat7$Block == "Unsupervised\nDense")

t.test(dat7_ud$d.prime ~ dat7_ud$Order)

### Comparing SS before UD and US

dat8 <- subset(dprime_all, dprime_all$Order == 2 | dprime_all$Order == 6)
dat8_ss <- subset(dat8, dat8$Block == "Supervised\nSparse")

t.test(dat8_ss$d.prime ~ dat8_ss$Order)

#### RT

test <- data.frame(tapply(dat$RT, list(dat$Subject, dat$Block), mean, na.rm = TRUE))
test$Subject <- row.names(test)

merge <- merge(test, ord, by = "Subject")
merge.melt <- melt.data.frame(merge, id.vars = c("Subject", "Order"), variable.name = "Block", na.rm = TRUE)
names(merge.melt) <- c("Subject", "Order", "Block", "RT")

p1 <- ggplot(merge.melt, aes(Block, RT, fill = Block)) + geom_violin() + facet_grid(.~Order) + theme_bw()
p1

### Effect 1

dat1 <- subset(merge.melt, merge.melt$Order <=2)

m1 <- lmer(RT ~ 1 + (1|Subject), data = dat1)
m2 <- lmer(RT ~ Block + (1|Subject), data = dat1)
m3 <-  lmer(RT ~ Block + Order + (1|Subject), data = dat1)
m4 <-  lmer(RT ~ Block * Order + (1|Subject), data = dat1)

### Effect 2

dat2 <- subset(merge.melt, merge.melt$Order == 3 | merge.melt$Order == 4)

m1 <- lmer(RT ~ 1 + (1|Subject), data = dat2)
m2 <- lmer(RT ~ Block + (1|Subject), data = dat2)
m3 <-  lmer(RT ~ Block + Order + (1|Subject), data = dat2)
m4 <-  lmer(RT ~ Block * Order + (1|Subject), data = dat2)

### Effect 4

dat3 <- subset(merge.melt, merge.melt$Order == 5 | merge.melt$Order == 6)

m1 <- lmer(RT ~ 1 + (1|Subject), data = dat3)
m2 <- lmer(RT ~ Block + (1|Subject), data = dat3)
m3 <-  lmer(RT ~ Block + Order + (1|Subject), data = dat3)
m4 <-  lmer(RT ~ Block * Order + (1|Subject), data = dat3)







