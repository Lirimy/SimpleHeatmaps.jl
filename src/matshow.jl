import FileIO: open, close, save, @format_str, Stream
import IndirectArrays: IndirectArray
import MappedArrays: mappedarray
import Colors: colormap
import ImageContainers: ImageContainer

const CURRENT_COLORMAP = colormap("Blues", 256)
current_colormap() = CURRENT_COLORMAP


function set_colormap(cmap::AbstractVector)
    @assert length(cmap)==256 "Number of gradation must be 256"
    @. CURRENT_COLORMAP = RGB(cmap)
end


function matshow(A::AbstractMatrix; f::Function=x->clamp(1+floor(Int, 256*x), 1, 256))
    ImageContainer{:jlc}(IndirectArray(mappedarray(f, A), CURRENT_COLORMAP))
end


function addframe(io, img::ImageContainer{:jlc})
    save(Stream(format"BMP", io), img.content)
end


function openanim(func::Function, fmt::Symbol=:gif)
    fin = Pipe()
    fout = IOBuffer()
    
    if fmt == :mp4
        fproc = run(
            pipeline(`ffmpeg -v 0 -i - -pix_fmt yuv420p -f matroska -`,
                stdin=fin, stdout=fout),
            wait=false)
        
        try
            func(fin)
        finally
            close(fin)
        end
        
        wait(fproc)
        close(fproc)
        return ImageContainer{:mp4}(take!(fout))
    
    elseif fmt == :gif
        palette = tempname() * ".bmp"
        save(palette, IndirectArray(reshape(1:256, 16, 16)', SimpleHeatmaps.CURRENT_COLORMAP))
    
        fproc = run(
            pipeline(`ffmpeg -v 0 -i - -i $palette -lavfi paletteuse=dither=sierra2_4a -f gif -`,
                stdin=fin, stdout=fout),
            wait=false)
        
        try
            func(fin)
        finally
            close(fin)
        end
        
        wait(fproc)
        close(fproc)
        return ImageContainer{:gif}(take!(fout))
    
    else
        error("Only support mp4 / gif: $fmt")
    end
end

