# This R script contains several simple ARIMA models for Sales forecasting. While more 
# complicated ARIMA models such as ARIMAX and VAR, also deep learning models such as 
# LSTM and GRU can be explored, this case only limits to the ARIMA models.
# Also these ARIMA models forecast the overall sale over time, more granular forecast over
# different country or product can be explored further.

# Import Library
library(plyr)
library(dplyr)
library(MASS)
library(tseries)
library(forecast)
library(urca)
library(lmtest)
library(ggplot2)
library(stats)
library(lubridate)

# Read in sales data
sales = read.csv("data_science_case/sales.txt", sep = ';')

View(sales)

summary(sales)

# Group by retail week to get the aggregate sales over time
sales_agg <- sales %>% group_by(retailweek) %>% summarise(sales = sum(sales))

min(sales_agg$retailweek)
max(sales_agg$retailweek)

lubridate::week(c(ymd("2014-12-28"), ymd("2017-04-30")))

sales_agg <- ts(sales_agg$sales, start = c(2014, 52), end = c(2017, 18), frequency = 52)

plot(sales_agg)


# Use log transformation to stabilize the series, but not mandatory since no significant exponential/explosive trend observed
# From the graph, the log transformation does not help much on stabilizing the series
log_sales_agg <- log(sales_agg)
plot(log_sales_agg)

# Check decomposition plot, no trend obsrved, might have seasonality
plot(decompose(sales_agg))

# Check stationarity of the level using ADF tests
# It seems that the series is stationary based on the test results, no need to do further differences
View(sales_agg)

plot(sales_agg)

adf.test(sales_agg, alternative = c("stationary"))

adf.test(sales_agg, alternative = c("explosive"))

kpss.test(sales_agg, null = "Level")

# kpss.test(sales_agg, null = "Trend")

# sales_agg %>% ur.df(type = "none", selectlags = "AIC") %>% summary()

sales_agg %>% ur.df(type = "drift", selectlags = "AIC") %>% summary()

sales_agg %>% ur.df(type = "trend", selectlags = "AIC") %>% summary()

ndiffs(sales_agg)

# No need to do further diff, but plot it to check
plot(diff(sales_agg))

# Split the dataset into train and test, keep 20% (~25) as the test set
y_train <- window(sales_agg, end = c(2016, 45))
y_test <- window(sales_agg, start = c(2016, 46))

# Check AC & PAC to estimate the AR/MA orders to incorporate
# Box-Jenkins order selection method
# PACF shows AR orders, no cutoff, but might try 8 as it could be significant
# Might have seasonality
# ACF shows MA orders, gradual decay, might have no MA orders
Pacf(y_train)
Acf(y_train)

# Specifies a few ARIMA models
model_1 <- arima(y_train, order = c(4, 0, 0))
# model_1 <- arima(y_train, order = c(4, 0, 0), fixed = c(NA, 0, 0, NA, NA))
model_2 <- arima(y_train, order = c(2, 0, 0))
model_3 <- arima(y_train, order = c(1, 0, 1))
model_4 <- arima(y_train, order = c(1, 0, 0), seasonal = c(1, 0, 0))
model_5 <- auto.arima(y_train)

# Check model coefs significance
# model_1 has some weakly significant variables, might need to drop, but ok for now
summary(model_1)
coeftest(model_1)

# model_2 is ok for now
summary(model_2)
coeftest(model_2)

# model_3 MA term is weakly significant, ok
summary(model_3)
coeftest(model_3)

# model_4, seasonal ar, is fine
summary(model_4)
coeftest(model_4)

# model_5, some variables are not significant, might need to drop
summary(model_5)
coeftest(model_5)

# Check model residual, correlation and characteristic roots for the models
# model_1 is fine
Acf(residuals(model_1))
Pacf(residuals(model_1))
checkresiduals(model_1)
Box.test(model_1$residuals, type = "Ljung-Box")
qqnorm(model_1$residuals)
qqline(model_1$residuals)
autoplot(model_1)

# Model 2 is fine, will keep for parsimonious reason
Acf(residuals(model_2))
Pacf(residuals(model_2))
checkresiduals(model_2)
Box.test(model_2$residuals, type = "Ljung-Box")
qqnorm(model_2$residuals)
qqline(model_2$residuals)
autoplot(model_2)

# Model 3 is fine
Acf(residuals(model_3))
Pacf(residuals(model_3))
checkresiduals(model_3)
Box.test(model_3$residuals, type = "Ljung-Box")
qqnorm(model_3$residuals)
qqline(model_3$residuals)
autoplot(model_3)

# Model 4 has close to unit roots due to the inclusion of seasonal terms
Acf(residuals(model_4))
Pacf(residuals(model_4))
checkresiduals(model_4)
Box.test(model_4$residuals, type = "Ljung-Box")
qqnorm(model_4$residuals)
qqline(model_4$residuals)
autoplot(model_4)

# Model 5 is ok too, although not perfect in terms of residual correlation, but will keep for now
Acf(residuals(model_5))
Pacf(residuals(model_5))
checkresiduals(model_5)
Box.test(model_5$residuals, type = "Ljung-Box")
qqnorm(model_5$residuals)
qqline(model_5$residuals)
autoplot(model_5)


# In-Sample and Out-of-Sample Accuracy
# model 1 and 4 have best in sample fitness
# model_4 seems to have best Out-of-Sample forecasting accuracy
accuracy(forecast(model_1, h = 25), y_test)
accuracy(forecast(model_2, h = 25), y_test)
accuracy(forecast(model_3, h = 25), y_test)
accuracy(forecast(model_4, h = 25), y_test)
accuracy(forecast(model_5, h = 25), y_test)


# Pick model 4, plot forecasted values and true values
autoplot(forecast(model_4, 25))

autoplot(sales_agg) +
  autolayer(forecast(model_4, 25), series = "ARIMA(1, 0, 0), SEASONAL(1, 0, 0)") + 
  xlab("Week") + ylab("Sales") + 
  ggtitle("Forecasts for Sales") + 
  guides(colour = guide_legend(title = "Forecast"))


# Estimate model 4 on all the data and product model coefs and forecasts
final_model <- arima(sales_agg, order = c(1, 0, 0), seasonal = c(1, 0, 0))

final_model

final_model$coef

forecast(final_model)

autoplot(forecast(final_model))

# One concern is that training data set is too short, and the model is not sufficient
# As demonstrate below buy using auto arima on the whole data set can product a forecast that capture the seasonality better
model_6 <- auto.arima(sales_agg)
summary(model_6)
autoplot(forecast(model_6))


# We also don't need to through away other model we could explore to ensemble them a weight such as 0.5
final_model_forecast <- forecast(final_model)
model_6_forecast <- forecast(model_6)
final_prediction <- 1/2*final_model_forecast$mean + 1/2*model_6_forecast$mean

autoplot(sales_agg, series = 'Historical') +
  autolayer(final_prediction, series = "Ensembled ARIMA Models") + 
  xlab("Week") + ylab("Sales") + 
  ggtitle("Forecasts for Sales") + 
  guides(colour = guide_legend(title = "Forecast for Sales")) + 
  theme(legend.position = c(0.83, 0.92))

