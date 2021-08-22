library(plyr)
library(MASS)
library(tseries)
library(forecast)

data = read.csv("C:/Users/zefan/Desktop/model/AirConditioning.csv")

View(data)



# read in training data
train_data <- data[29:59, 2:5]

names(train_data) <- as.matrix(train_data[1, ])
train_data <- train_data[-1, ]

train_data <- rename(train_data, c('a/c' = 'a_c', 'House Age' = 'House_Age'))

rownames(train_data) <- NULL

train_data$a_c <- as.numeric(as.character(train_data$a_c))
train_data$House_Age <- as.numeric(as.character(train_data$House_Age))
train_data$Price <- as.numeric(as.character(train_data$Price))
train_data$temp <- as.numeric(as.character(train_data$temp))

View(train_data)


# first try a OLS
mod1 <- lm(a_c ~ House_Age + Price + temp, data = train_data)

summary(mod1)

# drop Price since it's not significant
mod2 <- lm(a_c ~ House_Age + temp, data = train_data)

summary(mod2)

# AIC stepwise selection
mod3 <- stepAIC(mod1, direction = "both")

summary(mod3)

accuracy(mod3)

# choose mod3 based on AIC and significance, then need to test residual, 
# not normally distributed
qqnorm(mod3$residuals)
qqline(mod3$residuals)

#test for correlation
acf(mod3$residuals)
durbin.watson(mod3)


# Try a ARIMAX model
# First fit ARIMA on a/c, then add other exogenous variables
y = ts(train_data$a_c, start = 1, frequency = 1)



# No obvious trend, but could be non-stationary due to the graph meander
plot(y)

#plot(decompose(y))

# use log to stabilize, but not mandatory since no exponential trend
plot(log(y))

logy = log(y)

# check stationarity using ADF
adf.test(y, alternative = c("stationary"))
adf.test(y, alternative = c("explosive"))


adf.test(logy, alternative = c("stationary"))
adf.test(logy, alternative = c("explosive"))


# use urca for detailed specification
urca::ur.df(y, type = c("none", "drift", "trend"), lags = 1, selectlags = c("Fixed", "AIC", "BIC"))

urca::ur.df(y, type = c("drift"), selectlags = c("AIC"))


# will try difference as unit root is not rejected
plot(diff(y))

plot(diff(logy))

adf.test(diff(y), alternative = c("stationary"))
adf.test(diff(y), alternative = c("explosive"))

adf.test(diff(logy), alternative = c("stationary"))
adf.test(diff(logy), alternative = c("explosive"))


plot(diff(diff(y)))
adf.test(diff(diff(y)), alternative = c("stationary"))


plot(diff(diff(logy)))
adf.test(diff(diff(logy)), alternative = c("stationary"))


# Series is too short to conclude, find non-stationary, but could be due to short duration
# might need to difference twice, which is not common
# try auto arima to see
auto.arima(y)
auto.arima(logy)

# auto arima choose ARIMA(3, 0, 0), try pacf and acf to see p and q
acf(y)
pacf(y)


# A/C price is too short to be stationary, and difference will not work, so would not suggest ARIMA
# try ARIMA(3, 0, 0)
mod4 <- arima(y, order = c(3, 0, 0))
summary(mod4)

# test on residual, correlogram
acf(mod4$residuals)
pacf(mod4$residuals)

# Ljung-Box Q test, no overall autorelation on residual
Box.test(mod4$residuals, lag = 20, type = 'Ljung-Box')

# Characteristics roots tests
plot(mod4)

# qqplot, not perfectly normal, need more data
qqnorm(mod4$residuals)
qqline(mod4$residuals)




# try logy
mod5 <- auto.arima(logy)
summary(mod5)

# test on residual, correlogram
acf(mod5$residuals)
pacf(mod5$residuals)

# Ljung-Box Q test, overall autorelation on residual exist
Box.test(mod5$residuals, lag = 20, type = 'Ljung-Box')

# Characteristics roots tests
plot(mod5)


# will use mod4 for now, ARIMA(3, 0, 0), add exogenous variable

mod6 <- arima(y, order = c(3, 0, 0), xreg = train_data[, 2:4])

summary(mod6)





# Extract Test data
# read in training data
test_data <- data[15:21, 2:4]

names(test_data) <- as.matrix(test_data[1, ])
test_data <- test_data[-1, ]

test_data <- rename(test_data, c('Temperature' = 'temp', 'House Age' = 'House_Age'))

rownames(test_data) <- NULL

test_data$House_Age <- as.numeric(as.character(test_data$House_Age))
test_data$Price <- as.numeric(as.character(test_data$Price))
test_data$temp <- as.numeric(as.character(test_data$temp))

View(test_data)


# Forecast using different models
# mod3 is ok if pass durbin-watson correlation test
mod3
output_mod3 = predict(mod3, test_data)

output_mod3

# negative y and also insignificant coeffs, should not choose mod6
mod6
output_mod6 = predict(mod6, newxreg = test_data)


# mod4 is ok, but it might not be not stationary, and have issue on ACF, PACF, could keep for ensembling
mod4

output_mod4 = forecast(mod4, 6)

output_mod4

forecast(mod4, 6)

plot(forecast(mod4))


# in general, don't think there is a perfect model in this situation
# as stationarity is not satisfied, especially when duration is short,
# so might use a simple regression model 3, however, there might be 
# auto-correlation exist, which will increase variance and confidence-interval.
# Therefore, would keep two models mod3 and mod4, ensemble to keep forecast accuracy and reduce variance


series1 <- output_mod3

series2 <- output_mod4$mean

series1
series2

# ensemble using 0.5 as weight
final_prediction <- 1/2*series1 + 1/2*series2

final_prediction

