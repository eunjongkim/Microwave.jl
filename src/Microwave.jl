# __precompile__(true)
module Microwave
# Microwave.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, /, convert, show, getindex, setindex!
# export setMicrowaveFloat

abstract type AbstractParams end
abstract type AbstractData end

# const MFloat = BigFloat
#using Touchstone
include(joinpath("Circuit", "Circuit.jl"))
import .Circuit: CircuitParams, Impedance, Admittance, CircuitData, ∥,
    resistor, inductor, capacitor
export Circuit
export CircuitParams, Impedance, Admittance, CircuitData, ∥,
    resistor, inductor, capacitor

include(joinpath("Network", "Network.jl"))
import .Network: NetworkParams, Sparams, Yparams, Zparams, TwoPortParams, ABCDparams
export Network
export NetworkParams, Sparams, Yparams, Zparams, TwoPortParams, ABCDparams
# Definitions of NetworkParams, NetworkData
# include(joinpath("Network", "NetworkParams.jl"))
# include(joinpath("Network", "NetworkData.jl"))
# include(joinpath("Network", "convert.jl"))
# include(joinpath("Network", "connect.jl"))
# include(joinpath("Network", "twoport.jl"))
#
# include(joinpath("Touchstone", "Touchstone.jl"))
# include(joinpath("Touchstone", "convert.jl"))

# interpolate data
# include("interpolate.jl")

end # module
