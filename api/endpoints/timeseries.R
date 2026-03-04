# Time Series Analysis Endpoints
# Forecasting, decomposition, trend analysis

library(forecast)
library(tseries)
library(zoo)

#* Time Series Forecast
#* Forecast future values using ARIMA
#* @param data:numeric Time series data
#* @param periods Number of periods to forecast
#* @param method Forecast method (default: arima)
#* @post /timeseries/forecast
#* @serializer unboxedJSON
function(data, periods = 5, method = "arima") {
  tryCatch({
    ts_data <- ts(data)
    
    if (method == "arima") {
      fit <- auto.arima(ts_data)
    } else if (method == "ets") {
      fit <- ets(ts_data)
    } else {
      return(list(
        success = FALSE,
        error = "Method must be 'arima' or 'ets'"
      ))
    }
    
    forecast_result <- forecast(fit, h = periods)
    
    return(list(
      success = TRUE,
      forecast = as.numeric(forecast_result$mean),
      lower_80 = as.numeric(forecast_result$lower[, 1]),
      upper_80 = as.numeric(forecast_result$upper[, 1]),
      lower_95 = as.numeric(forecast_result$lower[, 2]),
      upper_95 = as.numeric(forecast_result$upper[, 2]),
      method = method,
      model = forecast_result$method
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Time Series Decomposition
#* Decompose time series into trend, seasonal, and remainder
#* @param data:numeric Time series data
#* @param frequency Frequency of the time series
#* @param type Decomposition type: additive or multiplicative
#* @post /timeseries/decompose
#* @serializer unboxedJSON
function(data, frequency = 12, type = "additive") {
  tryCatch({
    ts_data <- ts(data, frequency = frequency)
    
    if (type == "multiplicative") {
      decomp <- decompose(ts_data, type = "multiplicative")
    } else {
      decomp <- decompose(ts_data, type = "additive")
    }
    
    return(list(
      success = TRUE,
      trend = as.numeric(decomp$trend),
      seasonal = as.numeric(decomp$seasonal),
      remainder = as.numeric(decomp$random),
      type = type
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Moving Average Smoothing
#* Smooth time series with moving average
#* @param data:numeric Time series data
#* @param window Window size
#* @param centered Use centered moving average (default: true)
#* @post /timeseries/smooth
#* @serializer unboxedJSON
function(data, window = 3, centered = TRUE) {
  tryCatch({
    if (centered) {
      smoothed <- rollmean(data, k = window, align = "center", fill = NA)
    } else {
      smoothed <- rollmean(data, k = window, align = "right", fill = NA)
    }
    
    return(list(
      success = TRUE,
      smoothed = as.numeric(smoothed),
      window = window,
      centered = centered
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}