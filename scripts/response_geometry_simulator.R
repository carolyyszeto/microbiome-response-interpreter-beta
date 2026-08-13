source(file.path(dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]), mustWork=FALSE)), "backend_common.R"))
opts <- parse_cli_args(); require_args(opts,c("outdir")); set.seed(as.integer(opts$seed %||% 1)); n <- as.integer(opts$n %||% 12)
scenarios <- c("null_response", "magnitude_only_random_direction", "shared_direction", "mixed_response", "opposing_subgroups")
make <- function(s) switch(s,
  null_response=matrix(0,n,2),
  magnitude_only_random_direction={z<-runif(n,0,2*pi); cbind(cos(z),sin(z))*2},
  shared_direction=matrix(rep(c(2,1),each=n),ncol=2)+matrix(rnorm(2*n,0,.1),n),
  mixed_response={z<-runif(n,0,2*pi); M<-cbind(cos(z),sin(z)); M[seq_len(floor(n/2)),]<-M[seq_len(floor(n/2)),]+c(2,0); M},
  opposing_subgroups={M<-matrix(rep(c(2,0),each=n),ncol=2); M[(floor(n/2)+1):n,]<- -M[(floor(n/2)+1):n,]; M})
out <- bind_rows(lapply(scenarios,function(s){M<-make(s); tibble(scenario=s,n_subjects=n,mean_magnitude=mean(sqrt(rowSums(M^2))),mean_loo_reference_cosine=mean(compute_loo_cosines(M),na.rm=TRUE))}))
write_tsv_safe(out,file.path(ensure_outdir(opts$outdir),"response_geometry_simulator.tsv"))
