__precompile__(true)

module Transformations

using Reexport
@reexport using LearnBase
using RecipesBase

import CatViews: CatView, splitview
import Base: rand
import LearnBase: transform, transform!, grad, grad!, addgrad!, value
import StatsBase: logistic, logit

export
    input_node,
    output_node,
    input_length,
    output_length,
    input_value,
    output_value,
    input_grad,
    output_grad,
    params,

    Node,
    link_nodes!,
    Affine,
    Activation,
    Chain,
    ConvFilter,
    ConvLayer,
    MaxPooling,
    Differentiable,
    NonDifferentiable,
    OnceDifferentiable,
    TwiceDifferentiable

function zero!{T,N}(v::AbstractArray{T,N})
    for i in eachindex(v)
        v[i] = zero(T)
    end
end

input_node(t::Transformation) = t.input
output_node(t::Transformation) = t.output
input_length(t::Transformation) = length(input_node(t))
output_length(t::Transformation) = length(output_node(t))
input_value(t::Transformation) = value(input_node(t))
output_value(t::Transformation) = value(output_node(t))
input_grad(t::Transformation) = grad(input_node(t))
output_grad(t::Transformation) = grad(output_node(t))

# # return a view of the parameter vector... may be a CatView/SplitView
# function params end

abstract Learnable <: Transformation

"The length of the parameter vector"
params_length(t::Transformation) = 0
params_length(t::Learnable) = length(params(t))

"Learnable parameter values"
params(t::Transformation) = zeros(0)
params(t::Learnable) = value(t.params)

"Gradients of the learnable parameters"
grad(t::Transformation) = zeros(0)
grad(t::Learnable) = grad(t.params)

# notes:
#   Transformations will be updated in a forward (transform) and backward (grad) pass.
#   The input nodes of a larger comp graph will be called with `transform!(t,input)` and all other
#   nodes will be called with `transform!(t)`, assuming they are properly "linked" beforehand.
#   This is because `output` is computed, which shares a reference to the arrays in the following
#   Transformation's `input`, so it's ready to compute with `transform!`.

#   The same happens in reverse.  An `input` node's `∇` is the same array as the child node's `output.∇`,
#   so the gradients can flow backwards with one call to `grad!` in the proper (reverse) order.
#   In this case, the

# TODO:
#   - DAGs of Transformations
#   - Then handle cycles

# ----------------------------------------------------------------

# Most Transformations can share these methods as long as they have the required fields.


# Copy input values into the input node, then transform
function transform!(t::Transformation, input::AbstractArray)
    copy!(input_value(t), input)
    transform!(t)
end

# Copy the gradient into the output node, and propagate it back.
function grad!(t::Transformation, ∇out::AbstractArray)
    copy!(output_grad(t), ∇out)
    grad!(t)
end


# # return a CatView of the params
# function params(t::Transformation)
#     t.θ
# end
#
# # return a CatView of the param gradients
# function grad(t::Transformation)
#     t.∇θ
# end

# # update our params
# # TODO: handle learning rate better
# function addgrad!(t::Transformation, dθ::AbstractVector, η::Number)
#     for (i,j) in zip(eachindex(t.θ), eachindex(dθ))
#         t.θ[i] += η * dθ[j]
#     end
# end


# ----------------------------------------------------------------

include("params.jl")
include("nodes.jl")
include("affine.jl")
include("activations.jl")
include("chain.jl")
include("convolutions.jl")
include("pooling.jl")
include("functions.jl")

# ----------------------------------------------------------------

end # module
