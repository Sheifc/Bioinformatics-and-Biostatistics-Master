---
title: 'PEC1: Secuencias promotoras en E. Coli'
author: "Sheila Fernández Cisneros"
date: '`r format(Sys.Date(),"%e de %B, %Y")`'
output:
  html_document:
    toc: TRUE
    toc_depth: 2
    theme: cosmo
    toc_float: TRUE
    number_section: FALSE
  pdf_document:
    toc: TRUE
    toc_depth: 2
bibliography: biblio.bib
csl: apa.csl
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```
```{r libraries, include=FALSE}
# Cargamos las librerías 

library(knitr)
library(stringr)
library(class)
library(dplyr)
library(gmodels)
library(ggseqlogo)
library(ggplot2)
library(ROCR)
library(pROC)
library(caret)
```

```{r input, include=FALSE}
# Input / Output variables

file <- "promoters.txt"
file1 <- "promoters_onehot.txt"
```

## 1. Escribir en el informe una sección con el título “Algoritmo k-NN” en el que se haga una breve explicación de su funcionamiento y sus características. Además, se presente una tabla de sus fortaleza y debilidades.

# Algoritmo k-NN 

## Breve explicación de su funcionamiento y sus características

De forma general decimos que un algoritmo es un conjunto de reglas o instrucciones definidas y no ambiguas, ordenadas y finitas con un fin concreto como solucionar un problema, realizar un cálculo, procesar datos, realizar una tarea, etc. 

Para poder ejecutar un algoritmo se necesita de disponibilidad de datos y en muchos casos, una gran cantidad de éstos, por otra parte según el tipo de algoritmo se necesita de una mayor potencia de cálculo o no. De forma que existe una relación entre estos tres elementos: disponibilidad de datos, potencia de datos y algoritmo.

Para cada algoritmo se presentará una estructura como ésta: breve presentación del algoritmo, detalles e hiperparámetros y puntos fuertes y débiles.

El algoritmo k-NN se desarrolló por primera vez sobre 1950 como un método no paramétrico en estadística. Se puede usar para problemas tanto de clasificación como de regresión.

La predicción se basa en las *k* muestras de entrenamiento más próximas a la muestra a predecir. 

-En el caso de clasificación, el resultado sería, la clase más frecuente entre sus *k* vecinos más próximos. 

-Si es un problema de regresión, la predicción es un valor promedio de los valores de sus *k* vecinos más próximos. 

Según el número de vecinos usado, el resultado de la predicción puede ser diferente, por tanto el único hiperparámetro que presenta este algoritmo es el número de vecinos más próximo que se representa por la letra *k*. El cual se debe ajustar en el proceso de entrenamiento y suele ser un valor impar para evitar empates en las decisiones de predicción. 

Otro factor importante es la distancia usada para medir la proximidad, dependerá de las características de las variables predictoras. Existen muchos tipos de distancias, la más usual es la distancia euclidiana, otro ejemplo sería la distancia ciudad o Manhattan que va a ser un valor absoluto.

## Fortalezas y debilidades del algoritmo K-NN:

| Fortalezas | Debilidades |
| -- | -- |
| Simple | No produce un modelo |
| Eficaz | Gran consumidor de memoria |
| No asume ninguna distribución de los datos | Requiere preproceso de imputación para tratar valores missing |

No produce un modelo ya que para cada predicción debe de calcular todas las distancias del punto a predecir con todos los datos de entrenamiento. Si hay valores perdidos o missing hay que realizar un preproceso de imputación. 

## 2. Desarrollar una función en R (o Python) que implemente una codificación “one-hot” (one-hot encoding) de las secuencias. Presentar un ejemplo simple de su uso.


Ejemplo simple del uso de one-hot: 

Las bases nitrogenadas que forman los nucleótidos son 4: a, g, c y t. 

Creamos un vector con ellas que llamaremos baseN:

```{r}
baseN <- c("a","g","c","t")
```

### Creamos la función one-hot:

```{r}
one.hot<-function(secuencia, bases){
y<-unlist(strsplit(secuencia,"")) # separamos las bases nitrogenadas que compone la secuencia
sapply(y,function(x){match(bases,x,nomatch=0)}) # The sapply() function in the R Language takes a list, vector, or data frame as input and gives output in the form of an array or matrix object.
}
```

### Realizamos un ejemplo:

```{r}
sec_ejemplo <- "tactag"
ej <- t(one.hot(sec_ejemplo, bases = baseN))
ej
```

Como podemos observar, hemos codificado con 0 y 1 nuestra secuencia ejemplo basándonos en el vector creado inicialmente *baseN*, indicado con números 1, 2, 3 y 4, los componentes de baseN y con ceros la no presencia de dichos componentes en nuestra secuencia ejemplo y con 1 la presencia de dicho componente en nuestra secuencia ejemplo. 

vector <- t(matriz)
dim(vector) <-prod(dim(vector))
vector
```{r}
# lo pasamos a vector:
vector <- t(ej)
dim(vector) <- prod(dim(vector))
vector
```

## 3. Desarrollar un script en R (o Python) que implemente un clasificador knn. El script ha de realizar los siguientes apartados:

## (a) Leer los datos del fichero promoters.txt e indicar el número de observaciones por clase.

Para leer los datos del fichero, primero vamos a mostrar el archivo en el cual tenemos las secuencias. 

```{r, echo=FALSE}
data <- read.table(file, sep=",", stringsAsFactors = FALSE, header = FALSE) 
head(data)
str(data)
```

Observamos que tenemos `r nrow(data)` observaciones de `r ncol(data)` variables, las tres son de tipo character. 

Los atributos del fichero de datos son:
1. Un símbolo de {+/-}, indicando la clase (“+” = promotor).
2. El nombre de la secuencia promotora. Las instancias que corresponden a no promotores se denominan por la posición genómica.
3. Las restantes posiciones corresponden a la secuencia.

Por tanto, lo primero que debemos hacer es convertir a factor con dos niveles la primera columna para posteriormente usar los datos en los correspondientes análisis. 

```{r}
data$V1 <- factor(data$V1, levels = c("+", "-"))
str(data)
```

Para conocer la cantidad de secuencias de cada clase "+","-" :

```{r}
data.frame(table(data[,1]))
```

Podemos comprobar que tenemos `r nrow(data[data$V1 == "+", ])` secuencias promotoras y `r nrow(data[data$V1 == "-", ])` secuencias no promotoras. 

## (b) Transformar las secuencias de nucleótidos en vectores numéricos usando la función de transformación desarrollada anteriormente. En caso que no se haya implementado la función de codificación one-hot, se puede acceder a los datos ya transformados cargando el fichero promoters_onehot.txt.

### Transformación de los datos one.hot: 

La columna 3 del dataset es la que corresponde con las secuencias, por tanto, aplicamos la codificación one.hot a la columna 3 del dataset: 

```{r}
data_onehot <- apply(as.data.frame(data[,3]), 1, one.hot, baseN)
data_onehot <- t(data_onehot)
data_onehot <- as.data.frame(data_onehot)
#head(data_onehot)
#str(data_onehot)
```

Observamos que tenemos `r nrow(data_onehot)` observaciones de `r ncol(data_onehot)` variables.

### Transformación del dataset:

Podemos empezar eliminando la columna 3 y 2 de nuestros datos para quedarnos con la columna que nos interesa que es la de promotor/no promotor (+/-). 

```{r}
data_V1 <- select(data, -V3, -V2)
str(data_V1) # comprobamos que V1 ya se ha transformado a factor
```

Aplicamos un label a los niveles del factor:

```{r}
data_V1$V1 <- factor(data_V1$V1, labels = c("plus","minus"))
head(data_V1)
str(data_V1)
```

Unimos los datasets que contienen la primera columna y la tercera tras la codificación onehot con cbind():

```{r}
dataframe <- cbind (data_V1, data_onehot)
#head(dataframe)
```

Le asignamos nombre a la primera columna:

```{r}
names(dataframe)[1] = "class"
#head(dataframe)
```

## (c) Utilizando la semilla aleatoria 123, separar los datos en dos partes, una parte para training (67%) y una parte para test (33%).

Procedemos a plantar la semilla indicada y separar los datos como es requerido: 

```{r}
set.seed(123) #fijamos la semilla
train <- sample(1:nrow(dataframe),round(2*nrow(dataframe)/3,0)) #con la función sample 
training <- dataframe[train,] # creamos la parte training de los datos
test <- dataframe[-train,] # creamos la parte test de los datos
# Creamos el train y test set solamente de la columna "label":
train_label <- data[train,1] 
test_label <- data[-train,1]
```

Mostramos cuantos promotores hay en training y test:

```{r}
table(training$class)
table(test$class)
```

Otro modo de hacerlo podría ser: 

```{r}
set.seed(123)
split <- sort(sample(nrow(dataframe), nrow(dataframe)*0.67)) # Cogemos el 67% del dataset

train1 <- dataframe[split, -1]
test1 <- dataframe[-split, -1]

train1_label <- dataframe[split, 1]
test1_label <- dataframe[-split, 1]
```

## (d) Aplicar el knn (k = 1, 5, 11, 21, 51, 71) basado en el training para predecir que secuencias del test son secuencias promotoras o no. Además, realizar una curva ROC para cada k y mostrar el valor de AUC.

### KNN() (k = 1, 5, 11, 21, 51, 71):

```{r}
test <- test[-1] # eliminamos la columna class
training <- training[-1] # eliminamos la columna class
```


```{r}
set.seed(123) # fijamos una semilla
pred1 <-knn(train = training, test = test, cl = train_label, k = 1, prob = TRUE)
pred1
CrossTable(x = test_label, y = pred1, prop.chisq = FALSE )
```

```{r}
set.seed(123) # fijamos una semilla
pred5 <-knn(train = training, test = test, cl = train_label, k = 5, prob = TRUE)
pred5
CrossTable(x = test_label, y = pred5, prop.chisq = FALSE )
```

```{r}
set.seed(123) # fijamos una semilla
pred11 <-knn(train = training, test = test, cl = train_label, k = 11, prob = TRUE)
pred11
CrossTable(x = test_label, y = pred11, prop.chisq = FALSE )
```

```{r}
set.seed(123) # fijamos una semilla
pred21 <-knn(train = training, test = test, cl = train_label, k = 21, prob = TRUE)
pred21
CrossTable(x = test_label, y = pred21, prop.chisq = FALSE )
```

```{r}
set.seed(123) # fijamos una semilla
pred51 <-knn(train = training, test = test, cl = train_label, k = 51, prob = TRUE)
pred51
CrossTable(x = test_label, y = pred51, prop.chisq = FALSE )
```

```{r}
set.seed(123) # fijamos una semilla
pred71 <-knn(train = training, test = test, cl = train_label, k = 71, prob = TRUE)
pred71
CrossTable(x = test_label, y = pred71, prop.chisq = FALSE )
```

### Curva ROC para cada k y mostrar el valor de AUC:

```{r}
k <- c(1,5,11,21,51, 71)

par(mfrow=c(3,3))
for (i in k){
  pred <- knn(train = training, test = test, cl = train_label, k=i, prob=TRUE)
 
  prob <- attr(pred, "prob")
  prob1 <- ifelse(pred == "+", prob, 1-prob)
  
  res <- auc(test_label,prob1) 
  
  pred_knn <- ROCR::prediction(prob1, test_label)
  pred_knn <- performance(pred_knn, "tpr", "fpr")
  plot(pred_knn, avg= "threshold", colorize=T, lwd=3, 
       main=paste("ROC curve, k: ", i, ", auc=", round(res,4)))
}
```

## (e) Comentar los resultados de la clasificación en función de la curva ROC, valor de AUC y del número de falsos positivos, falsos negativos y error de clasificación obtenidos para los diferentes valores de k. La clase asignada como positiva son las que representan secuencias promotoras.

### Curvas ROC:

Los puntos que comprenden las curvas ROC indican la tasa de verdaderos positivos en diferentes umbrales de falsos positivos. Para crear las curvas, las predicciones de un clasificador se ordenan según la probabilidad estimada del modelo de la clase positiva, con los valores más grandes primero.

### Valor de AUC: 

Cuanto más cerca esté la curva del clasificador perfecto, mejor será para identificar valores positivos. Esto se puede medir utilizando una estadística conocida como el área bajo la curva ROC (AUC abreviado). El AUC trata el diagrama ROC como un cuadrado bidimensional y mide el área total bajo la curva ROC. AUC varía de 0,5 (para un clasificador sin valor predictivo) a 1,0 (para un clasificador perfecto). Una convención para interpretar las puntuaciones AUC utiliza un sistema similar a las calificaciones académicas con letras:

• A: Sobresaliente = 0,9 a 1,0

• B: Excelente/bueno = 0,8 a 0,9

• C: Aceptable/regular = 0,7 a 0,8

• D: Pobre = 0,6 a 0,7

• E: Sin discriminación = 0,5 a 0,6

Como ocurre con la mayoría de las escalas similares a esta, los niveles pueden funcionar mejor para algunas tareas que para otras; la categorización es algo subjetiva.

También vale la pena señalar que dos curvas ROC pueden tener una forma muy diferente y, sin embargo, tener un AUC idéntico. Por esta razón, un AUC solo puede ser engañoso. La mejor práctica es usar AUC en combinación con un examen cualitativo de la curva ROC.

Fuente: [@lantz]

### Curva ROC para k=71: 

La línea diagonal desde la esquina inferior izquierda hasta la esquina superior derecha del diagrama representa un clasificador sin valor predictivo. Este tipo de clasificador detecta verdaderos positivos y falsos positivos exactamente a la misma velocidad, lo que implica que el clasificador no puede discriminar entre los dos. Esta es la línea de base por la cual se pueden juzgar otros clasificadores. Las curvas ROC que caen cerca de esta línea indican modelos que no son muy útiles. Además coincide con el valor de auc más bajo posible, 0.5.

### Curvas ROC para k=51, k=21, k=5, k=11, k=1: 

Justo en este orden están representadas las curvas y valores auc coincidiendo en orden decreciente de mejor clasificador a peor. 

### Matrices de confusión: 

A partir de los valores expresados en la Matriz de Confusión, es posible contar con una serie de medidas útiles en nuestro análisis. 

Precisión = (TP + TN) / (TP + FP + FN + TN)

Sensibilidad = TP / (TP + FN)

Especificidad = TN / (TN + FP)

```{r, include=FALSE}
conf1 <- confusionMatrix(table(test_label, pred1))
conf5 <- confusionMatrix(table(test_label, pred5))
conf11 <- confusionMatrix(table(test_label, pred11))
conf21 <- confusionMatrix(table(test_label, pred21))
conf51 <- confusionMatrix(table(test_label, pred51))
conf71 <- confusionMatrix(table(test_label, pred71))
```
```{r}
conf1
```

```{r}
conf5
```

```{r}
conf11
```

```{r}
conf21
```

```{r}
conf51
```

```{r}
conf71
```

Para el valor de k=1, obtenemos como Falso positivo, FP=7 y Falso negativo, FN=1. Verdadero postivo, TP=16 y verdadero negativo, TN=11.

Para el valor de k=5, obtenemos como Falso positivo, FP=6 y Falso negativo, FN=2. Verdadero postivo, TP=15 y verdadero negativo, TN=12.

Para el valor de k=11, obtenemos como Falso positivo, FP=7 y Falso negativo, FN=1. Verdadero postivo, TP=16 y verdadero negativo, TN=11.

Para el valor de k=21, obtenemos como Falso positivo, FP=9 y Falso negativo, FN=1. Verdadero postivo, TP=16 y verdadero negativo, TN=9.

Para el valor de k=51, obtenemos como Falso positivo, FP=12 y Falso negativo, FN=0. Verdadero postivo, TP=17 y verdadero negativo, TN=6.

Para el valor de k=71, obtenemos como Falso positivo, FP=18 y Falso negativo, FN=0. Verdadero postivo, TP=17 y verdadero negativo, TN=0.

### Error de clasificación: 

Para calcular el error de clasificación: (FP+FN)/(TP+TN+FP+FN)
A partir de los valores expresados en la Matriz de Confusión, es posible contar con una serie de medidas útiles en nuestro análisis. 

```{r}
error_rate <- function(tp,tn,fp,fn){
  return((fp + fn)/(tp+tn+fp+fn))
}
# Positivos verdaderos para cada valor de K:
tp1=16
tp5=15
tp11=16
tp21=16
tp51=17
tp71=17

# Negativos verdaderos para cada valor de k: 
tn1=11
tn5=12
tn11=11
tn21=9
tn51=6
tn71=0

# Falsos positivos para cada valor de k:
fp1=7
fp5=6
fp11=7
fp21=9
fp51=12
fp71=18

# Falsos negativos para cada valor de k:
fn1=1
fn5=2
fn11=1
fn21=1
fn51=0
fn71=0
  
error1 <- error_rate(tp = tp1, tn= tn1, fp = fp1, fn = fn1)
error5 <- error_rate(tp = tp5, tn= tn5, fp = fp5, fn = fn5)
error11 <- error_rate(tp = tp11, tn= tn11, fp = fp11, fn = fn11)
error21 <- error_rate(tp = tp21, tn= tn21, fp = fp21, fn = fn21)
error51 <- error_rate(tp = tp51, tn= tn51, fp = fp51, fn = fn51)
error71 <- error_rate(tp = tp71, tn= tn71, fp = fp71, fn = fn71)

print(paste0("error rate para k=1 = ", error1))
print(paste0("error rate para k=5 = ", error5))
print(paste0("error rate para k=11 = ", error11))
print(paste0("error rate para k=21 = ", error21))
print(paste0("error rate para k=51 = ", error51))
print(paste0("error rate para k=71 = ", error71))
```

El mayor error rate es para k=71 como era de esperar, le sigue k=51, después k21 y las demás tienen una tasa de error de clasificación similar. 

## 4. Representar las secuencias logo de cada tipo de secuencia (promotor/no promotor). Comentar los resultados obtenidos.

Usaremos la función toupper() para pasar las secuencias a mayúscula. Después separamos las secuencias promotoras de las no promotoras y aplicamos la función ggseqlogo(). 

```{r}
datos <- read.table(file, header=FALSE, sep=",")

toupper <- toupper(datos$V3)
datos1 <- cbind.data.frame(datos$V1, toupper)

names(datos1)[1] = "V1"
head(datos1)

promotor <- datos1[datos1$V1 == "+",]
no_promotor <- datos1[datos1$V1 == "-",]

head(promotor)
head(no_promotor)
```

```{r}
ggseqlogo(promotor[,2])
```


```{r}
ggseqlogo(no_promotor[,2])
```

Representando las secuencias logo se puede ver el grado de conservación de una secuencia. 

ggseqlogo() nos muestra las probabilidades de que aparezcan los nucleótidos en cada posición de la secuencia. Los nucleótidos que aparecen en la parte superior del gráfico y con mayor tamaño són los más probables en cada posición.

La variabilidad de las secuencias viene representada con el tamaño de las letras, de modo que a menor número de nucleótidos diferentes, mayor es la letra, mejor conservación habrá y mayor su frecuencia o probabilidad.

En el gráfico de las secuencias promotoras se observan claramente 3 posiciones con claramente menos variabilidad respecto a todas las demás, las letras más grandes de estas posiciones son T, T y G lo que significa que son los nucleótidos que predominan en estas posiciones. Las frecuencias son claramente más altas que las del gráfico de secuencias no promotoras, concretamente 10 veces más. 

Sin embargo, el gráfico de secuencias no promotoras presenta posiciones con diferente variabilidad, siendo una de ellas la que destaca por encima de las demás, indicando que es la mejor conservada. El nucleótido que predomina en dicha posición es la G. 


