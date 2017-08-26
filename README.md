# Touchstone
[Julia](julialang.org) library for calculation with touchstone (.sNp) files.

Written by Eun Jong Kim (ekim7206@gmail.com)

## Usage
```jl
Pkg.clone("https://github.com/eunjongkim/Touchstone.jl.git")
using Touchstone
```
## To do
- Support for `Yparams` and `Zparams`
- Support for Z₀≠50Ω  (introduce impedance steps)
- Support for general `N`-port networks
- Plots
- Writing raw touchstone file from data
