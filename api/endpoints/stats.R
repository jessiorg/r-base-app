# Statistical Analysis Endpoints
# Descriptive statistics, correlation, regression

library(stats)

#* Descriptive Statistics
#* Calculate mean, median, sd, min, max, quartiles
#* @param data:numeric Array of numeric values
#* @post /stats/describe
#* @serializer unboxedJSON
function(data) {
  tryCatch({
    if (length(data) < 2) {
      return(list(
        success = FALSE,
        error = "Data must contain at least 2 values"
      ))
    }
    
    result <- list(
      success = TRUE,
      count = length(data),
      mean = mean(data, na.rm = TRUE),
      median = median(data, na.rm = TRUE),
      sd = sd(data, na.rm = TRUE),
      variance = var(data, na.rm = TRUE),
      min = min(data, na.rm = TRUE),
      max = max(data, na.rm = TRUE),
      q25 = quantile(data, 0.25, na.rm = TRUE),
      q75 = quantile(data, 0.75, na.rm = TRUE),
      iqr = IQR(data, na.rm = TRUE),
      skewness = moments::skewness(data, na.rm = TRUE),
      kurtosis = moments::kurtosis(data, na.rm = TRUE)
    )
    
    return(result)
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Correlation Analysis
#* Calculate correlation between two variables
#* @param x:numeric First variable
#* @param y:numeric Second variable
#* @param method Method: pearson, spearman, or kendall
#* @post /stats/correlation
#* @serializer unboxedJSON
function(x, y, method = "pearson") {
  tryCatch({
    if (length(x) != length(y)) {
      return(list(
        success = FALSE,
        error = "x and y must have the same length"
      ))
    }
    
    cor_test <- cor.test(x, y, method = method)
    
    return(list(
      success = TRUE,
      correlation = cor_test$estimate,
      p_value = cor_test$p.value,
      confidence_interval = cor_test$conf.int,
      method = method
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Linear Regression
#* Perform simple linear regression
#* @param x:numeric Independent variable
#* @param y:numeric Dependent variable
#* @post /stats/regression
#* @serializer unboxedJSON
function(x, y) {
  tryCatch({
    if (length(x) != length(y)) {
      return(list(
        success = FALSE,
        error = "x and y must have the same length"
      ))
    }
    
    model <- lm(y ~ x)
    summary_model <- summary(model)
    
    return(list(
      success = TRUE,
      coefficients = list(
        intercept = coef(model)[1],
        slope = coef(model)[2]
      ),
      r_squared = summary_model$r.squared,
      adj_r_squared = summary_model$adj.r.squared,
      f_statistic = summary_model$fstatistic[1],
      p_value = pf(
        summary_model$fstatistic[1],
        summary_model$fstatistic[2],
        summary_model$fstatistic[3],
        lower.tail = FALSE
      ),
      residual_std_error = summary_model$sigma
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* T-Test
#* Perform Student's t-test
#* @param group1:numeric First group
#* @param group2:numeric Second group
#* @param paired Paired test (default: false)
#* @post /stats/ttest
#* @serializer unboxedJSON
function(group1, group2, paired = FALSE) {
  tryCatch({
    test <- t.test(group1, group2, paired = paired)
    
    return(list(
      success = TRUE,
      statistic = test$statistic,
      p_value = test$p.value,
      confidence_interval = test$conf.int,
      mean_difference = test$estimate
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}