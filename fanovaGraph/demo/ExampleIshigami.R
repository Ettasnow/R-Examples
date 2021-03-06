#################################
# Ishigami function application #
#################################

require(fanovaGraph)

### function definition:

d <- 3
domain <- c(-pi, pi)
fun <- ishigami.fun

### maximin design via package 'lhs'
data(L)
x<-pi*L[,1:3]

### kriging model via package 'DiceKriging'

y <- fun(x)
KM <- km(~1, design = data.frame(x), response = y)

### standard Sobol indices with package 'sensitivity'

i1 <- fast99(model = kmPredictWrapper, factors = d, n = 2000, q = "qunif", 
             q.arg = list(min = domain[1], max = domain[2]), km.object = KM)
plot(i1)


### estimation of total interaction indices via fixing method

g <- estimateGraph(f.mat = kmPredictWrapper, d = d, n.tot = 30000, q.arg = 
  list(min = domain[1], max = domain[2]), km.object = KM) 
print(g$tii)

### plot the full graph

plot(g)

### threshold decision by looking at DeltaJumps

plotDeltaJumps(g)

### threshold inactive edges and plot graph again

g.cut <- threshold(g, delta = 0.1, scale = TRUE)
plot(g.cut)

### estimate new model

Cliques <- g.cut$cliques
parameter <- kmAdditive(x, y, cl = Cliques)

### comparison to standard kriging

xpred <- matrix(runif(d * 1000, domain[1], domain[2]), ncol = d)
y_new <- predictAdditive(xpred, x, y, parameter, cl = Cliques)
y_old <- kmPredictWrapper(xpred, km.object = KM)
y_exact <- fun(xpred)

op <- par("mfrow")
par(mfrow = c(1, 2))
plot(y_exact, y_old, asp = 1, xlab="y, exact", ylab="y, predicted", main="Standard Kernel")
abline(0, 1)
plot(y_exact, y_new[, 1], asp = 1, xlab="y, exact", ylab="y, predicted", main="Modified Kernel")
abline(0, 1)
par(mfrow = op)

sqrt(mean((y_old - y_exact)^2))
sqrt(mean((y_new[, 1] - y_exact)^2))