# promotion methods for CircuitParams
for p in (:Sparams, :Yparams, :Zparams, :ABCDparams)
    @eval promote_rule(::Type{($p){T}}, ::Type{($p){S}}) where {T<:Real, S<:Real} =
        ($p){promote_type(T, S)}
end

# Conversion between general nPort parameters:
for p in (:Sparams, :Yparams, :Zparams, :ABCDparams)
    @eval convert(::Type{$p}, s::NetworkData{S, $p{T}}) where
        {S<:Real, T<:Real} = s
end

convert(::Type{Zparams}, s::NetworkData{S, Sparams{T}}) where
    {S<:Real, T<:Real} = _S_to_Z(s)
convert(::Type{Yparams}, s::NetworkData{S, Sparams{T}}) where
    {S<:Real, T<:Real} = _S_to_Y(s)
convert(::Type{Sparams}, z::NetworkData{S, Zparams{T}}) where
    {S<:Real, T<:Real} = _Z_to_S(z)
convert(::Type{Sparams}, y::NetworkData{S, Yparams{T}}) where
    {S<:Real, T<:Real} = _Y_to_S(y)
convert(::Type{Zparams}, y::NetworkData{S, Yparams{T}}) where
    {S<:Real, T<:Real} =
    NetworkData(y.ports, y.frequency,
    [Zparams(inv(y.params[n].data)) for n in 1:y.nPoint])
convert(::Type{Yparams}, z::NetworkData{S, Zparams{T}}) where
    {S<:Real, T<:Real} =
    NetworkData(z.ports, z.frequency,
    [Yparams(inv(z.params[n].data)) for n in 1:z.nPoint])

"""
Helper matrices related to reference impedances
"""
Z_ref(ports::Vector{Port}) = diagm(impedances(ports), 0)
Z_ref(D::NetworkData) = Z_ref(D.ports)
G_ref(ports::Vector{Port}) = diagm(1./sqrt.(abs.(impedances(ports))), 0)
G_ref(D::NetworkData) = G_ref(D.ports)

"""
Conversion from S-parameters to Z-parameters
"""
function _S_to_Z(s::NetworkData{S, Sparams{T}}) where {S<:Real, T<:Real}
    E = eye(T, s.nPort)
    _Z_ref, _G_ref = Z_ref(s), G_ref(s)
    params = [Zparams(inv(_G_ref) * inv(E - s.params[n].data) *
        (E + s.params[n].data) * _Z_ref * _G_ref) for n in 1:s.nPoint]
    return NetworkData(s.ports, s.frequency, params)
end

"""
Conversion from S-parameters to Y-parameters
"""
function _S_to_Y(s::NetworkData{S, Sparams{T}}) where {S<:Real, T<:Real}
    E = eye(T, s.nPort)
    _Z_ref, _G_ref = Z_ref(s), G_ref(s)
    params = [Yparams(inv(_G_ref) * inv(_Z_ref) *
        inv(E + s.params[n].data) * (E - s.params[n].data) *
        _G_ref) for n in 1:s.nPoint]
    return NetworkData(s.ports, s.frequency, params)
end

"""
Conversion from Z-parameters to S-parameters
"""
function _Z_to_S(z::NetworkData{S, Zparams{T}}) where {S<:Real, T<:Real}
    _Z_ref, _G_ref = Z_ref(z), G_ref(z)
    params = [Sparams(_G_ref * (z.params[n].data - _Z_ref) *
        inv(z.params[n].data + _Z_ref) * inv(_G_ref)) for n in 1:z.nPoint]
    return NetworkData(z.ports, z.frequency, params)
end

"""
Conversion from Y-parameters to S-parameters
"""
function _Y_to_S(y::NetworkData{S, Yparams{T}}) where {S<:Real, T<:Real}
    E = eye(T, y.nPort)
    _Z_ref, _G_ref = Z_ref(y), G_ref(y)
    params = [Sparams(_G_ref * (E - _Z_ref * y.params[n].data) *
        inv(E + _Z_ref * y.params[n].data) * inv(_G_ref)) for n in 1:y.nPoint]
    return NetworkData(y.ports, y.frequency, params)
end

# for two-port parameters
convert(::Type{Sparams}, abcd::NetworkData{S, ABCDparams{T}}) where
    {S<:Real, T<:Real} = _ABCD_to_S(abcd)
convert(::Type{ABCDparams}, s::NetworkData{S, Sparams{T}}) where
    {S<:Real, T<:Real} = _S_to_ABCD(s)

"""
Conversion from ABCD-parameters to S-parameters
"""
function _ABCD_to_S(abcd::NetworkData{S, ABCDparams{T}}) where {S<:Real, T<:Real}
    Z0 = impedances(abcd)[1]
    s = [begin
        (A, B, C, D) = (abcd[(1, 1), n], abcd[(1, 2), n], abcd[(2, 1), n], abcd[(2, 2), n])
        S11 = (A + B / Z0 - C * Z0 - D) / (A + B / Z0 + C * Z0 + D)
        S12 = 2 * (A * D - B * C) / (A + B / Z0 + C * Z0 + D)
        S21 = 2 / (A + B / Z0 + C * Z0 + D)
        S22 = (-A + B / Z0 - C * Z0 + D) / (A + B / Z0 + C * Z0 + D)
        Sparams([S11 S12; S21 S22])
        end for n in 1:abcd.nPoint]
    return NetworkData(abcd.ports, abcd.frequency, s)
end

"""
Conversion from S-parameters to ABCD-parameters
"""
function _S_to_ABCD(s::NetworkData{S, Sparams{T}}) where {S<:Real, T<:Real}
    if s.nPort != 2
        error("Error: ABCD-parameters are defined only for 2-port networks")
    end
    if is_uniform(s) == false
        error("Error: The port impedances of a ABCDparams must be uniform")
    end
    Z0 = impedances(s)[1]
    abcd = [begin
    (S11, S12, S21, S22) = (s[(1, 1), n], s[(1, 2), n], s[(2, 1), n], s[(2, 2), n])
    A = ((1 + S11) * (1 - S22) + S12 * S21) / (2 * S21)
    B = Z0 * ((1 + S11) * (1 + S22) - S12 * S21) / (2 * S21)
    C = 1 / Z0 * ((1 - S11) * (1 - S22) - S12 * S21) / (2 * S21)
    D = ((1 - S11) * (1 + S22) + S12 * S21) / (2 * S21)
    ABCDparams([A B; C D])
    end for n in 1:s.nPoint]  # converting S-parameters into ABCD parameters
    return NetworkData(s.ports, s.frequency, abcd)
end
