using Colors
using IndirectArrays
using MappedArrays

const CURRENT_COLORMAP = colormap("Blues", 256)

function matshow(A::AbstractMatrix; f=x->1+floor(Int, 256*x))
    IndirectArray(mappedarray(f, A), CURRENT_COLORMAP)
end
