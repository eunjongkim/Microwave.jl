module Network

import Microwave: AbstractParams, AbstractData
import Microwave.Circuit: Impedance, Admittance
import Base: +, -, *, /, ^, convert, promote_rule, show

export NetworkParams, Sparams, Yparams, Zparams
export TwoPortParams, ABCDparams
export Port, NetworkData, impedances, swap_ports!, permute_ports!


include("NetworkParams.jl")
include("NetworkData.jl")
include("convert.jl")
include("operations.jl")

end
