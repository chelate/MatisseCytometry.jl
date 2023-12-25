using Luxor


function draw_scale(hue,saturation; nh = 360, ns = 100)
    maxr = saturation + (1 / ns / 2)
    minr = saturation - (1 / ns / 2)
    maxθ = 2*pi*(hue/360 + (1 / nh / 2))
    minθ = 2*pi*(hue/360 - (1 / nh / 2))
    hsv = RGB(HSV(360-hue,saturation,1))
    sethue(red(hsv),green(hsv),blue(hsv))
    setline(0.1)
    arc(Point(0,0), maxr,minθ,maxθ)
    carc(Point(0,0), minr,maxθ,minθ)
    fillstroke()
end

##
@pdf begin
    setline(10)
    sethue("purple")
    scale(2)
    gsave()
    scale(100)
    for ii in 1:360
        for jj in range(0,1,100)
            draw_scale(ii,jj;nh = 360,ns = 100)
        end
    end
    grestore()
    sethue("black")
    setline(1.0)
    for ii in 0:10:350
        θ = -(ii/360)*2*pi
        line(Point(100*cos(θ), 100*sin(θ)),Point(105*cos(θ), 105*sin(θ)); action = :stroke)
        text(string(ii), Point(110*cos(θ), 110*sin(θ)), angle=θ, valign = :middle)
    end
end