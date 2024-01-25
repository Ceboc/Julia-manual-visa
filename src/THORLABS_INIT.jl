Thor = pyimport("pylablib.devices.Thorlabs")

list_thor_devices = Thor.list_kinesis_devices()

@info list_thor_devices[1][2]
@info list_thor_devices[2][2]

KDC_entr = Thor.KinesisMotor(list_thor_devices[2][1],scale="K10CR1")

function KDC_ent_to_home()
    KDC_entr.home()

    while KDC_entr.is_homing()
        print("Homing \r")
        sleep(0.5)
    end
    println("")
end

θλ2_cal = 0.0
function θ_λ2(θ₀)
    θ = θ₀ - θλ2_cal
    @info "Moving λ/2 a $(θ₀)°                    "
    KDC_entr.move_to(θ)
    while KDC_entr.get_status()[1] == "moving_bk"
        sleep(0.1)
        print("λ/2 Position,  θ = $(round(KDC_entr.get_position(),digits=4) - θλ2_cal)°                     \r")
    end
    @info "λ/2 angle $(θ₀)°                               "
end

function KDC_entr_close()
    KDC_entr.close()
end