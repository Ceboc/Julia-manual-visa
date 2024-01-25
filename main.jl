include("src/VISA_INIT.jl")
include("src/THORLABS_INIT.jl")

using JLD2
using ProgressMeter

ts = OSC_ADQ()[1]
θs = 0:0.5:360


DATA_OSC_X1 = []
DATA_OSC_X2 = []
DATA_OSC_Y1 = zeros(Float64,length(ts),length(θs))
DATA_OSC_Y2 = zeros(Float64,length(ts),length(θs))

osc_sig = Channel(1)
mon_osc = @async OSC_monitor(osc_sig)
@showprogress for (i,θ) in enumerate(θs)

    θ_c(θ)
    sleep(0.2)
    xs1, ys1, xs2, ys2 = OSC_ADQ()
    sleep(0.3)


    push!(DATA_OSC_X1,xs1)
    push!(DATA_OSC_X2,xs2)

    DATA_OSC_Y1[:,i] .= ys1
    DATA_OSC_Y2[:,i] .= ys2

    put!(osc_sig,1)
end
list_resources = RM.list_resources()put!(osc_sig,"stop")

OSC_CLOSE()
KDC_entr_close()

file_name = "24012024_malus_1.jld2"
f = jldopen(joinpath("data", file_name), "a+") do file
    configuracion = JLD2.Group(file, "configuracion")
    datos = JLD2.Group(file, "datos")
    configuracion["OSC_preamble"] = OSC.query_ascii_values("wav:preamble?")
    configuracion["OSC_idn"] = OSC.query("*IDN?")
    configuracion["OSC_conf"] = KDC_entr.get_settings()
    configuracion["MOTOR_idn"] = list_thor_devices[2][2]
    datos["DATA_OSC_X1"]=DATA_OSC_X1
    datos["DATA_OSC_X2"]=DATA_OSC_X2
    datos["DATA_OSC_Y1"]=DATA_OSC_Y1
    datos["DATA_OSC_Y2"]=DATA_OSC_Y2
    datos["θs"] = θs
end

maxs = [maximum(cols) for cols in eachcol(DATA_OSC_Y2)]
mins = [minimum(cols) for cols in eachcol(DATA_OSC_Y2)]

extrema_amp = maxs .- mins

begin
    f = Figure()
    ax = Axis(f[1,1],
        xlabel = "t [s]",
        ylabel = "Voltage [V]")
    lines!(ax,DATA_OSC_X1[1],DATA_OSC_Y1[:,568],label = "Ch. 1")
    lines!(ax,DATA_OSC_X2[1],DATA_OSC_Y2[:,568] .* 10,label = "Ch. 2")
    axislegend(ax)
    f
end

begin
    F = Figure()
    ax = Axis(F[1,1],
    xlabel=L"\theta \:[^\circ]",
    ylabel=L"V")

    lines!(ax,θs,extrema_amp)
    DataInspector()
    F
end