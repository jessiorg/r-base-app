# R API Server with Plumber
# Main entry point

library(plumber)
library(jsonlite)
library(logger)

# Set up logging
log_threshold(INFO)
log_appender(appender_file("/var/log/plumber.log", append = TRUE))

# Load utility functions
source("/app/api/utils/helpers.R")

# Create the plumber router
pr <- plumb("/app/api/endpoints/")

# CORS filter
pr$filter("cors", function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }
})

# Logging filter
pr$filter("logger", function(req) {
  log_info(paste(req$REQUEST_METHOD, req$PATH_INFO))
  plumber::forward()
})

# Error handling
pr$setErrorHandler(function(req, res, err) {
  log_error(paste("Error:", err$message))
  res$status <- 500
  list(
    success = FALSE,
    error = "Internal server error",
    message = err$message
  )
})

# Health check endpoint
pr$handle("GET", "/health", function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    version = "1.0.0"
  )
})

# Start the server
log_info("Starting R API server on port 8000")
pr$run(
  host = "0.0.0.0",
  port = 8000,
  swagger = TRUE
)