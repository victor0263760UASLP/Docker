using OrnsteinZernike
using DelimitedFiles

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
    try
        φ = parse(Float64, args[1])
        kBT = parse(Float64, args[2])
        M = parse(Int, args[3])
        N_stages = parse(Int, args[4])
        local_folder = args[5]
        volume_folder = args[6]

        # Crear carpetas si no existen
        mkpath(local_folder)
        mkpath(volume_folder)

        max_iter = 10000
        dr = 100.0 / M
        ρ = (6 / π) * φ

        potential = HardSpheres(1.0)
        dims = 3
        system = SimpleLiquid(dims, ρ, kBT, potential)
        closure = PercusYevick()
        method = NgIteration(M=M; dr=dr, max_iterations=max_iter, N_stages=N_stages)

        sol = solve(system, closure, method)

        # Guardar datos S(k)
        filename = "Sk_phi$(φ)_kBT$(kBT)_M$(M)_N$(N_stages).dat"
        header = "k S(k)"
        data = hcat(sol.k, sol.Sk)

        save_data(joinpath(local_folder, filename), data; header=header)
        save_data(joinpath(volume_folder, filename), data; header=header)

        # Resumen de parámetros
        resumen = [
            ["phi" φ];
            ["kBT" kBT];
            ["M" M];
            ["N_stages" N_stages];
            ["rho" ρ];
            ["dr" dr];
            ["puntos_k" length(sol.k)]
        ]

        resumen_name = "resumen_parametros.dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header="Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header="Parámetro Valor")

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)