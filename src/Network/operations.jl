
function +(param1::T, param2::T) where {T<:NetworkParams}
    if param1.nPort == param2.nPort
        return T(param1.data + param2.data)
    else
        error("The number of ports must be identical in order to perform binary operations")
    end
end

function -(param1::T, param2::T) where {T<:NetworkParams}
    if param1.nPort == param2.nPort
        return T(param1.data - param2.data)
    else
        error("The number of ports must be identical in order to perform binary operations")
    end
end

function *(param1::T, param2::T) where {T<:NetworkParams}
    if param1.nPort == param2.nPort
        return T(param1.data * param2.data)
    else
        error("The number of ports must be identical in order to perform binary operations")
    end
end

^(param::T, N::Int) where {T<:NetworkParams} = T(^(param.data,N))
