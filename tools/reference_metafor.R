# Reproduce the public fixture; only development-time R packages are used.
# Install metafor 4.8-0, metadat 1.4-0 and jsonlite before running.
# Rscript tools/reference_metafor.R [output.json]
library(metafor)
library(jsonlite)
stopifnot(as.character(packageVersion("metafor")) == "4.8.0",
          as.character(packageVersion("metadat")) == "1.4.0")
data(dat.bcg, package="metadat")
d <- escalc(measure="RR", ai=tpos, bi=tneg, ci=cpos, di=cneg, data=dat.bcg)
models <- list(intercept=~1, latitude=~ablat, multi=~ablat+year)
fits <- list()
for (label in names(models)) for (test in c("z", "adhoc")) {
  f <- rma(yi, vi, mods=models[[label]], data=d, method="REML", test=test,
           control=list(threshold=1e-12, maxiter=10000))
  X <- model.matrix(f)
  residual <- d$yi - as.vector(X %*% f$beta)
  pred <- if (label == "intercept") predict(f) else
    predict(f, newmods=if (label=="latitude") matrix(c(13,30,55),ncol=1) else cbind(c(13,30,55), c(1950,1970,1980)))
  fits[[paste(label, test, sep="_")]] <- list(tau2=f$tau2, beta=as.vector(f$beta),
    se=f$se, ci_lower=f$ci.lb, ci_upper=f$ci.ub, QE=f$QE,
    residual_q=sum(residual^2/(d$vi+f$tau2)), covariance=unname(vcov(f)),
    prediction=list(estimate=pred$pred, se=pred$se, ci_lower=pred$ci.lb, ci_upper=pred$ci.ub))
}
result <- list(R=R.version.string, metafor=as.character(packageVersion("metafor")),
  metadat=as.character(packageVersion("metadat")), data=d, fits=fits)
args <- commandArgs(trailingOnly=TRUE)
output <- if (length(args)) args[[1]] else "fixtures/metafor-bcg/reference.json"
writeLines(toJSON(result, digits=16, auto_unbox=TRUE, pretty=TRUE), output)
