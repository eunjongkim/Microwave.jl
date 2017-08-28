# Microwave
[Julia](julialang.org) library for calculation with Microwave objects.

Written by Eun Jong Kim (ekim7206@gmail.com)

## Usage
```jl
Pkg.clone("https://github.com/eunjongkim/Microwave.jl.git")
using Microwave
```
## To do
- Support for `Yparams` and `Zparams`: in `read_touchstone`
- Support for non-uniform Z₀
- More support for two-port networks
- Plots (Magnitude Plot, Smith Chart)
- Writing raw touchstone file from data (or saving data into other forms)
