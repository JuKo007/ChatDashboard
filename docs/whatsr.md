# Install WhatsR without Java

ChatDashboard calls the WhatsR parser and dashboard plots. WhatsR also imports
`qdap` for its separate lexical dispersion plot. That import loads `openNLP` and
`rJava` at package startup. The patch in this repository makes `qdap` optional
and keeps the parser and other plots intact.

From the ChatDashboard checkout, clone the pinned WhatsR source into a fresh
directory and apply the patch:

```sh
git clone https://github.com/gesiscss/WhatsR.git WhatsR-build
git -C WhatsR-build checkout 06d7633d5d64f9028a8939d25fdca9eb04390dde
git -C WhatsR-build apply --check ../patches/whatsr-optional-qdap.patch
git -C WhatsR-build apply ../patches/whatsr-optional-qdap.patch
```

Run this from the ChatDashboard root in R to install the imports and the patched package:

```r
install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_local("WhatsR-build", dependencies = NA, upgrade = "never")
```

Restart R and verify:

```r
library(WhatsR)
stopifnot(!"rJava" %in% loadedNamespaces())
```

Only install `qdap` if you need `WhatsR::plot_lexical_dispersion()`.
The same patched source can be used when preparing a webR build, with a
WebAssembly package repository that supplies its imports.
