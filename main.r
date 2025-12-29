# ==============================================================================
# MAIN PIPELINE - ANN Weather Station
# ==============================================================================
# Main script for evapotranspiration estimation using neural networks

# Load dependencies
library(dplyr)
library(plyr)
library(Metrics)
library(xlsx)
library(neuralnet)

# Load modules
source("config/model_config.R")
source("src/infrastructure/data_loader.R")
source("src/infrastructure/file_exporter.R")
source("src/services/data_preprocessor.R")
source("src/services/neural_network_trainer.R")

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================
message("=== LOADING DATA ===")

# Load station metadata
metadata <- load_station_metadata(DATA_FILE)
message(sprintf("Station: Lat %.4f, Lon %.4f, Alt %.1fm", 
                metadata$latitude, metadata$longitude, metadata$altitude))

# Load weather data
df_raw <- load_weather_data(DATA_FILE, HEADER_SKIP_LINES)

# Fix datetime shift issue (preserves original behavior)
df_raw <- fix_datetime_shift(df_raw)

# ==============================================================================
# 2. CALCULATE REFERENCE ETO
# ==============================================================================
message("\n=== CALCULATING REFERENCE ETo (PENMAN-MONTEITH) ===")

df_with_eto <- calculate_reference_eto(df_raw, metadata)

# ==============================================================================
# 3. PREPARE DATA FOR TRAINING
# ==============================================================================
message("\n=== PREPARING DATA FOR TRAINING ===")

prepared_data <- prepare_training_data(df_with_eto, TRAIN_TEST_RATIO)
train_set <- prepared_data$train
test_set <- prepared_data$test

message(sprintf("Training data: %d records", nrow(train_set)))
message(sprintf("Test data: %d records", nrow(test_set)))

# ==============================================================================
# 4. TRAIN INDIVIDUAL MODELS
# ==============================================================================
message("\n=== TRAINING INDIVIDUAL MODELS ===")

model_config <- list(
  hidden_layers = NN_HIDDEN_LAYERS,
  learning_rate = NN_LEARNING_RATE,
  threshold = NN_THRESHOLD,
  step_max = NN_STEP_MAX,
  activation_function = NN_ACTIVATION_FUNCTION,
  error_function = NN_ERROR_FUNCTION,
  sample_size = TRAINING_SAMPLE_SIZE
)

test_with_predictions <- train_multiple_algorithms(
  train_data = train_set,
  test_data = test_set,
  algorithms = TRAINING_ALGORITHMS,
  input_features = INPUT_FEATURES,
  target_variable = TARGET_VARIABLE,
  config = model_config
)

# ==============================================================================
# 5. PREPARE DATA FOR ENSEMBLE
# ==============================================================================
message("\n=== PREPARING DATA FOR ENSEMBLE ===")

# Train the base models on training data to get predictions for ensemble training
train_features <- extract_features(train_set, INPUT_FEATURES)

train_with_predictions <- train_set
for (algorithm in TRAINING_ALGORITHMS) {
  message(paste("Generating training predictions for ensemble with:", algorithm))
  
  # Train model
  model <- train_nn_model(
    train_data = train_set,
    input_features = INPUT_FEATURES,
    target_variable = TARGET_VARIABLE,
    algorithm = algorithm,
    hidden_layers = NN_HIDDEN_LAYERS,
    learning_rate = NN_LEARNING_RATE,
    threshold = NN_THRESHOLD,
    step_max = NN_STEP_MAX,
    activation_function = NN_ACTIVATION_FUNCTION,
    error_function = NN_ERROR_FUNCTION,
    sample_size = TRAINING_SAMPLE_SIZE
  )
  
  # Predict on training set for ensemble
  predictions_normalized <- predict_nn(model, train_features)
  predictions_denormalized <- denormalize_predictions(
    predictions_normalized, 
    train_set[[TARGET_VARIABLE]]
  )
  
  train_with_predictions[, algorithm] <- predictions_denormalized
}

# Rename columns for consistency
ensemble_feature_names <- TRAINING_ALGORITHMS
ensemble_feature_names[2] <- "rprop_plus"   # rprop+
ensemble_feature_names[3] <- "rprop_minus"  # rprop-

# Select only ETo and predictions from base models
ensemble_train <- train_with_predictions[, c(TARGET_VARIABLE, TRAINING_ALGORITHMS)]
ensemble_test <- test_with_predictions[, c(TARGET_VARIABLE, TRAINING_ALGORITHMS)]

# Rename columns
colnames(ensemble_train) <- c(TARGET_VARIABLE, ensemble_feature_names)
colnames(ensemble_test) <- c(TARGET_VARIABLE, ensemble_feature_names)

# ==============================================================================
# 6. TRAIN ENSEMBLE MODEL
# ==============================================================================
ensemble_test <- train_ensemble_model(
  train_data = ensemble_train,
  test_data = ensemble_test,
  base_model_names = ensemble_feature_names,
  target_variable = TARGET_VARIABLE,
  ensemble_algorithm = ENSEMBLE_ALGORITHM,
  config = model_config
)

# ==============================================================================
# 7. EXPORT RESULTS
# ==============================================================================
message("\n=== EXPORTING RESULTS ===")

# Prepare output dataframe
output_data <- ensemble_test[, c(TARGET_VARIABLE, ensemble_feature_names, "ensemble")]

# Rename columns for clarity
colnames(output_data) <- c(
  "ETo_Actual",
  "Prediction_Backprop",
  "Prediction_RProp_Plus",
  "Prediction_RProp_Minus",
  "Prediction_SAG",
  "Prediction_SLR",
  "Prediction_Ensemble"
)

# Export to Excel
export_to_excel(output_data, OUTPUT_FILE)

message("\n=== PIPELINE COMPLETED SUCCESSFULLY ===")