#Rivera Juarez Victor Guadalupe Rivera Juarez 9 de Junio del 2025

using OrnsteinZernike: PercusYevick, HypernettedChain, CustomPotential, SimpleLiquid, DensityRamp, NgIteration, solve
using DelimitedFiles

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == typeof("hola") "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
if flag
    println("Data saved as ", nombre) end
end

function main(args...)
    if length(args) < 10
        @error "Se requieren 10 argumentos: σ z kBT φ M N_stages max_iter chi_list local_folder volume_folder"
        return
    end

    σ            = parse(Float64, args[1])
    z            = parse(Float64, args[2])
    kBT          = parse(Float64, args[3])
    φ            = parse(Float64, args[4])
    M            = parse(Int, args[5])
    N_stages     = parse(Int, args[6])
    max_iter     = parse(Int, args[7])
    chi_list_str = args[8]
    local_folder = args[9]
    volume_folder = args[10]
    

    mkpath(local_folder)  # Crea carpeta si no existe
    mkpath(volume_folder)

    χ = parse.(Float64, split(chi_list_str, ","))

    # Parámetros Yukawa
    κ = σ / 566.02
    p = (λB = 0.71432 / σ, σ = 1.0, κ = κ, z = -z)

    function Yukawa_R(r, p)
        κa = p.κ * 0.5 * p.σ
        LB = (p.z^2) * p.λB * exp(2 * κa) / (1 + κa)^2
        return LB * exp(-p.κ * r) / r
    end

    potential = CustomPotential(Yukawa_R, p)

    dims = 3
    ρ = (6 / π) * φ
    system = SimpleLiquid(dims, ρ, kBT, potential)
    closure = HypernettedChain()

    dr = 200.0 / M
    method = NgIteration(M = M; dr = dr, max_iterations = max_iter, N_stages = N_stages)
    densities = ρ .* χ
    method2 = DensityRamp(method, densities)

    SOL = solve(system, closure, method2)

    phi_str = replace(string(round(φ, digits=4)), "." => "p")

    for (idx, sol) in enumerate(SOL)
        gr_filename = joinpath(local_folder, "gdr_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(gr_filename, hcat(sol.r, sol.gr), header = "r g(r)")

        sk_filename = joinpath(local_folder, "sdk_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(sk_filename, hcat(sol.k, sol.Sk), header = "k S(k)")

        gr_filename = joinpath(volume_folder, "gdr_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(gr_filename, hcat(sol.r, sol.gr), header = "r g(r)")

        sk_filename = joinpath(volume_folder, "sdk_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(sk_filename, hcat(sol.k, sol.Sk), header = "k S(k)")
    end

end

    
main(ARGS...)

