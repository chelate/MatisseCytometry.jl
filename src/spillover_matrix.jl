using CairoMakie

function sm_heatmap(name)
    # takes the csv file as a name
    base = split(name,".")[1:end-1]
    df = CSV.read(joinpath(DATA_PATH(),name), DataFrame)
    function transform(x)
        if x == 1.0
            return NaN
        else
            return min(x,0.04)^(1/2)
        end
    end

    rows = names(df)[2:end]
    cols = df[:, 1]
    dat = Matrix(df[:, 2:end])
    data = dat[:,vec(sum(dat,dims = 1) .> 0.0001)]
    yticks = replace.(string.(rows[vec(sum(dat,dims = 1)) .> 0.0001]),"Di"=>"")
    xticks = replace.(string.(cols),"Di"=>"")

    fig = Figure(;size=(800, 800))
    ax = Axis(fig[1, 1], xticks = (1:length(xticks), xticks), yticks = (1:length(yticks), yticks), xlabel = "Spotted", ylabel = "Observed (% spot)")
    heatmap!(ax, transform.(data) ; colormap= Reverse(:bilbao), nan_color = RGB(.3))
    for i in axes(data,1), j in axes(data,2)
        if 0.9 > data[i, j] > 0.0004 
            txtcolor = data[i, j] > 0.005 ? :white : :black
            text!(ax, "$(round(100*data[i,j], digits = 1))", position = (i, j),fontsize = 10,
                color = txtcolor, align = (:center, :center))
        end
    end
    ax.xticklabelrotation = π / 2
    ax.xticklabelalign = (:right, :center)
    save(fig, joinpath(FIG_PATH(), base*"_heatmap.pdf"))
    fig
end