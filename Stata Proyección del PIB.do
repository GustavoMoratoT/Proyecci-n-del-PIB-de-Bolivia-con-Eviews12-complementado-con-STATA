import excel "C:\Users\GUSTAVO\Desktop\GustavoALL\Cursos\Udemy\STATA\Practica de STATA\PIB.xlsx", sheet("Hoja1") firstrow
describe

***Crearmos nuestra Fecha temporal Anual***
set obs 42
gen anual= 1980 +_n -1
tsset anual
browse

*Filtros y Ciclos***

*Tecnica de Moving Average (MA), lo malo de esta tecnica es que no me permite conocer su ciclo
*los dos valroes de 2 nos muestra que iremos con 2 adelante y con 2 atras, el 1 que si voy a usar el valor actual y que formara parte del calculo del promedio, en caso de poner 0 el valor actual no sera considerado en el calculo, lo mas recomendable es poner 1.
tssmooth ma PIB_ma = PIB, window(2 1 2) //PIB suavizado,

tsline PIB_ma PIB, xtitle("") title("PIB y Tendencia")  ///
	legend(order(1 "Tendencia" 2 "PIB") cols(5)) //
	tlabel(1980(5)2021, grid labsize(*0.1)) lpattern(solid -)
	
**Filtro de Hodrick - Prescott***
tsfilter hp PIB_ciclo = PIB, trend(PIB_tendencia) smooth(100)

tsline PIB_tendencia PIB, xtitle("") title("PBI and Tendencia")  /// TENDENCIA
	legend(order(1 "Tendencia del PBI" 2 "PBI") cols(2)) ///
	tlabel(1980(2)2021, grid labsize(*0.7)) lpattern(solid -)
tsline PIB_ciclo, xtitle("") ytitle("") title("Ciclo del PIB")  /// CICLO
	tlabel(1980(2)2021, grid labsize(*0.7)) lpattern(solid -)
	

**********************************************************Primer Paso: Analizar la Estacionaridad**************************************

***PRUEBA GRAFICA***
//si la grafica fluctura al rededor de una valor fijo >>> Estacionariedad
tsline PIB

//Como varios "palitos" estan fuera del nivel de confianza>>No Estacionaria
ac lnpib   //funcion de autocorrelacion, si hay muchos palitos continuos y q estan muy alejados de la banda de confianza entonces decimos que la Serie tiene una Raiz Unitaria
pac lnpib //funcion de autocorrelacion parcial, nos muestra la correlacion entre la serie con su resago pero considerando los resagos intermedios
corrgram lnpib
*********PRUEBAS FORMALES******

***TEST DICKEY-FULLER*****
*H0: la serie es No Estacionaria (tiene Raiz Unitaria)
*H1: La serie es estacionaria
**Regla de ORO: si P-Values > 0.05, aceptamos la H0
dfuller lnpib
*MacKinnon approximate p-value for Z(t)=0.3010, Como P-Value>0.05. No se rechaza la H0, por tanto la serie es NO ESTACIONARIA

***TEST PHILIPS-PERRON******
*HO: la serie es No Estacionaria (tiene Raiz Unitaria)
pperron lnpib
**MacKinnon approximate p-value for Z(t)=0.0651. Como P-Value>0.05. No se rechaza la H0, por tanto la serie es NO ESTACIONARIA

**TEST DF-GLS****** minuto 6:20 video 94
*HO: la serie es No Estacionaria (tiene Raiz Unitaria con drift)
dfgls lnpib,max(2) //analizamos con 2 resagos

**CONCLUIMOS QUE LA SERIE ES NO ESTACIONARIA***

***********************************************2 PASO: TRANSFORMAR LA SERIE EN ESTACIONARIA*****************************
gen dlnpib= d.lnpib  //aplicamos la primera diferencia
br

*pruebas graficas*
tsline dlnpib //analizando, la serie fluctua al rededor de una media (osea nos indica es estacionaria, a pesar de los picos que observamos)
ac dlnpib //la autocorrelacion se ve que cae, ya no es una autocorrelacion que deciende lentamente... osea es Estacionaria

*pruebas formales* H0: la serie es no estacionaria PValue>0.05
dfuller dlnpib // si Z(t) al compararlo con 5% Critical Value esta a la izquierna nos indica que la serie es Estacionaria
pperron dlnpib  //si Z(t) al compararlo con 5% Critical Value esta a la izquierna nos indica que la serie es Estacionaria
dfgls dlnpib,max(2) //analizamos con 6 resagos, si DF-GLD l compararlo con 5% Critical Value esta a la izquierna nos indica que la serie es Estacionaria

**CONCLUIMOS QUE LA SERIE ES ESTACIONARIA***

****************************************************3 PASO: ESTIMAR EL MODELO ARIMA*************************************
*AC --> orden de MA(q)
*PAC --> irden de AR(p)

ac dlnpib   // hay 2 palitos fuera >> MA (1 2)
pac dlnpib  //el palito 1,2,8 y 9 caen fuera >> AR(1 2 8 9)

*Tenemos que hacer varias combinacion
arima lnpib, arima(12,1,1) //una manera de hacerlo, el 1 en medio es la diferencia 
arima dlnpib, ar(1 2) ma(1 2)  //otra forma, en la cual ya mi variable esta diferenciada
estat ic

arima dlnpib, ar(1 2 5 12)  ma(1)  //
estat ic  ///criterio de IC para la decision

**Como el segundo modelo tiene menor AIC, nos quedamos con el. 
**La idea es probar con varios tipos de modelos, quizas en el segundo modelo quitandole el ar(8) y ma(2)...