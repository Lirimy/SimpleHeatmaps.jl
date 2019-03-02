import Colors: colormap
import IndirectArrays: IndirectArray
import MappedArrays: mappedarray
import FileIO: open, close, save, @format_str, Stream


const CURRENT_COLORMAP = colormap("Blues", 256)
current_colormap() = CURRENT_COLORMAP


function set_colormap(cmap::AbstractVector)
    @assert length(cmap)==256 "Number of gradation must be 256"
    @. CURRENT_COLORMAP = RGB(cmap)
end


function matshow(A::AbstractMatrix; f::Function=x->1+floor(Int, 256*x))
    IndirectArray(mappedarray(f, A), CURRENT_COLORMAP)
end


get_extension(fn) = lowercase(Base.Filesystem.splitext(fn)[2][2:end])


struct AnimationFile
    filename::String
end


function Base.show(io::IO, ::MIME"text/html", anim::AnimationFile)
    ext = get_extension(anim.filename)

    if ext == "mp4"
        write(io, "<video controls><source src=\"$(relpath(anim.filename))?$(rand())>\" type=\"video/mp4\"></video>")
    elseif ext == "gif"
        write(io, "<img src=\"$(relpath(anim.filename))?$(rand())>\" />")
    else
        error("Only support mp4/gif: $ext")
    end
    
    nothing
end


function addframe(io, img::AbstractMatrix)
    save(Stream(format"BMP", io), img)
end


function openanim(f::Function, filename::AbstractString="out.mp4")
    filename = abspath(filename)
    ext = get_extension(filename)
    
    if ext == "mp4"
        open(f, `ffmpeg -v 0 -i pipe:0 -pix_fmt yuv420p -y $filename`, "w")
        return AnimationFile(filename)
    elseif ext == "gif"
        palette = tempname() * ".bmp"
        save(palette, IndirectArray(reshape(1:256, 16, 16)', SimpleHeatmaps.CURRENT_COLORMAP))
        open(f, `ffmpeg -v 0 -i pipe:0 -i $palette -lavfi paletteuse=dither=sierra2_4a -y $filename`, "w")
        return AnimationFile(filename)
    else
        error("Only support mp4/gif: $ext")
    end
end

