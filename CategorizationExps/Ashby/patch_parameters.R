# Parameters taken from Maddox, Ashby, & Bohil (2003)

setwd("~/dissertation/CategorizationExps/Ashby")

ii.freqa <- as.integer(rnorm(40, mean = 272, sd = 4538))
ii.freqa = .25*(ii.freqa/50)
ii.ora <- as.integer(rnorm(40, mean = 153, sd = 4538))
ii.ora <- ii.ora*(pi/500)

rb.freqa <- as.integer(rnorm(40, mean = 260, sd = 75))
rb.freqa = .25*(rb.freqa/50)
rb.ora <- as.integer(rnorm(40, mean = 125, sd = 9000))
rb.ora <- rb.ora*(pi/500)
paramsa <- data.frame(cbind(ii.freqa, ii.ora, rb.freqa, rb.ora))


ii.freqb <- as.integer(rnorm(40, mean = 327, sd = 4538))
ii.freqb = .25*(ii.freqb/50)
ii.orb <- as.integer(rnorm(40, mean = 97, sd = 4538))
ii.orb <- ii.orb*(pi/500)

rb.freqb <- as.integer(rnorm(40, mean = 340, sd = 75))
rb.freqb = .25*(rb.freqb/50)
rb.orb <- as.integer(rnorm(40, mean = 125, sd = 9000))
rb.orb <- rb.orb*(pi/500)
paramsb <- data.frame(cbind(ii.freqb, ii.orb, rb.freqb, rb.orb))

paramsa$category <- "a"
paramsb$category <- "b"

names(paramsa) <- c("ii_freq", "ii_or", "rb_freq", "rb_or", "category")
names(paramsb) <- c("ii_freq", "ii_or", "rb_freq", "rb_or", "category")

params <- rbind(paramsa, paramsb)
params.ii <- params[,c(1,2,5)]
params.rb <- params[,c(3,4,5)]

write.csv(params.ii, "II_PatchParameters.csv", row.names=FALSE)
write.csv(params.rb, "RB_PatchParameters.csv", row.names=FALSE)