# Parameters taken from Maddox, Ashby, & Bohil (2003)

setwd("~/dissertation/CategorizationExps/Ashby")
ii.freq <- as.integer(rnorm(40, mean = 272, sd = 4538))
ii.freq = .25*(ii.freq/50)
ii.or <- as.integer(rnorm(40, mean = 153, sd = 4538))
ii.or <- ii.or*(pi/500)

rb.freq <- as.integer(rnorm(40, mean = 260, sd = 75))
rb.freq = .25*(rb.freq/50)
rb.or <- as.integer(rnorm(40, mean = 125, sd = 9000))
rb.or <- rb.or*(pi/500)
params <- cbind(ii.freq, ii.or, rb.freq, rb.or)

write.csv(params, "PatchParamters.csv")