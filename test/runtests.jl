using MatisseCytometry
using Test
using StatsBase
using Colors

if isdir(joinpath(@__DIR__,"color_figures"))
    rm(joinpath(@__DIR__,"color_figures"),recursive = true)
end

set_project(@__DIR__)

function random_colorscheme(;ncols = 10)
    targs = sample(get_target_list(),ncols; replace = false)
    colangle = sample(0:20:360,ncols; replace = false)
    [HSV(c,1,1) => t for (t,c) in zip(targs,colangle)]
end

println( random_colorscheme())
istiff(t) = split(t, ".")[end] == "tiff"
ispdf(t) = split(t, ".")[end] == "pdf"

for t in readdir(MatisseCytometry.IMG_PATH())
    if split(t, ".")[end] == "tiff"
        println("making $(t) without masks")
        color_figure(t, random_colorscheme(;ncols = 10)...; colorscale = 0.3)
    end
end

for t in readdir(MatisseCytometry.IMG_PATH())
    if istiff(t)
        println("making $(t) with masks")
        color_figure(t, random_colorscheme(;ncols = 10)...; mask_dir = "masks_deepcell", colorscale = 0.2)
    end
end

@testset "MatisseCytometry.jl" begin
    # Write your tests here.
    @test isdir(MatisseCytometry.FIG_PATH())
    @test 2*length(filter(istiff, readdir(MatisseCytometry.IMG_PATH()))) ==
         length(filter(ispdf,readdir(MatisseCytometry.FIG_PATH())))
end
