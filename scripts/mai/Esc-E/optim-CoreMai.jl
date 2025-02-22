# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using CSV, DataFrames, Chain 

# Directorios de resultados 
savepath = datadir("results", "CoreMai", "Esc-E", "Optim")
savepath_best = datadir("results", "CoreMai", "Esc-E", "BestOptim")

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

## Funciones de apoyo para optimización iterativa de cuantiles 
includet(scriptsdir("mai", "mai-optimization.jl"))

## Configuración para simulaciones

# Parámetros de configuración general del escenario de evaluación 
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(60),
    :resamplefn => ResampleSBB(36),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2018, 12),
    :nsim => 125_000
)

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mai_nseg => [3,4,5,10],
    :mai_method => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 100
MAXITER = 1000

for config in optconfig
    optimizemai(config, gtdata; K, savepath, maxiterations = MAXITER)
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
# select(df, :method, :mse, :n, :K, :q)


## Optimizar con mayor número de simulaciones y puntos iniciales previos

prelim_methods = @chain df begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las dos menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:mse)
            first(2)
        end
    end
    select(:method, :n, :mse, :q)
end


# Optimizar con mayor número de simulaciones 
K = 10_000
MAXITER = 30

for r in eachrow(prelim_methods)
    # Crear configuración para optimizar 
    config = merge(genconfig, Dict(
        :mai_nseg => r.n, 
        :mai_method => eval(Symbol(r.method))
    ))

    # Optimizar las metodologías candidatas con vectores iniciales 
    optimizemai(config, gtdata; 
        K, savepath,
        qstart = r.q, # Vector inicial de búsqueda 
        maxiterations = MAXITER)
end


## Evaluar los mejores métodos utilizando criterios básicos 

df = collect_results(savepath)
best_methods = @chain df begin
    filter(:K => k -> k == K, _) 
    combine(gdf -> gdf[argmin(gdf.mse), :], groupby(_, :method))
    select(:method, :n, :mse, :q)
end

# Obtener funciones de inflación de mejores métodos MAI
bestmaifns = map(eachrow(best_methods)) do r 
    # Obtener método de strings guardados por función optimizemai
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    InflationCoreMai(eval(method))
end

# Diccionarios de configuración para evaluación 
config_mai = merge(genconfig, Dict(:inflfn => bestmaifns)) |> dict_list

# Ejecutar evaluaciones finales
run_batch(gtdata, config_mai, savepath_best, savetrajectories=true)
