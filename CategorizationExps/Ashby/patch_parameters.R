# Parameters taken from Maddox, Ashby, & Bohil (2003)

setwd("~/dissertation/CategorizationExps/Ashby")

library(ggplot2)
library(MASS)
library(cowplot)

# create vectors containing mean frequencies and orientations for categories A and B
rb.mean.a <- c(260, 125)
rb.mean.b <- c(340, 125)
# create covariance matrices
rb.cov.a = matrix(c(75,0,0, 9000), nrow=2, ncol=2)
rb.cov.b = matrix(c(75,0,0, 9000), nrow=2, ncol=2)
# sample from bivariate normal distribution using above parameters
rba <- data.frame(mvrnorm(40, mu = rb.mean.a, Sigma = rb.cov.a)) 
colnames(rba) <- c("freq","orientation")
rba$Category <- "A"
rbb <- data.frame(mvrnorm(40, mu = rb.mean.b, Sigma = rb.cov.b))
colnames(rbb) <- c("freq","orientation")
rbb$Category <- "B"

rb <-rbind(rba, rbb)

# transform parameters using formulae from paper
## frequency is modified to make differences more visible
rb$freq.tr <- .25+(rb$freq/100)
rb$orient.tr <- rb$orientation*(pi/500) 

# create function for 45 degree rotation
rotate <- function(df, degree) {
  dfr <- df
  degree <- pi * degree / 180
  l <- sqrt(dfr$freq^2 + df$orientation^2)
  teta <- atan(df$orientation / df$freq)
  dfr$freq <- round(l * cos(teta - degree))
  dfr$orientation <- round(l * sin(teta - degree))
  return(dfr)
}

# rotate RB parameters by 45 degrees
rb.rotate <- rb[,c(1,2)]
ii <- rotate(rb.rotate, 45)

ii <- cbind(ii, rb$Category)
colnames(ii)[3] <- "Category"

# transform variables
ii$freq.tr <- .25+(ii$freq/100)
ii$orient.tr <- ii$orientation*(pi/500) 

# change radians to degrees
rad2deg <- function(rad) {(rad * 180) / (pi)}

rb$orient.tr <- rad2deg(rb$orient.tr)
ii$orient.tr <- rad2deg(ii$orient.tr)

## Plot the parameters

ii$type <- "Information Integration"
rb$type <- "Rule Based"

all <- rbind(ii,rb)
all$type = factor(all$type,levels = c("Rule Based", "Information Integration"))

p1 <- ggplot(subset(all, type == "Rule Based"), aes(freq.tr, orient.tr, shape = Category)) + geom_point(size = 2) + theme_bw(15) +
  xlab("Frequency (bar width)") + ylab("Orientation (degrees)") + geom_vline(xintercept=3.25, linetype = "dashed") +
  xlim(1,5)
p1

p1 <- ggplot(subset(all, type == "Information Integration"), aes(freq.tr, orient.tr, shape = Category)) + geom_point(size = 2) + theme_bw(15) +
  xlab("Frequency (bar width)") + ylab("Orientation (degrees)") + 
  geom_abline(intercept = -157, slope = 35, linetype="dashed") +
  xlim(1,5)
p1
## Save parameters

ii.save <- ii[,c(4:5, 3)]
names(ii.save) <- c("ii_freq", "ii_or", "category")
levels(ii.save$category) <- c("a", "b")
write.csv(ii.save, "II_PatchParameters.csv", row.names = FALSE)

rb.save <- rb[,c(4:5, 3)]
names(rb.save) <- c("rb_freq", "rb_or", "category")
rb.save$category <- as.factor(rb.save$category)
levels(rb.save$category) <- c("a", "b")
write.csv(rb.save, "RB_PatchParameters.csv", row.names = FALSE)

