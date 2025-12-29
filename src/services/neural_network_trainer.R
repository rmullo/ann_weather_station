# ==============================================================================
# NEURAL NETWORK TRAINER
# ==============================================================================
# Serviços de treinamento de redes neurais

require(neuralnet)
source("src/utils/normalization.R")

#' Train a neural network model
#'
#' @param train_data Training dataset
#' @param input_features Vector of input feature names
#' @param target_variable Name of target variable
#' @param algorithm Training algorithm name
#' @param hidden_layers Vector defining hidden layer architecture
#' @param learning_rate Learning rate
#' @param threshold Convergence threshold
#' @param step_max Maximum training iterations
#' @param activation_function Activation function name
#' @param error_function Error function name
#' @param sample_size Number of samples to use for training (NULL for all)
#' @return Trained neuralnet object
train_nn_model <- function(train_data, 
                            input_features, 
                            target_variable,
                            algorithm,
                            hidden_layers,
                            learning_rate,
                            threshold,
                            step_max,
                            activation_function,
                            error_function,
                            sample_size = NULL) {
  
  # Use subset of data if sample_size is specified
  training_subset <- if (is.null(sample_size)) {
    train_data
  } else {
    train_data[1:min(sample_size, nrow(train_data)), ]
  }
  
  # Build formula dynamically
  formula_str <- paste(target_variable, "~", paste(input_features, collapse = " + "))
  formula_obj <- as.formula(formula_str)
  
  # Train model
  model <- neuralnet::neuralnet(
    formula = formula_obj,
    data = training_subset,
    hidden = hidden_layers,
    algorithm = algorithm,
    learningrate = learning_rate,
    rep = 1,
    err.fct = error_function,
    act.fct = activation_function,
    threshold = threshold,
    stepmax = step_max,
    linear.output = TRUE
  )
  
  return(model)
}

#' Make predictions using trained model
#'
#' @param model Trained neuralnet object
#' @param test_features Test data with input features only
#' @return Vector of predictions
predict_nn <- function(model, test_features) {
  results <- neuralnet::compute(model, test_features)
  return(results$net.result)
}

#' Denormalize predictions back to original scale
#'
#' @param predictions Normalized predictions
#' @param original_target Original target variable (for scale reference)
#' @return Denormalized predictions
denormalize_predictions <- function(predictions, original_target) {
  return(denormalize_minmax(predictions, original_target))
}

#' Train multiple models with different algorithms
#'
#' @param train_data Training dataset
#' @param test_data Test dataset
#' @param algorithms Vector of algorithm names
#' @param input_features Vector of input feature names
#' @param target_variable Name of target variable
#' @param config List with model configuration parameters
#' @return Test dataset with predictions from all algorithms
train_multiple_algorithms <- function(train_data, 
                                       test_data, 
                                       algorithms,
                                       input_features,
                                       target_variable,
                                       config) {
  
  test_features <- extract_features(test_data, input_features)
  
  for (algorithm in algorithms) {
    message(paste("Treinando modelo com algoritmo:", algorithm))
    
    # Train model
    model <- train_nn_model(
      train_data = train_data,
      input_features = input_features,
      target_variable = target_variable,
      algorithm = algorithm,
      hidden_layers = config$hidden_layers,
      learning_rate = config$learning_rate,
      threshold = config$threshold,
      step_max = config$step_max,
      activation_function = config$activation_function,
      error_function = config$error_function,
      sample_size = config$sample_size
    )
    
    # Make predictions
    predictions_normalized <- predict_nn(model, test_features)
    predictions_denormalized <- denormalize_predictions(
      predictions_normalized, 
      test_data[[target_variable]]
    )
    
    # Add predictions to test dataset
    test_data[, algorithm] <- predictions_denormalized
  }
  
  return(test_data)
}

#' Train ensemble model that combines predictions from multiple models
#'
#' @param train_data Training dataset with predictions from base models
#' @param test_data Test dataset with predictions from base models
#' @param base_model_names Vector of column names for base model predictions
#' @param target_variable Name of target variable
#' @param ensemble_algorithm Algorithm for ensemble model
#' @param config List with model configuration parameters
#' @return Test dataset with ensemble predictions added
train_ensemble_model <- function(train_data,
                                  test_data,
                                  base_model_names,
                                  target_variable,
                                  ensemble_algorithm,
                                  config) {
  
  message("Treinando modelo ensemble...")
  
  # Train ensemble
  ensemble_model <- train_nn_model(
    train_data = train_data,
    input_features = base_model_names,
    target_variable = target_variable,
    algorithm = ensemble_algorithm,
    hidden_layers = config$hidden_layers,
    learning_rate = config$learning_rate,
    threshold = config$threshold,
    step_max = config$step_max,
    activation_function = config$activation_function,
    error_function = config$error_function,
    sample_size = config$sample_size
  )
  
  # Make predictions on entire test set
  test_features <- extract_features(test_data, base_model_names)
  predictions_normalized <- predict_nn(ensemble_model, test_features)
  predictions_denormalized <- denormalize_predictions(
    predictions_normalized,
    test_data[[target_variable]]
  )
  
  # Add ensemble predictions
  test_data[, "ensemble"] <- predictions_denormalized
  
  return(test_data)
}

#' Helper function to extract features (reused from preprocessor)
extract_features <- function(dataset, feature_names) {
  return(subset(dataset, select = feature_names))
}
