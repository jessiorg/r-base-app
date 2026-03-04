# Trading and Financial Calculations
# Returns, moving averages, RSI, volatility, Sharpe ratio

library(TTR)
library(PerformanceAnalytics)

#* Calculate Returns
#* Calculate simple or logarithmic returns
#* @param prices:numeric Array of prices
#* @param type Return type: simple or log
#* @post /trading/returns
#* @serializer unboxedJSON
function(prices, type = "simple") {
  tryCatch({
    if (length(prices) < 2) {
      return(list(
        success = FALSE,
        error = "Need at least 2 prices"
      ))
    }
    
    if (type == "log") {
      returns <- diff(log(prices))
    } else {
      returns <- diff(prices) / head(prices, -1)
    }
    
    return(list(
      success = TRUE,
      returns = returns,
      cumulative_return = prod(1 + returns) - 1,
      mean_return = mean(returns),
      type = type
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Moving Average
#* Calculate simple or exponential moving average
#* @param prices:numeric Array of prices
#* @param period Moving average period
#* @param type MA type: simple or exponential
#* @post /trading/moving-average
#* @serializer unboxedJSON
function(prices, period = 20, type = "simple") {
  tryCatch({
    if (type == "exponential") {
      ma <- EMA(prices, n = period)
    } else {
      ma <- SMA(prices, n = period)
    }
    
    return(list(
      success = TRUE,
      ma = as.numeric(ma),
      period = period,
      type = type
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* RSI (Relative Strength Index)
#* Calculate RSI indicator
#* @param prices:numeric Array of prices
#* @param period RSI period (default: 14)
#* @post /trading/rsi
#* @serializer unboxedJSON
function(prices, period = 14) {
  tryCatch({
    rsi <- RSI(prices, n = period)
    current_rsi <- tail(na.omit(rsi), 1)
    
    # Determine signal
    signal <- "neutral"
    if (current_rsi > 70) signal <- "overbought"
    if (current_rsi < 30) signal <- "oversold"
    
    return(list(
      success = TRUE,
      rsi = as.numeric(rsi),
      current_rsi = as.numeric(current_rsi),
      period = period,
      signal = signal
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Volatility
#* Calculate volatility (standard deviation of returns)
#* @param returns:numeric Array of returns
#* @param annualize Annualize volatility (default: false)
#* @param periods_per_year Trading periods per year (default: 252)
#* @post /trading/volatility
#* @serializer unboxedJSON
function(returns, annualize = FALSE, periods_per_year = 252) {
  tryCatch({
    vol <- sd(returns, na.rm = TRUE)
    
    if (annualize) {
      vol <- vol * sqrt(periods_per_year)
    }
    
    return(list(
      success = TRUE,
      volatility = vol,
      annualized = annualize
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Sharpe Ratio
#* Calculate Sharpe ratio
#* @param returns:numeric Array of returns
#* @param risk_free_rate Risk-free rate (annualized)
#* @param periods_per_year Trading periods per year (default: 252)
#* @post /trading/sharpe-ratio
#* @serializer unboxedJSON
function(returns, risk_free_rate = 0.02, periods_per_year = 252) {
  tryCatch({
    rf_period <- risk_free_rate / periods_per_year
    excess_returns <- returns - rf_period
    
    sharpe <- mean(excess_returns, na.rm = TRUE) / sd(excess_returns, na.rm = TRUE)
    sharpe_annualized <- sharpe * sqrt(periods_per_year)
    
    return(list(
      success = TRUE,
      sharpe_ratio = sharpe,
      sharpe_ratio_annualized = sharpe_annualized,
      risk_free_rate = risk_free_rate
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Bollinger Bands
#* Calculate Bollinger Bands
#* @param prices:numeric Array of prices
#* @param period Period (default: 20)
#* @param sd_multiplier Standard deviation multiplier (default: 2)
#* @post /trading/bollinger-bands
#* @serializer unboxedJSON
function(prices, period = 20, sd_multiplier = 2) {
  tryCatch({
    bb <- BBands(prices, n = period, sd = sd_multiplier)
    
    return(list(
      success = TRUE,
      upper_band = as.numeric(bb[, "up"]),
      middle_band = as.numeric(bb[, "mavg"]),
      lower_band = as.numeric(bb[, "dn"]),
      bandwidth = as.numeric(bb[, "pctB"]),
      period = period
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}