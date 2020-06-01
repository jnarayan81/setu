library(ggplot2)
library(reshape2)
args = commandArgs(trailingOnly=TRUE)

myMatrix <- read.table(args[1], sep="\t", header=FALSE);

png(args[2])
w.plot <- melt(myMatrix)
p <- ggplot(aes(x=value, colour=variable), data=w.plot)
p + geom_density()
