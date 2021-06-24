using DrWatson
@quickactivate "HEMI"

## TODO 
# Replicación de resultados para percentiles o una medida sencilla 
# Generación de slicing de fechas para CountryStructure

## Configuración de procesos
using Distributed
addprocs(4, exeflags="--project")

@everywhere begin 
    using Dates, CPIDataBase
    using InflationFunctions
    using InflationEvalTools
end

# Carga de librerías 
using JLD2

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

# Datos hasta 2019
gtdata_19 = gtdata[Date(2019,12)]

# Funciones de inflación 
# totalfn = InflationTotalCPI()
PERC = 0.65:0.01:0.80
percfn = InflationPercentileEq.(PERC) |> Tuple |> EnsembleFunction

## Carga parámetro

@load datadir("param", "gt_param_ipc_cb.jld2") tray_infl_pob
tray_infl_pob = tray_infl_pob[1:120+108-11]

tray_infl_pob = Float32[5.42722940444946,5.21740913391113,5.1054835319519,5.04974126815796,5.00702857971191,4.97795343399048,4.9976110458374,5.07713556289673,5.09072542190552,5.17375469207764,5.28535842895508,5.3938627243042,5.47831058502197,5.61403036117554,5.65212965011597,5.72646856307983,5.79174757003784,5.84725141525269,5.92467784881592,6.0011625289917,6.05566501617432,6.0272216796875,6.04208707809448,6.05975389480591,6.08925819396973,6.05583190917969,6.06763362884521,6.01415634155273,5.97792863845825,5.97262382507324,5.96133470535278,5.94263076782227,5.99491596221924,6.08052015304565,6.07551336288452,6.05849027633667,6.06149435043335,6.26296997070313,6.38947486877441,6.54394626617432,6.62696361541748,6.71412944793701,6.81958198547363,6.89680576324463,6.99925422668457,7.03741312026978,7.17200040817261,7.4135422706604,7.5512170791626,7.79668092727661,7.79038667678833,7.92993307113647,8.06832313537598,8.14713287353516,8.18707942962646,8.23985290527344,8.20285034179688,8.22887420654297,8.31437110900879,8.4993953704834,8.57541561126709,8.6611385345459,8.82681655883789,8.76948833465576,8.70902538299561,8.70592594146729,8.71362686157227,8.71266174316406,8.79708480834961,8.81947326660156,8.71167182922363,8.49747657775879,8.41513824462891,8.3585262298584,8.30085277557373,8.32761573791504,8.38985443115234,8.39413452148438,8.41584205627441,8.50903987884521,8.47275257110596,8.49907398223877,8.67732810974121,8.84299278259277,9.06616401672363,9.44085121154785,9.59079265594482,9.89489555358887,10.1481437683105,10.2132558822632,10.3988885879517,10.4956150054932,10.5220317840576,10.5350017547607,10.5076198577881,10.5484008789063,10.413969039917,10.0748777389526,9.78797721862793,9.59815979003906,9.37088775634766,9.2099666595459,9.10444259643555,9.08539295196533,9.0456485748291,9.10017490386963,9.18064117431641,9.34454154968262,9.37796783447266,8.30346298217773,8.18573188781738,7.73259401321411,7.41826295852661,7.27552175521851,6.99235200881958,6.63022994995117,6.34915828704834,5.82382678985596,5.09952306747437,4.22003269195557,3.87661457061768,3.82914543151855,3.80297899246216,3.75332832336426,3.72897386550903,3.74255180358887,3.778076171875,3.78526449203491,3.7574291229248,3.73300313949585,3.73671054840088,3.7601113319397,3.74870300292969,3.70476245880127,3.68313789367676,3.64233255386353,3.61073017120361,3.58501672744751,3.59588861465454,3.67016792297363,3.66079807281494,3.64001989364624,3.63075733184814,3.63088846206665,3.56161594390869,3.47850322723389,3.38002443313599,3.29815149307251,3.20215225219727,3.1114935874939,2.87374258041382,2.60219573974609,2.50618457794189,2.49432325363159,2.41216421127319,2.27516889572144,2.22748517990112,2.23615169525146,2.24192142486572,2.22964286804199,2.22527980804443,2.21860408782959,2.24995613098145,2.26815938949585,2.30616331100464,2.3207426071167,2.37178802490234,2.4274468421936,2.4813175201416,2.5352954864502,2.59305238723755,2.65364646911621,2.71923542022705,2.78573036193848,2.87866592407227,2.93818712234497,2.9606819152832,2.98001766204834,3.04447412490845,3.13156843185425,3.17363739013672,3.18421125411987,3.24362516403198,3.31120491027832,3.34535837173462,3.37328910827637,3.43178510665894,3.52380275726318,3.59112024307251,3.63972187042236,3.61354351043701,3.61169576644897,3.64061594009399,3.70385646820068,3.69281768798828,3.68163585662842,3.70273590087891,3.70516777038574,3.6950945854187,3.63929271697998,3.58268022537231,3.51992845535278,3.52936983108521,3.52401733398438,3.49041223526001,3.44551801681519,3.43583822250366,3.39800119400024,3.33651304244995,3.31544876098633,3.38348150253296,3.49035263061523,3.50204706192017,3.49658727645874,3.50468158721924,3.56094837188721,3.60382795333862];



## Trayectorias y MSE

using Statistics

tray_infl = pargentrayinfl(percfn, gtdata; rndseed = 0, K=125_000); # 12:54

# @save datadir("percentiles", "trayectorias", "tray_infl.jld2") tray_infl
# @load datadir("percentiles", "trayectorias", "tray_infl.jld2") tray_infl

# Distribución de errores por realización 
mse_dist = dropdims(permutedims(mean((tray_infl .- tray_infl_pob) .^ 2; dims=1), (3,2,1)), dims=3)

# Métricas de evaluación 
mse = mean( (tray_infl .- tray_infl_pob) .^ 2 ; dims=[1, 3]) |> vec
rmse = mean( sqrt.((tray_infl .- tray_infl_pob) .^ 2); dims=[1, 3]) |> vec
me = mean((tray_infl .- tray_infl_pob), dims=[1, 3]) |> vec

# Ancho de la distribución de MSE 
std(mse_dist; dims=1)
std(mse_dist; dims=1) / 125_000


## Gráfica de distribución MSE 
using Plots

best_pk = argmin(mse)
histogram(mse_dist[:, best_pk], normalize=:probability)

sq_dist = vec( (tray_infl[:, best_pk, :] .- tray_infl_pob) .^ 2 )
histogram(sq_dist, normalize=:probability)
xlims!(0,1)

err_dist = vec( (tray_infl[:, best_pk, :] .- tray_infl_pob) )
histogram(err_dist, normalize=:probability)


## Gráfica de percentiles

scatter(PERC, mse, label="MSE",
    size=(800, 600), 
    title="Evaluación de percentiles", 
    legend = :bottomright)

scatter(PERC, rmse, label="RMSE",
    size=(800, 600), 
    title="Evaluación de percentiles", 
    legend = :bottomright)

scatter(PERC, me, label="ME",
    size=(800, 600), 
    title="Evaluación de percentiles", 
    legend = :bottomright)

## Gráfica de trayectoria promedio

m_tray_infl = dropdims(mean(tray_infl; dims=3), dims=3)
plot(Date(2001, 12):Month(1):Date(2019, 12), m_tray_infl, 
    label = :none, 
    size = (800, 600))
plot!(Date(2001, 12):Month(1):Date(2019, 12), tray_infl_pob, 
    label = "Trayectoria paramétrica", 
    linewidth=5)


## Una sola medida

tray_infl = pargentrayinfl(InflationPercentileEq(74), gtdata[Date(2019,12)]; rndseed = 0, K=125_000);

mse_dist = vec(mean((tray_infl .- tray_infl_pob) .^ 2; dims=1))

# Métricas de evaluación 
mse = mean( (tray_infl .- tray_infl_pob) .^ 2)
rmse = mean( sqrt.((tray_infl .- tray_infl_pob) .^ 2))
me = mean((tray_infl .- tray_infl_pob))

# Ancho de la distribución de MSE 
mean(mse_dist)
std(mse_dist)
std(mse_dist) / 125_000

sqerr_dist = vec((tray_infl .- tray_infl_pob) .^ 2)

mean(sqerr_dist)
std(sqerr_dist)
std(sqerr_dist) / 125_000

# Gráficas
histogram(sqerr_dist, normalize=:probability)
xlims!(0,1)

histogram(mse_dist, normalize=:probability)
