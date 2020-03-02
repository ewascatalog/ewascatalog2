##devtools::install_github("perishky/eval.save")
library(eval.save)
eval.save.dir(".eval")

top.n <- 1000 ## p_rank in sql query <= 1000

overlaps <- read.table("output/overlaps.txt", sep="\t", stringsAsFactors=F, header=T)

overlaps$n1 <- pmin(top.n, overlaps$n1)
overlaps$n2 <- pmin(top.n, overlaps$n2)

n <- 485000
overlaps$ff <- n - overlaps$n1 - overlaps$n2 + overlaps$overlap
overlaps$tt <- overlaps$overlap
overlaps$tf <- overlaps$n1 - overlaps$overlap
overlaps$ft <- overlaps$n2 - overlaps$overlap

overlaps$p <- eval.save({
  apply(overlaps[,c("ff","ft","tf","tt")], 1, function(vals) {
    fisher.test(matrix(vals, ncol=2), alternative="greater")$p.value
  })
}, "overlaps-p")

## add symmetric comparisons
overlaps.r <- overlaps
overlaps.r$study1 <- overlaps.r$study2
overlaps.r$n1 <- overlaps.r$n2
overlaps.r$study2 <- overlaps$study1
overlaps.r$n2 <- overlaps$n1
overlaps.r$p <- overlaps$p
overlaps <- rbind(overlaps, overlaps.r)

## create 'overlap' matrix
studies <- unique(c(overlaps$study1, overlaps$study2))
overlap.p <- matrix(NA, ncol=length(studies), nrow=length(studies),
                   dimnames=list(studies, studies))
idx <- cbind(r=match(overlaps$study1, rownames(overlap.p)),
             c=match(overlaps$study2, colnames(overlap.p)))
overlap.p[idx] <- overlaps$p

log.p <- -log(overlap.p,10)
log.p[which(log.p > 50)] <- 50
threshold <- -log(0.05/length(log.p)*2, 10)

## plot heatmap of log.p
source("heatmap-function.r")

pdf("output/cell-counts-and-variables.pdf")
plot.new()
grid.clip()
cols <- heatmap.color.scheme(low.breaks=seq(0,threshold,length.out=50),
                             high.breaks=seq(threshold,max(log.p,na.rm=T),length.out=50))
h.out <- heatmap.simple(log.p,
                        color.scheme=cols,
                        key.min=0,
			key.max=max(log.p, na.rm=T),
			na.color="gray",
			scale="none",
                        title="...")
 #h.marks <- matrix(0, ncol=ncol(log.p), nrow=nrow(log.p))
 #h.marks[log.p < threshold] <- 1
 #heatmap.mark(h.out, h.marks, mark="box")
 dev.off()


## identify reproducible clusters
library(pvclust)
pvclust(log.p, nboot=100)
...