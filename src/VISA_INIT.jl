using PyCall
using GLMakie
using Observables

visa = pyimport("pyvisa")

RM = visa.ResourceManager()

list_resources = RM.list_resources()

OSC = RM.open_resource(list_resources[1])

@info OSC.query("*IDN?")


function OSC_inic()
    OSC.write("*RST")
    sleep(1)
    OSC.write(":AUTOSCALE")
    sleep(0.1)
    OSC.write("TIMebase:Scale 2.0E-3")
    sleep(0.1)
    OSC.write("CHANNEL2:DISPLAY 1")
    sleep(0.1)
    OSC.write("CHANNEL2:SCALE 200 mV")
    sleep(0.1)
    OSC.write("CHANNEL1:OFFSet 0 V")
    sleep(0.1)
    OSC.write("CHANNEL1:OFFSet 370 mV")
    sleep(0.1)
end

OSC_inic()

function data_to_values(data, params)
    formato, tipo, puntos, cuenta, x_incr, x_orig, x_ref, y_incr, y_orig, y_ref = params
    a = 1:puntos
    xs = @. ((a - x_ref) * x_incr) + x_orig
    ys = @. ((data - y_ref) * y_incr) + y_orig
    return xs, ys
end

function OSC_Channel_adq(channel::Int)
    OSC.write("WAVEFORM:SOURCE CHAN$channel")
    sleep(0.1)
    params = OSC.query_ascii_values("wav:preamble?")
    sleep(0.1)
    data = OSC.query_binary_values("WAVeform:DATA?", datatype="B", is_big_endian=true)
    sleep(0.1)
    data_to_values(data, params)
end

function OSC_cons(escala,ofs)
    xs1, ys1 = OSC_Channel_adq(1)
    xs2, ys2 = OSC_Channel_adq(2)
    ys2 *= escala
    ys2 .-= ofs

    xs1, ys1, xs2, ys2
end

function OSC_ADQ()
    @info "Data query from oscilloscope"
    OSC.write("WAVEFORM:POINTS MAX")
    sleep(0.1)
    OSC.write(":SINGLE")
    sleep(0.1)

    xs1, ys1 = OSC_Channel_adq(1)
    sleep(0.1)
    xs2, ys2 = OSC_Channel_adq(2)

    OSC.write(":RUN")

    xs1, ys1, xs2, ys2
end

function OSC_CLOSE()
    OSC.close()
end


function OSC_monitor(chan)
    xs1, ys1, xs2, ys2 = Observable.(OSC_cons(1e2,10))
    
    
    g = Figure()
    axg = Axis(g[1,1],
    xlabel = L"t",
    ylabel = L"V",
    title = "Oscilloscope")
    
    lines!(axg, xs1,ys1, label = "ch1")
    lines!(axg, xs2,ys2, label = "ch2")
    axislegend(axg)
    # DataInspector falla con el tema negro
    # quizá hay que levantar un issue
    #DataInspector()
    gg = display(GLMakie.Screen(),g)
    

    while true
        data = take!(chan)
        #sleep(0.1)
        #@info "TOMA OSC"
        xs1[], ys1[], xs2[], ys2[] = OSC_cons(1e2,10)

        if data == "stop"
            @info "END OSCILLOSCOPE MONITOR"
            close(gg)
            break
        end
    end
end