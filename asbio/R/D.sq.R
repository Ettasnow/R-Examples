D.sq<-function(g1,g2){
dbar<-as.vector(colMeans(g1)-colMeans(g2))
S1<-cov(g1)
S2<-cov(g2)
n1<-nrow(g1)
n2<-nrow(g2)
V<-as.matrix((1/(n1+n2-2))*(((n1-1)*S1)+((n2-1)*S2)))
D.sq<-t(dbar)%*%solve(V)%*%dbar
res<-list()
res$D.sq<-D.sq
res$V<-V
res
}