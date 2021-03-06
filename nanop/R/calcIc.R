calcSc <- function(nanop, ts,
                           dQ=.01, minQ=1,maxQ=20,type="neutron", 
                           scatterFactor=list(
                             a1 = 16.777389, b1=.122737, a2=19.317156,
                             b2=8.62157, a3=32.979682, b3=1.256902, a4=5.595453,
                             b4=38.008821, a5=10.576854, b5=.000601,
                             c=-6.279078), scatterLength=7.63) {
  
  if(type == "neutron") {
    type <- 0
    natomTypes <- length(scatterLength)
  }
  else {
    type <- 1 
    natomTypes <- length(scatterFactor$a1)#add error checks
  }
  Q <- seq(minQ,maxQ,by=dQ)
  if(is.null(attributes(nanop)$rowcore)){

    
    
    res <- list(Q=Q, gQ=.C("calcSc",
              res = as.double(ts$gQ),
              Q = as.double(Q), 
              len = as.integer(length(Q)),
              nrow = as.integer(nrow(nanop)),
              atomType=as.integer(attr(nanop, "atomType")),
                        natomTypes = natomTypes, 
                        a1 = as.double(scatterFactor$a1),
                        b1 = as.double(scatterFactor$b1),
                        a2 = as.double(scatterFactor$a2),
                        b2 = as.double(scatterFactor$b2),
                        a3 = as.double(scatterFactor$a3),
                        b3 = as.double(scatterFactor$b3),
                        a4 = as.double(scatterFactor$a4),
                        b4 = as.double(scatterFactor$b4),
                        a5 = as.double(scatterFactor$a5),
                        b5 = as.double(scatterFactor$b5),
                        c = as.double(scatterFactor$c),
                        scatterLengths=scatterLength, 
                        type=as.integer(type),
              PACKAGE="nanop")$res)
  }
  else {
    rc <- attributes(nanop)$rowcore
    rsh <- attributes(nanop)$rowshell
    if(rc == 0 || rsh == 0) 
      stop("no atoms in core or shell.")
    else {
      nanopC <- nanop[1:rc,]
      nanopS <- nanop[(rc+1):nrow(nanop),]

      res <- list(Q=Q, gQ=.C("calcSc_CS",
                         res = as.double(ts$gQ),
                         Q = as.double(Q), 
                         len = as.integer(length(Q)),
                         minQ = as.double(minQ),
                         dQ = as.double(dQ),
                         npC = as.double(as.vector(t(nanopC))),
                         npS = as.double(as.vector(t(nanopS))),
                         nrowC = as.integer(nrow(nanopC)),
                         nrowS = as.integer(nrow(nanopS)),
                         atomTypeC=as.integer(attr(nanop, "atomType")),
                         atomTypeS=as.integer(attr(nanop, "atomTypeS")),
                         natomTypesC = natomTypes,
                         natomTypesS = natomTypes, 
                         a1 = as.double(scatterFactor$a1),
                         b1 = as.double(scatterFactor$b1),
                         a2 = as.double(scatterFactor$a2),
                         b2 = as.double(scatterFactor$b2),
                         a3 = as.double(scatterFactor$a3),
                         b3 = as.double(scatterFactor$b3),
                         a4 = as.double(scatterFactor$a4),
                         b4 = as.double(scatterFactor$b4),
                         a5 = as.double(scatterFactor$a5),
                         b5 = as.double(scatterFactor$b5),
                         c = as.double(scatterFactor$c),
                         scatterLengths=scatterLength, 
                         type=as.integer(type),
                         PACKAGE="nanop")$res)
    }
  }
  res
  
}

