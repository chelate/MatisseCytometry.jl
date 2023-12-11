module MatisseCytometry


export color_figure, set_project, get_target_list
#export color_figure
using ColorSchemes
using StatsBase # package with basic math such as means
using Images # image processing
using CSV # for readng the panel file
using Luxor # for drawing the masks and legens in vector graphics


project_path = @__DIR__ # this will be set to the environment path

function set_project(path::AbstractString)
    if !isdir(path)
        print("This is not yet a directory. Do you want to create it? \n (yes/no): ")
        user_response = readline()
        if lowercase(user_response) == "yes"
            # Create the file
            mkpath(path)
            global data_directory = "data"
            mkpath(joinpath(path,data_directory))
            println("Directory '$path' created.")
            global project_path = path
            println("The project root directory has been set to $(project_path)")
        else
            println("canceled.")
        end
    else
        global project_path = path
        println("The project root directory has been set to $(project_path)")
    end
end

data_directory = "data"
img_directory = "img"
DATA_PATH() = joinpath(project_path, data_directory) # set directories
IMG_PATH() = joinpath(project_path, data_directory, img_directory) # set directories
function set_data_directory(path)
    global data = path
    println("The data directory is now $(DATA_PATH())")
end

function set_img_directory(path)
    global img_directory = path
    println("The image directory is now $(IMG_PATH())")
end

function FIG_PATH()
    fig_path = joinpath(project_path, "color_figures") # set directories
    if !isdir(fig_path)
        mkpath(fig_path)
    end
    return fig_path
end




function color_means(data, pairs...; scale = 0.7)
    # pairs takes the form color => channellist
    # Initialize an array to store the generated RGB channels
    # generates the sclad colors that are the means of the channels selected
    clrs::Vector{RGB{Float64}} = [c for (c,_) in pairs]
    inds::Vector{Vector{Int}} = [l for (_,l) in pairs]
    scaledict = quantile_scale_dict(data)
    getdata(i,j,k) = clamp( scaledict[k] * data[i, j, k] / 255, 0, 1)
    generated_rgb_channels = Array{RGB{Float64}}(undef, size(data, 1), size(data, 2))
    # Generate RGB channels based on the sum of the preceeding colors
    for i in axes(data, 1), j in axes(data, 2)
        out = RGB{Float64}(0)
        for (c,list) in Iterators.zip(clrs,inds)
            out += scale * mean(getdata(i,j,k) for k in list)*c
        end
        # make sure there is no overflow
        m = max(out.r,out.g,out.b,1)
        clipped = RGB(min(out.r,1), min(out.g,1), min(out.b,1))
        out = out * (0.5/m) + clipped * (0.5) # half scaled, half clipped.
        generated_rgb_channels[i, j] = out
    end
    return generated_rgb_channels
end

function color_image(tiff, pairs...; colorscale = 0.7)
    img = rawview(channelview(Images.load(tiff)))
    newpairs = [i => get_channel_list(p) for (i,p) in pairs]
    color_means(img, newpairs...; scale = colorscale)
end

function quantile_scale_dict(array; reference_quantile = 0.95)
    nanto_remove(x) = isinf(x) ? (reference_quantile*255) : Float64(x)
    Dict(chan => 
    (reference_quantile*255) / nanto_remove(quantile(vec(array[:,:,chan]),reference_quantile))
        for chan in axes(array,3))
end

function color_figure(img_file, pairs...; mask_dir="", 
    window = nothing, name = "untitled_$(rand(0:9,4)...)_",
    figpath = FIG_PATH(), datpath = DATA_PATH(), colorscale = 0.7)
    
    total_img_path = joinpath(IMG_PATH(),img_file)
    img_fname = basename(total_img_path)
    patnum = split(split(img_fname,".")[end-1],"_")[end]

    img = color_image(total_img_path, pairs...; colorscale)
    s = size(img)
    if isnothing(window)
        window = (1:s[1],1:s[2])
    end
    if !isempty(mask_dir)
        img2 = rawview(channelview(Images.load(
        joinpath(datpath, mask_dir, img_fname))))[window...]
        bd = cellboundaries(img2)
    end

    Drawing(length(window[2]),length(window[1])..., 
        # where we save the image
        joinpath(figpath, name*mask_dir*"_"*patnum*".pdf"))
        # begin image
    gsave()
    Luxor.transform([0 1 1 0 0 0])
        gsave()
            Luxor.transform([0 1 1 0 0 0])
            placeimage(img[window[1], window[2]], Luxor.Point(0, 0))
        grestore()
        gsave()
        if !isempty(mask_dir)
            setline(0.1)
            translate(Luxor.Point(-.5, -.5))
            draw_boundarydict(bd)
        end
        grestore()
    grestore()
    gsave()
        sss = 10*round(length(window[2])/100, sigdigits=1)
        translate(
            Luxor.Point(length(window[2]),length(window[1])) -
            Luxor.Point(sss,sss/2)*2/3            
            )
        draw_scalebar(sss, color =  RGB(1))
    grestore()
    Luxor.scale( length(window[2])/700)
    translate(Luxor.Point(5,5))
    draw_legends(pairs...)
    finish()
    preview()
end

"""

example to test legeng
@pdf begin
   draw_legends(    HSV(0,1,1) => ["CD3"],
   HSV(60,1,1) => ["CD20"],
   HSV(120,1,1) => ["CD21"],
   HSV(180,1,1) => ["Ir-193","HistH3"]) 
end

"""


function draw_scalebar(size; color = RGB(1.0))
    sethue(color)    
    setline(size/30)
    fontsize(round(Int,size/4))
    fontface("Helvetica")
    Luxor.line(Luxor.Point(-size/2,-size/5), Luxor.Point(size/2,-size/5); action = :stroke)
    Luxor.line(Luxor.Point(-size/2,-size/5 - size/10), Luxor.Point(-size/2,-size/5 + size/10); action = :stroke)
    Luxor.line(Luxor.Point(size/2,-size/5 - size/10), Luxor.Point(size/2,-size/5 + size/10); action = :stroke)
    Luxor.text("$(round(Int,size)) μm",Luxor.Point(0,0), halign=:center, valign = :top)
    
end


function draw_legends(pairs...)
    vec_wrap(x::Vector) = x
    vec_wrap(x::AbstractString) = [x]
    loremipsum = [vec_wrap(jj) for (_,jj) in pairs]
    colors = [ii for (ii,_) in pairs]
    fontface("Helvetica")
    fontsize(20)
    # closure that captures the widest line
    _counter() = (w = 0; (n) -> w = max(w,n))
    counter = _counter()

    setopacity(0)
    h = textbox(map(filter(!isempty,loremipsum)) do x
        join(x, " + ")
    end,
        O + (10, 0),
        leading = 30,
        linefunc = (lnumber, str, pt, h) -> begin
            sethue(colors[lnumber])
            counter(textextents(str)[3])
        end)
    setopacity(0.65)
    sethue(RGBA(0,0,0))
    box(BoundingBox(box(O, Luxor.Point(O.x + counter(0) + 20, h.y - 15); vertices = true)),10 ;action=:fill)
    setopacity(1.0)
    textbox(map(filter(!isempty,loremipsum)) do x
        join(x, " + ")
    end,
        O + (10, 0),
        leading = 30,
        linefunc = (lnumber, str, pt, h) -> begin
        sethue(colors[lnumber])
        end)
end


"""
Machinery for drawing masks
"""

# core function

function addpoints!(bd, v1, i1, j1, v2, i2, j2)
    imid = (i1+i2) / 2
    jmid = (j1+j2) / 2
    idif = (i1-i2) / 2
    jdif = (j1-j2) / 2

    push!(bd[v1], 
        (Luxor.Point(imid - jdif, jmid + idif), Luxor.Point(imid + jdif, jmid - idif)) )
    push!(bd[v2], 
        (Luxor.Point(imid + jdif, jmid - idif), Luxor.Point(imid - jdif, jmid + idif)) )
end

# scan through masks and find the boundary

function cellboundaries(mask)
    (width,height) = size(mask)
    # returns an object
    bndry_dict = Dict(ii => Vector{Tuple{Luxor.Point,Luxor.Point}}() for ii in unique(mask))
    #draw verticle lines
    for ii in 1:width
        val = zero(mask[ii,1])
        for jj in 1:height
            new = mask[ii,jj]
            if new != val
                addpoints!(bndry_dict, val, ii, jj-1, new, ii, jj)
                val = new
            end
        end
        addpoints!(bndry_dict, val, ii, height, zero(val), ii, height + 1)
    end
    for jj in 1:height
        val = zero(mask[1,jj])
        for ii in 1:width
            new = mask[ii,jj]
            if new != val
                addpoints!(bndry_dict, val, ii-1, jj, new, ii, jj)
                val = new 
            end
        end
        addpoints!(bndry_dict, val, width, jj, zero(val), width+1, jj)
    end
    return bndry_dict
end

#rads(pt) = atan(pt.y, pt.x)
crossz(pt1,pt2) = pt1.y*pt2.x - pt1.x * pt2.y

function draw_singlecell_boundaries(vd)
    ii = 1
    outs = Vector{Vector{Luxor.Point}}()
    out = Vector{Luxor.Point}()
    while true
        (v1,v2) = popat!(vd, ii)
        push!(out,v1)
        isempty(vd) ? break : nothing
        ii_list = findall(x-> x[1] == v2, vd)
        if isempty(ii_list) # start over if you can't find your way
            push!(outs,out)
            out = Vector{Luxor.Point}()
            ii = 1
        else
            ii = argmin( ii -> crossz(v1-v2, vd[ii][2] - v2), ii_list)
        end
    end
    push!(outs,out)
    sethue(ColorSchemes.tol_incandescent[clamp(4*(length(outs)-1),1,11)])
    for out in outs
        movecloser!(out,.15)
        Luxor.poly(out; action = :stroke, close = true)
    end
end

function movecloser!(vec,r)
    for (ii, v0,v1,v2) in Iterators.zip(eachindex(vec), circshift(vec,1), vec, circshift(vec,-1))
        dif = v2 - v0
        rot_dif = Luxor.Point(-sign(dif.y), sign(dif.x))
        vec[ii] = v1 + r * rot_dif
    end
end


function draw_boundarydict(bd)
    for (val, vec) in pairs(bd)
        if val > 0
            draw_singlecell_boundaries(vec)
        end
    end
end


"""
functions for reading through panel file and returning the index of the matching row for channel toggling
"""


function find_row_index(csv_file::AbstractString, search_string::AbstractString)
    # Read the CSV file
    data = CSV.File(csv_file)

    # Iterate through rows and find the index
    for (index, row) in enumerate(data)
        # Check if the entry in the kth column starts with the specified string
        if string(row.name) == search_string
            return index
        end
    end

    # If no match is found, return a message indicating so
    error("No matching target for $(search_string) found")
end

function get_target_list(; panel = joinpath(DATA_PATH(),"panel.csv"))
    # Read the CSV file
    data = CSV.File(panel)

    # Iterate through rows and find the index
    [row.name for row in data if !isempty(row.name)]
end

function get_channel_list(list_of_targets; panel = joinpath(DATA_PATH(),"panel.csv"))
    out = Vector{Int}()
    for target in list_of_targets
        ii = find_row_index(panel, target)
        push!(out,ii)
    end
    return out
end

function get_channel_list(target::AbstractString; panel = joinpath(DATA_PATH(),"panel.csv"))
    return get_channel_list([target]; panel)
end

include("download_steinbock.jl")

end
