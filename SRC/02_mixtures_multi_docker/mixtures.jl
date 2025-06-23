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
        println("Data saved as ", nombre)
    end
end

function main(args...)
    if length(args) < 5
        @error "Se requieren 5 argumentos: D1, D2, rho_total, kBT, local_folder, volume_folder"
        return
    end

    try
        D1 = parse(Float64, args[1])
        D2 = parse(Float64, args[2])
        rho_total = parse(Float64, args[3])
        kBT = parse(Float64, args[4])
        local_folder = args[5]
        volume_folder = args[6]

        mkpath(local_folder)
        mkpath(volume_folder)

        D = [D1, D2]
        potential = HardSpheres(D)
        dims = 3
        ρ = rho_total * [0.5, 0.5] 
        system = SimpleLiquid(dims, ρ, kBT, potential)

        closure = PercusYevick()

        sol = solve(system, closure)

        datos = [sol.r sol.gr[:, 1, 1] sol.gr[:, 1, 2] sol.gr[:, 2, 1] sol.gr[:, 2, 2]]
        filename = "result_mixture_$(D1)_$(D2)_$(rho_total)_$(kBT).dat"

        header = "r g_11 g_12 g_21 g_22"
        save_data(joinpath(local_folder, filename), datos, header=header)
        save_data(joinpath(volume_folder, filename), datos, header=header)

        resumen = [
            ["D1" D1];
            ["D2" D2];
            ["rho_total" rho_total];
            ["rho_1" ρ[1]];
            ["rho_2" ρ[2]];
            ["kBT" kBT];
            ["puntos" length(sol.r)]
        ]
        resumen_name = "resumen_parametros.dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header="Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header="Parámetro Valor")

    catch error
        @error "Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
