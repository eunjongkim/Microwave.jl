module Network

import Microwave: AbstractParams, AbstractData
import Microwave.Circuit: Impedance, Admittance
import Base: +, -, *, /, ^, convert, promote_rule, show

export NetworkParams, Sparams, Yparams, Zparams, TwoPortParams, ABCDparams
export Port, NetworkData, impedances, swap_ports!, permute_ports!
export connect_ports, innerconnect_ports, cascade
export reflection_coefficient, transmission_coefficient, impedance_step
export series_network, parallel_network, terminated_network, π_network, t_network


include("NetworkParams.jl")
include("NetworkData.jl")
include("convert.jl")
include("operations.jl")
include("connect.jl")
include("twoport.jl")

end
