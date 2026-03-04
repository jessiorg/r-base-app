# Data Processing Endpoints
# Outlier detection, normalization, transformation

#* Outlier Detection
#* Detect outliers using IQR or Z-score method
#* @param data:numeric Array of numeric values
#* @param method Detection method: iqr or zscore
#* @param threshold Threshold multiplier (default: 1.5 for IQR, 3 for zscore)
#* @post /data/outliers
#* @serializer unboxedJSON
function(data, method = "iqr", threshold = NULL) {
  tryCatch({
    if (method == "iqr") {
      if (is.null(threshold)) threshold <- 1.5
      
      q1 <- quantile(data, 0.25, na.rm = TRUE)
      q3 <- quantile(data, 0.75, na.rm = TRUE)
      iqr <- q3 - q1
      
      lower_bound <- q1 - threshold * iqr
      upper_bound <- q3 + threshold * iqr
      
      outliers <- data < lower_bound | data > upper_bound
      
    } else if (method == "zscore") {
      if (is.null(threshold)) threshold <- 3
      
      z_scores <- abs((data - mean(data, na.rm = TRUE)) / sd(data, na.rm = TRUE))
      outliers <- z_scores > threshold
      
    } else {
      return(list(
        success = FALSE,
        error = "Method must be 'iqr' or 'zscore'"
      ))
    }
    
    clean_data <- data[!outliers]
    
    return(list(
      success = TRUE,
      outliers = which(outliers),
      outlier_values = data[outliers],
      clean_data = clean_data,
      n_outliers = sum(outliers),
      method = method
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Normalize Data
#* Normalize data using min-max or z-score normalization
#* @param data:numeric Array of numeric values
#* @param method Normalization method: minmax or zscore
#* @post /data/normalize
#* @serializer unboxedJSON
function(data, method = "minmax") {
  tryCatch({
    if (method == "minmax") {
      min_val <- min(data, na.rm = TRUE)
      max_val <- max(data, na.rm = TRUE)
      normalized <- (data - min_val) / (max_val - min_val)
      
    } else if (method == "zscore") {
      normalized <- (data - mean(data, na.rm = TRUE)) / sd(data, na.rm = TRUE)
      
    } else {
      return(list(
        success = FALSE,
        error = "Method must be 'minmax' or 'zscore'"
      ))
    }
    
    return(list(
      success = TRUE,
      normalized = normalized,
      method = method
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}

#* Missing Values Imputation
#* Fill missing values using mean, median, or forward fill
#* @param data:numeric Array with potential NA values
#* @param method Imputation method: mean, median, or forward
#* @post /data/impute
#* @serializer unboxedJSON
function(data, method = "mean") {
  tryCatch({
    na_indices <- which(is.na(data))
    
    if (length(na_indices) == 0) {
      return(list(
        success = TRUE,
        data = data,
        n_imputed = 0,
        message = "No missing values found"
      ))
    }
    
    if (method == "mean") {
      fill_value <- mean(data, na.rm = TRUE)
      data[na_indices] <- fill_value
      
    } else if (method == "median") {
      fill_value <- median(data, na.rm = TRUE)
      data[na_indices] <- fill_value
      
    } else if (method == "forward") {
      data <- zoo::na.locf(data, na.rm = FALSE)
      
    } else {
      return(list(
        success = FALSE,
        error = "Method must be 'mean', 'median', or 'forward'"
      ))
    }
    
    return(list(
      success = TRUE,
      data = data,
      n_imputed = length(na_indices),
      imputed_indices = na_indices,
      method = method
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}