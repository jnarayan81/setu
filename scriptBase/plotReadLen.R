#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = "readLengthPlot.pdf"
}

pdf('readLengthPlot.pdf')

reads<-read.csv(file=args[1], sep="", header=FALSE)

plot (reads$V2,reads$V1,type="l",xlab="read length",ylab="occurences",col="blue")

dev.off()
