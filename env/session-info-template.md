# Environment and Session Information

Recommended minimum environment:

- R 4.4.x
- optparse
- data.table
- jsonlite
- ggplot2
- vegan

Optional packages for upstream microbiome preparation:

- phyloseq
- dada2
- zCompositions, when Bayesian/multiplicative zero replacement is required

Record this at the end of a reproducible run:

```r
sessionInfo()
```

Use `env/environment.yml` for a Conda-style environment and `env/Dockerfile` as a minimal Docker starting point. These files are convenience templates, not a guarantee of platform-specific binary availability on every system.
