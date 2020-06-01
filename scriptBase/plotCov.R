#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = "readLengthPlot.pdf"
}


library(reshape)
pdf('covPlot.pdf')

corona.chr <- read.table(args[1], header=FALSE, sep="\t", na.strings="NA", dec=".", strip.white=TRUE)

corona.chr<-rename(corona.chr,c(V1="Chr", V2="locus", V3="depth"))

plot(corona.chr$locus, corona.chr$depth, pch=1, col=c("green", "red"), cex=0.5)

dev.off()

