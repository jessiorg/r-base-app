# Utility Functions for R API

# Validate numeric array
validate_numeric_array <- function(data, min_length = 1) {
  if (!is.numeric(data)) {
    stop("Data must be numeric")
  }
  if (length(data) < min_length) {
    stop(paste("Data must contain at least", min_length, "values"))
  }
  return(TRUE)
}

# Safe division
safe_divide <- function(numerator, denominator) {
  if (denominator == 0) {
    return(NA)
  }
  return(numerator / denominator)
}

# Format response
format_success_response <- function(data, message = NULL) {
  response <- list(
    success = TRUE,
    data = data
  )
  if (!is.null(message)) {
    response$message <- message
  }
  return(response)
}

format_error_response <- function(error_message) {
  return(list(
    success = FALSE,
    error = error_message
  ))
}

# Calculate percentage change
percentage_change <- function(old_value, new_value) {
  return((new_value - old_value) / old_value * 100)
}

# Round to specified decimals
round_decimals <- function(value, decimals = 4) {
  return(round(value, decimals))
}