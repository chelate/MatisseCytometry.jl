# MatisseCytometry

[![Build Status](https://github.com/chelate/MatisseCytometry.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chelate/MatisseCytometry.jl/actions/workflows/CI.yml?query=branch%3Amain)

MatisseCytometry.jl is meant to mass-generate publication-ready images for mass cytometry experiments that are processed using the well documented [Steinbock](https://bodenmillergroup.github.io/steinbock/latest/) pipeline from the Bodenmiller group.

 > Color is my day-long obsession, joy and torment. - Monet

The human eye has only three "channels", so using more than three colors is "irrational". Nonetheless, artistically minded colleagues have suggested even the six colors offered by MCDViewer are "not enough". With MatisseCytometry, you can use as many colors as you like, going  beyond what is "rational", or even what is in "good taste". In fact, it is easy to go beyond the bounds of sanity itself! With MatisseCytometry you can quickly produce publication quality images that strain the very fabric of the mind!!

> It is the eye of ignorance that assigns a fixed and unchangeable color to every object” - Paul Gauguin

## Directions:

Before anything, download *juliaup*, the julia installer: "https://github.com/JuliaLang/juliaup" 

and make sure you can run julia. A start menu shortcut should appear in windows.

### Installation 
Open julia and add this package. You will probably also need to Colors.jl to define your color scheme. You only need to do this once and it should take awhile.

To add this package, you need to run the following commands in the REPL (the julia terminal)
   
```julia
using Pkg
Pkg.add(url="https://github.com/chelate/MatisseCytometry.jl")
Pkg.add("Colors")
```

then `using` the package and tell the package which project directory you wish to make your crazy images in.

```julia
using MatisseCytometry
using Colors
set_project("path/to/parentdirectoryofdata") # change to a data path
# test it out in a spare copy of your data in case anything goes wrong.
```

If you get confused about where your project directory is, run
```
MatisseCytometry.home
```
to see what the parent directory is.


### Usage
The main function is `color_figure` which has the arguments

``` colorfigure(base_filename, color_scheme...; optional_argments)```

`base_filename` is the multichannel tiff to build off of

`color_scheme` is a set of arguments specifying how different proteins should be colored, each entry looks like

`Color => ["target1","target2"]`

Usually there is no point is choosing colors with a low value (darkness), and we are most often interested in maximally saturated colors for maximum contrast between targets. Thus, the `HSV()` color specification is is particularly useful, where we set the saturation and value parameters to 1 and only change the hue "angle" on the color wheel, which runs from 0-360. To choose "whiter" colors one can set the saturation value closer to zero.

There are lots of ColorSchemes available in the julia package [ColorSchemes](https://juliagraphics.github.io/ColorSchemes.jl/stable/catalogue/#MetBrewer).

Example using a single image

```julia
color_figure("patient_001.tiff",
    # define you color scheme color => [list of targets]
    HSV(0,1,1) => ["CD3"],
    HSV(60,1,1) => ["CD20"],
    HSV(180,1,1) => ["Ir-193"],
        colorscale = 0.9, # overall saturation scale
        # if you want to draw masks, give the directory name of the mask folder
        mask_dir = "masks", # assumes that the mask file shares the same name
        name = "seurat", # signify the importance of this image with an optional name
        # otherwise it will be assigned a random number
        window = (300:600,300:600) # optional zoom in on a subregion
        )
```

heres a slight more exciting example

```julia
seurat = [ # name a color scheme for your records or to reuse
    HSV(0,1,1) => ["CD3"],
    HSV(60,1,1) => ["CD20"],
    HSV(90,1,1) => ["CD7"]
    HSV(120,1,1) => ["CD45RA"]
    HSV(180,1,1) => ["DNA1", "DNA2"]]
```

Walk all the files in img using:

```julia
for file in readdir(joinpath(MatisseCytometry.IMG_PATH()))
    color_figure(file,
        # assumes that the image is in the "img" folder
        # color => channel list
        seurat...,
        colorscale = 0.9, # overall saturation scale
        # if you want to draw masks, give the directory name of the mask folder
        mask_dir = "masks_deepcell",
        # assumes that the mask file shares the same name
        name = "seurat", # appends the patient number to the name
        window = (300:600,300:600) # zoom in on a subregion
        )
end
```


# Directory Structure
This project directory is assumed to have the special structure of a `steinbock` project: 

If you don't have access to the `steinbock` command tool you will need to generate the cannonical (assumed) directory structure yourself this will look like

```
MainDirectory
    |-color_figures (if this doesn't exist it will be created by the script)
    |-data (contains at minimum)
        |-img (contains .tiff files, simple multiplexed greyscale images)
        |-panel.csv  a csv file with column titled "name" 
            where the target row that matches   the channel of the .tiff files.
        |-some_masks if you wish to plot masks, this directory 
        |   contains .tiff numbered masks which result from segmentation
```


Check what MatCyto thinks the main directory by running `MatisseCytometry.main`.

This file structure is typically the result of running the steinbock preprocess step
```
alias steinbock="docker run -v path/to/data:/data -u $(id -u):$(id -g) ghcr.io/bodenmillergroup/steinbock:0.15.0"

steinbock preprocess imc panel
steinbock preprocess imc images --hpf 50

```

This data directory *must* contain a steinbock-formatted file where the rows match the channels in the img tiffs. If "data" is called something different, you can use `MatisseCytometry.set_data_directory(datapath)` to set the name to something other than data. In the 2023 workshop it would actually be set to `joinpath(data,steinbock)`.


If you don't have such a directory, you can play with the project by downloading the example steinbock test images after loading the project in a directory of your choice (say Documents)

```julia
MatisseCytometry.set_project("path/for/your/Documents/test")
MatisseCytometry.download_steinbock_example()
```

Careful with this function, since if you have something already in your project folder `path/for/your/Documents/test`, there is a chance download will overwrite it.




```
