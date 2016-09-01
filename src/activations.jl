
# general formula for elementwise activation: output = act(input)
# some examples of act: logistic, tanh, relu, etc
immutable Activation{F,T} <: Transformation
    n::Int
    # α::T  # scaling parameter for some activations
    input::Node{:input,T,1}
    output::Node{:output,T,1}

    # construct a new Activation, and link the nodes if it's the identity
    function Activation(n::Int) #, α::T = zero(T))
        input = Node(:input, zeros(T,n))
        output = Node(:output, zeros(T,n))
        if F == :identity
            link_nodes!(output, input)
        end
        new(n, input, output)
    end
end

Base.show{F,T}(io::IO, act::Activation{F,T}) = print(io, "$F($T, $(act.n))")

input_length(act::Activation) = act.n
output_length(act::Activation) = act.n

# ----------------------------------------------------------------------------


# identity: nothing to do, since we linked the input to output
transform!(act::Activation{:identity}) = act.output.val
grad!(act::Activation{:identity}) = act.input.∇

# for the following, compute the derivative f′(x), where y = act(x) is assumed precomputed
# ref: https://en.wikipedia.org/wiki/Activation_function

# logistic (sigmoid): act(x) = 1 ./ (1 .+ exp.(-x))
logistic′{T<:Number}(x::T, y::T) = y * (one(T) - y)

# tanh: act(x) = (eˣ .- e⁻ˣ) ./ (eˣ .+ e⁻ˣ)
tanh′{T<:Number}(x::T, y::T) = one(T) - y^2

softsign{T<:Number}(x::T) = x / (one(T) + abs(x))
softsign′{T<:Number}(x::T, y::T) = one(T) / (one(T) + abs(x))^2

relu{T<:Number}(x::T) = max(zero(T), x)
relu′{T<:Number}(x::T, y::T) = x >= zero(T) ? one(T) : zero(T)

softplus{T<:Number}(x::T) = log(one(T) + exp(x))
softplus′{T<:Number}(x::T, y::T) = logistic(x)

sinusoid{T<:Number}(x::T) = sin(x)
sinusoid′{T<:Number}(x::T, y::T) = cos(x)

gaussian{T<:Number}(x::T) = exp(-(x^2))
gaussian′{T<:Number}(x::T, y::T) = -2x*y



# ----------------------------------------------------------------------------

# generic implementations... ensure there's a derivative method of the correct name

const activations = [
    :logistic,
    :tanh,
    :softsign,
    :relu,
    :softplus,
    :sinusoid,
    :gaussian,
]

for act in activations
    s = string(act)
    f′ = Symbol(s*"′")

    @eval begin
        # elementwise map from input to output
        transform!(act::Activation{Symbol($s)}) = map!($act, act.output.val, act.input.val)

        # backprop gradient calc using specialized derivative
        function grad!(act::Activation{Symbol($s)})
            for i=1:act.n
                act.input.∇[i] = $f′(act.input.val[i], act.output.val[i]) * act.output.∇[i]
            end
            # no params, so nothing to return
        end

        # x-only version
        function $f′(x::Number)
            y = $act(x)
            $f′(convert(typeof(y), x), y)
        end

        value_func(act::Activation{Symbol($s)}) = $act
        deriv_func(act::Activation{Symbol($s)}) = $f′

        # export both functions
        export $act, $f′
    end
end


# ----------------------------------------------------------------------------

default_range(act::Activation) = linspace(-5,5)

# user recipe adds a default x range
@recipe act{F}(act::Activation{F}) = act, default_range(act)

# type recipe converts to a function of xi
@recipe act{A<:Activation}(::Type{A}, act::A) = Transformations.value_func(act)

# ----------------------------------------------------------------------------