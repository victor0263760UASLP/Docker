using ModeCouplingTheory
using Plots
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
        println(" Data saved as ", nombre)
    end
end

function find_analytical_C_k(k, η)
    A = -(1 - η)^-4 * (1 + 2η)^2
    B = (1 - η)^-4 * 6η * (1 + η / 2)^2
    D = -(1 - η)^-4 * 0.5 * η * (1 + 2η)^2
    Cₖ = @. 4π / k^6 * (
        24D - 2B * k^2 - (24D - 2(B + 6D) * k^2 + (A + B + D) * k^4) * cos(k)
        + k * (-24D + (A + 2B + 4D) * k^2) * sin(k)
    )
    return Cₖ
end

function find_analytical_S_k(k, η)
    Cₖ = find_analytical_C_k(k, η)
    ρ = 6 / π * η
    Sₖ = @. 1 + ρ * Cₖ / (1 - ρ * Cₖ)
    return Sₖ
end

ϕ_VW(ϕ::Float64) = ϕ * (1.0 - (ϕ / 16.0))
k_VW(ϕ::Float64, k::Float64) = k * ((ϕ_VW(ϕ) / ϕ)^(1.0 / 3.0))



function main(args...)
    if length(args) < 3
        @error "Se requieren 3 argumentos: PHI, local_folder volume_folder "
        return
    end

    try
        φ = parse(Float64, args[1])
        local_folder = args[2]
        volume_folder = args[3]

        
        mkpath(local_folder)
        mkpath(volume_folder)

    
        Nk = 100
        kmax = 40.0
        dk = kmax / Nk
        k = dk * (collect(1:Nk) .- 0.5)
        k_corr = k_VW.(φ, k)
        φ_corr = ϕ_VW(φ)
        S_calc = find_analytical_S_k(k_corr, φ_corr)

        k_all = [k; k]
        S_all = [ones(Nk); S_calc]

    
        ∂F0 = zeros(2 * Nk)
        α = 0.0
        β = 1.0
        γ = @. k_all^2 / S_all
        δ = 0.0

        kernel = SCGLEKernel(φ, k_all, S_all)
        equation = MemoryEquation(α, β, γ, δ, S_all, ∂F0, kernel)
        solver = TimeDoublingSolver(Δt = 1e-5, t_max = 1e10, N = 8, tolerance = 1e-8, verbose = true)
        sol = @time solve(equation, solver)

        
        files = []
        for ik in [7, 18, 25, 39]
            Fk = get_F(sol, 1:10:800, ik)
            t = get_t(sol)[1:10:800]
            push!(files, [log10.(t) Fk ./ S_all[ik]])
        end

        filename = "Fskt_phi_$(replace(string(φ), "." => "_")).dat"
        save_data(joinpath(local_folder, filename), files[1], header = "log10(t) Fs(k,t)")  
        save_data(joinpath(volume_folder, filename), files[1], header = "log10(t) Fs(k,t)")

        
        resumen = [
            
            ["phi" φ];
            ["Nk" Nk];
            ["t_max" solver.t_max]
        ]
        resumen_name = "resumen_phi_$(replace(string(φ), "." => "_")).dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header = "Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header = "Parámetro Valor")

        # Graficar
        p = plot(xlabel = "log10(t)", ylabel = "Fs(k,t)", ylims = (0, 1), legend = :bottomleft)
        for (idx, ik) in enumerate([7, 18, 25, 39])
            Fk = get_F(sol, 1:10:800, ik)
            t = get_t(sol)[1:10:800]
            plot!(p, log10.(t), Fk ./ S_all[ik], label = "k = $(round(k_all[ik], digits=2))", lw = 2)
        end
        display(p)
        savefig(p, joinpath(local_folder, "Fskt_phi_$(replace(string(φ), "." => "_")).svg"))
        savefig(p, joinpath(volume_folder, "Fskt_phi_$(replace(string(φ), "." => "_")).svg"))

# savefig(p, joinpath(local_folder, "Fskt_phi_$(replace(string(φ), "." => "_")).png"))
# savefig(p, joinpath(volume_folder, "Fskt_phi_$(replace(string(φ), "." => "_")).png"))

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)

