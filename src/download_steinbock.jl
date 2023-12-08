using ZipFile
using Downloads



function unzip(file, exdir="")
    # Determine the full path of the input zip file
    fileFullPath = isabspath(file) ? file : joinpath(pwd(), file)
    # Get the base path and output path for extraction
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(), exdir)))
    # Create the output directory if it doesn't exist
    isdir(outPath) ? "" : mkdir(outPath)
    # Open the zip archive for reading
    zarchive = ZipFile.Reader(fileFullPath)
    # Iterate through files in the zip archive
    for f in zarchive.files
        # Determine the full path for the extracted file
        fullFilePath = joinpath(outPath, f.name)
        # Check if the entry is a directory and create it if so
        if endswith(f.name, "/") || endswith(f.name, "\\")
            mkdir(fullFilePath)
        else
            # Write the content of the file to the extracted location
            write(fullFilePath, read(f))
        end
    end

    # Close the zip archive
    close(zarchive)
end

function download_steinbock_example(;dest = DATA_PATH())
    print("Do you want to download the test set? May overwrite data in $(dest) \n (yes/no): ")
    user_response = readline()
    if lowercase(user_response) == "yes"
        url_images = "https://zenodo.org/record/7412972/files/img.zip"
        destfile_images = joinpath(dest, "img.zip")
        Downloads.download(url_images, destfile_images)
    # Unzip images
        unzip(destfile_images)
        rm(destfile_images)
    # Remove the zip file

    # Download masks
        url_masks = "https://zenodo.org/record/7412972/files/masks_deepcell.zip"
        destfile_masks = joinpath(dest, "masks.zip")
        Downloads.download(url_masks, destfile_masks)
    # Unzip masks
        unzip(destfile_masks)
        rm(destfile_masks)
        url_panel = "https://zenodo.org/record/7412972/files/panel.csv"
        destfile_panel = joinpath(dest,"panel.csv")
        Downloads.download(url_panel, destfile_panel)
        println("Downloaded the 2023-ImagingWorkshop Example data")
    end
end
