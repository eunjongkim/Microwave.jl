module Network

import Microwave: AbstractParams, AbstractData
import Microwave.Circuit: Impedance, Admittance
import Base: +, -, *, /, ^, convert, promote_rule, show

export NetworkParams, Sparams, Yparams, Zparams
export TwoPortParams, ABCDparams

include("NetworkParams.jl")
include("convert.jl")
include("operations.jl")
# include("NetworkData.jl")
end
