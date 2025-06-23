using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == String "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
    if flag
        println(" Data saved as ", nombre)
    end
end

function main(args...)
    if length(args) < 4
        @error "Se requieren 4 argumentos: PHI, KBT, local_folder, volume_folder"
        return
    end

    try
        φ = parse(Float64, args[1])
        kBT = parse(Float64, args[2])
        local_folder = args[3]
        volume_folder = args[4]

        println("Argumentos recibidos: ", args)

        mkpath(local_folder)
        mkpath(volume_folder)

        dims = 3
        σ = 1.0
        ϵ = 1.0
        ρ = (6 / π) * φ
        potential = HardSpheres(σ)
        closure = PercusYevick()
        system = SimpleLiquid(dims, ρ, kBT, potential)

        sol = solve(system, closure)

        datos = [sol.r sol.gr]
        filename = "result_HS_phi_$(replace(string(φ), "." => "_")).dat"

        save_data(joinpath(local_folder, filename), datos, header = "r g(r)")
        save_data(joinpath(volume_folder, filename), datos, header = "r g(r)")

        resumen = [
            ["tipo_potencial" "HardSpheres"];
            ["sigma" σ];
            ["phi" φ];
            ["rho" ρ];
            ["kBT" kBT];
            ["puntos" length(sol.r)]
        ]
        resumen_name = "resumen_parametros_phi_$(replace(string(φ), "." => "_")).dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header = "Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header = "Parámetro Valor")

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
