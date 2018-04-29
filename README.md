
<!-- README.md is generated from README.Rmd. Please edit that file -->

# graphparse

## Installation

``` r
# install.packages("devtools")
devtools::install_github("mailund/graphparse")
```

## Example

Parsing a qpGraph file:

``` r
test_graph <- readr::read_file("data-raw/Basic_OngeEA_wArch.graph")
g <- graphparse::read_qpgraph(test_graph)
plot(g)
#> fminbnd:  Exiting: Maximum number of function evaluations has been exceeded
#>          - increase MaxFunEvals option.
#>          Current function value: 4411.21184093304
```

<img src="man/figures/README-pqgraph-1.png" width="100%" />

``` r
attr(g, "admixture_proportions")
#>                     K2_K                     P2_P     AdmixedNonAfr_AfrAnc 
#>                      0.5                      0.5                      0.5 
#> DenisovaAncAnc_SuperArch 
#>                      0.5
```

Parsing a dot file:

``` r
test_graph <- readr::read_file("data-raw/Basic_OngeEA_wArch.dot")
g <- graphparse::read_dot(test_graph)
plot(g)
#> fminbnd:  Exiting: Maximum number of function evaluations has been exceeded
#>          - increase MaxFunEvals option.
#>          Current function value: 9811.09667284432
```

<img src="man/figures/README-dot-1.png" width="100%" />

``` r
attr(g, "admixture_proportions")
#>  Arch_DenisovaAncAnc NeaAnc_AdmixedNonAfr            NeaAnc_K2 
#>                 0.49                 0.03                 0.01 
#>       DenisovaAnc_P2 
#>                 0.03
```
