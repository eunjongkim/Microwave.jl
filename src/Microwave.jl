# __precompile__(true)
module Microwave
# Microwave.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, /, convert, show, getindex, setindex!
export setMicrowaveFloat

const MFloat = BigFloat
#using Touchstone
include(joinpath("Circuit", "Circuit.jl"))
include(joinpath("Circuit", "convert.jl"))
include(joinpath("Circuit", "RLC.jl"))

# Definitions of NetworkParams, NetworkData
include(joinpath("Network", "NetworkParams.jl"))
include(joinpath("Network", "NetworkData.jl"))
include(joinpath("Network", "convert.jl"))
include(joinpath("Network", "connect.jl"))
include(joinpath("Network", "twoport.jl"))

include(joinpath("Touchstone", "Touchstone.jl"))
include(joinpath("Touchstone", "convert.jl"))

# interpolate data
include("interpolate.jl")

end # module
