# Contributing to R Base API

Thank you for your interest in contributing! 🎉

## How to Contribute

### Reporting Bugs

1. Check existing issues
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - API request/response examples
   - System information

### Suggesting Features

1. Check existing feature requests
2. Create an issue describing:
   - The endpoint or feature
   - Use case
   - Example request/response
   - Implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test all endpoints
5. Update documentation
6. Submit a pull request

## Development Guidelines

### Adding New Endpoints

```r
# In api/endpoints/your_category.R

#* Endpoint Description
#* Detailed description of what this endpoint does
#* @param param1 Description of parameter 1
#* @param param2 Description of parameter 2
#* @post /category/endpoint-name
#* @serializer unboxedJSON
function(param1, param2) {
  tryCatch({
    # Validate inputs
    validate_numeric_array(param1)
    
    # Perform calculation
    result <- your_calculation(param1, param2)
    
    # Return success response
    return(list(
      success = TRUE,
      result = result
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
}
```

### Testing

```bash
# Test locally
docker build -t r-api-test .
docker run -p 8000:8000 r-api-test

# Test endpoint
curl -X POST http://localhost:8000/your-endpoint \
  -H "Content-Type: application/json" \
  -d '{"param": [1,2,3]}'
```

### Code Style

- Follow R style guide
- Use meaningful variable names
- Add comments for complex logic
- Document all parameters
- Return consistent response format

## Areas to Contribute

1. **New Endpoints**
   - Machine learning algorithms
   - Advanced statistical tests
   - Additional trading indicators
   - Data visualization endpoints

2. **Documentation**
   - API usage examples
   - Tutorial guides
   - Video walkthroughs

3. **Performance**
   - Caching strategies
   - Optimization
   - Parallel processing

4. **Testing**
   - Unit tests
   - Integration tests
   - Load testing

## License

By contributing, you agree that your contributions will be licensed under the MIT License.