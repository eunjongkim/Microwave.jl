# __precompile__(true)
module Microwave
# Microwave.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, /, convert, show, getindex, setindex!
# export setMicrowaveFloat

abstract type AbstractParams end
abstract type AbstractData end

export AbstractParams, AbstractData
# const MFloat = BigFloat
#using Touchstone
include(joinpath("Circuit", "Circuit.jl"))
import .Circuit: CircuitParams, Impedance, Admittance, CircuitData, ∥,
    resistor, inductor, capacitor
export Circuit
export CircuitParams, Impedance, Admittance, CircuitData, ∥,
    resistor, inductor, capacitor

include(joinpath("Network", "Network.jl"))
import .Network: NetworkParams, Sparams, Yparams, Zparams, TwoPortParams, ABCDparams,
      Port, NetworkData, impedances, swap_ports!, permute_ports!, connect_ports,
      innerconnect_ports, cascade, reflection_coefficient, transmission_coefficient,
      impedance_step, series_network, parallel_network, terminated_network,
      π_network, t_network, check_frequency_identical
export Network
export NetworkParams, Sparams, Yparams, Zparams, TwoPortParams, ABCDparams,
      Port, NetworkData, impedances, swap_ports!, permute_ports!, connect_ports,
      innerconnect_ports, cascade, reflection_coefficient, transmission_coefficient,
      impedance_step, series_network, parallel_network, terminated_network,
      π_network, t_network, check_frequency_identical

include(joinpath("Touchstone", "Touchstone.jl"))
import .Touchstone: TouchstoneData, read_touchstone
export TouchstoneData, read_touchstone

# interpolate data
include("interpolate.jl")

end # module
