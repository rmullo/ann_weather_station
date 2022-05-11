source("penman_horario.R")
library(dplyr)
library(plyr)
library(Metrics)
library(xlsx)
require(neuralnet)

header = 11

cabecalho = read.csv(file = 'dados.csv', header = T, fill = TRUE, sep = ";")
lat = as.numeric(unlist(strsplit(cabecalho[2, 1], " "))[2])
long = as.numeric(unlist(strsplit(cabecalho[3, 1], " "))[2])
alt = as.numeric(unlist(strsplit(cabecalho[4, 1], " "))[2])


df = read.csv(file = 'dados.csv', skip = header-1, header = T, fill = TRUE, sep = ";")
df <- dplyr::rename(
          df, 
          ETo = X,
          data = Data.Medicao,
          hora = Hora.Medicao,
          precipitacao = PRECIPITACAO.TOTAL..HORARIO.mm.,
          pressao_atmosferica = PRESSAO.ATMOSFERICA.AO.NIVEL.DA.ESTACAO..HORARIA.mB.,
          pressao_atmosferica_maxima = PRESSAO.ATMOSFERICA.MAX.NA.HORA.ANT...AUT..mB.,
          pressao_atmosferica_minima = PRESSAO.ATMOSFERICA.MIN..NA.HORA.ANT...AUT..mB.,
          pressao_atmosferica_reduzida = PRESSAO.ATMOSFERICA.REDUZIDA.NIVEL.DO.MAR..AUT.mB.,
          radiacao = `RADIACAO.GLOBAL.Kj.mÂ².`,
          temperatura_cpu = TEMPERATURA.DA.CPU.DA.ESTACAO.Â.C.,
          temperatura_bulbo_seco = TEMPERATURA.DO.AR...BULBO.SECO..HORARIA.Â.C.,
          temperatura_ponto_de_orvalho = TEMPERATURA.DO.PONTO.DE.ORVALHO.Â.C.,
          temperatura_maxima = TEMPERATURA.MAXIMA.NA.HORA.ANT...AUT..Â.C.,
          temperatura_minima = TEMPERATURA.MINIMA.NA.HORA.ANT...AUT..Â.C.,
          temperatura_orvalho_maxima = TEMPERATURA.ORVALHO.MAX..NA.HORA.ANT...AUT..Â.C.,
          temperatura_orvalho_minima = TEMPERATURA.ORVALHO.MIN..NA.HORA.ANT...AUT..Â.C.,
          tensao_bateria = TENSAO.DA.BATERIA.DA.ESTACAO.V.,
          umidade_relativa_maxima = UMIDADE.REL..MAX..NA.HORA.ANT...AUT....,
          umidade_relativa_minima = UMIDADE.REL..MIN..NA.HORA.ANT...AUT....,
          umidade_relativa = UMIDADE.RELATIVA.DO.AR..HORARIA...,
          vento_direcao = VENTO..DIRECAO.HORARIA..gr..Â...gr..,
          vento_rajada = VENTO..RAJADA.MAXIMA.m.s.,
          vento_velocidade = VENTO..VELOCIDADE.HORARIA.m.s.
        )
tempdata = c(nrow(df))
temphora = c(nrow(df))

for(i in 4:(nrow(df))){
  
  tempdata[i+3] = df$data[i]
  temphora[i+3] = df$hora[i]
}
for(i in 1:(nrow(df)-3)){
  df$data[i] = tempdata[i]
  df$hora[i] = temphora[i]
}


for (i in 1:nrow(df)) {
  day = as.numeric(unlist(strsplit(df[i, 1], "-"))[3])
  month = as.numeric(unlist(strsplit(df[i, 1], "-"))[2])
  df[i,'mes'] = month
  year = as.numeric(unlist(strsplit(df[i, 1], "-"))[1])
  hour = as.numeric(df[i,2])
  Rs = as.numeric(df[i,8])/1000
  u2 = as.numeric(df[i,22]) 
  RHhr = (as.numeric(df[i,17])+as.numeric(df[i,18]))/2
  tMax = as.numeric(df[i,12])
  tMin = as.numeric(df[i,13])
  df[i,23] = penman_horario(tMax, tMin, alt, RHhr, u2, Rs, hour, day, month, year, lat, long)
}

for (i in 1:ncol(df)) { 
  df[,i]=as.numeric(df[,i])  
}

df = df[,-c(1)]

dfFiltered = df[complete.cases(df),]

normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}


dfFiltered = dfFiltered[sample(nrow(dfFiltered), nrow(dfFiltered)),]

maxmindf <- as.data.frame(lapply(dfFiltered, normalize))
scaleddata<-maxmindf
trainset = scaleddata[1:((nrow(scaleddata)/5)*4),]
testset = scaleddata[(1+nrow(trainset)):nrow(scaleddata),]

algoritimos = c("backprop", "rprop+", "rprop-", "sag", "slr")

for(i in 1:5){
  nn = neuralnet(ETo~
                  precipitacao+
                  pressao_atmosferica+
                  radiacao+
                  temperatura_bulbo_seco+
                  temperatura_ponto_de_orvalho+
                  temperatura_maxima+
                  temperatura_minima+
                  umidade_relativa+
                  vento_velocidade,
                data = trainset[1:500,], 
                hidden = c(8,5),
                algorithm = algoritimos[i],
                learningrate = 0.001,
                rep=1,
                err.fct = "sse",
                act.fct = "logistic",
                threshold = 0.05,
                stepmax = 1e+04,
                linear.output = TRUE
                )
  
  temp_test <- subset(testset, select = c(precipitacao,
                                            pressao_atmosferica,
                                            radiacao,
                                            temperatura_bulbo_seco,
                                            temperatura_ponto_de_orvalho,
                                            temperatura_maxima,
                                            temperatura_minima,
                                            umidade_relativa,
                                            vento_velocidade
                                          )
                      )
 
  nn.results <- neuralnet::compute(nn, temp_test)
  results <- data.frame(actual = testset$ETo, prediction = nn.results$net.result)
 
  predicted=results$prediction*(max(testset$ETo)-min(testset$ETo))+min(testset$ETo)
  actual=results$actual*(max(testset$ETo)-min(testset$ETo))+min(testset$ETo)
  deviation=(actual-predicted)^2
  comparison=data.frame(predicted,actual,deviation)
  
  testset[,algoritimos[i]] = comparison$predicted
}

saida = testset[ , c(22, 24, 25, 26, 27, 28)]
 
colnames(saida)[3] <- "rpropmais"
colnames(saida)[4] <- "rpropmenos"

nn = neuralnet(ETo~
                 backprop+
                 rpropmais+
                 rpropmenos+
                 sag+
                 slr,
               data = saida[1:500,], 
               hidden = c(8,5),
               algorithm = "rprop-",
               learningrate = 0.001,
               rep=1,
               err.fct = "sse",
               act.fct = "logistic",
               threshold = 0.05,
               stepmax = 1e+04,
               linear.output = TRUE
)
nn.results <- neuralnet::compute(nn, saida)
results <- data.frame(actual = testset$ETo, prediction = nn.results$net.result)

predicted=results$prediction*(max(testset$ETo)-min(testset$ETo))+min(testset$ETo)
actual=results$actual*(max(testset$ETo)-min(testset$ETo))+min(testset$ETo)
deviation=(actual-predicted)^2
comparison=data.frame(predicted,actual,deviation)
saida[, "combinado"] = comparison$predicted

write.xlsx(saida,file="Aruivo de saída.xlsx")

