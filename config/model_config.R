# ==============================================================================
# MODEL CONFIGURATION
# ==============================================================================
# Centralized configuration for neural network models

# Neural Network Architecture
NN_HIDDEN_LAYERS <- c(8, 5)
NN_LEARNING_RATE <- 0.001
NN_THRESHOLD <- 0.05
NN_STEP_MAX <- 1e+04
NN_ACTIVATION_FUNCTION <- "logistic"
NN_ERROR_FUNCTION <- "sse"
NN_REPETITIONS <- 1
NN_LINEAR_OUTPUT <- TRUE

# Training Algorithms
TRAINING_ALGORITHMS <- c("backprop", "rprop+", "rprop-", "sag", "slr")
ENSEMBLE_ALGORITHM <- "rprop-"

# Data Split
TRAIN_TEST_RATIO <- 0.8  # 80% train, 20% test
TRAINING_SAMPLE_SIZE <- 500  # Sample size for training individual models

# Input Features (Portuguese - data input names)
INPUT_FEATURES <- c(
  "precipitacao",
  "pressao_atmosferica",
  "radiacao",
  "temperatura_bulbo_seco",
  "temperatura_ponto_de_orvalho",
  "temperatura_maxima",
  "temperatura_minima",
  "umidade_relativa",
  "vento_velocidade"
)

# Target Variable
TARGET_VARIABLE <- "ETo"

# File Paths
DATA_FILE <- "data/raw/dados.csv"
OUTPUT_FILE <- "output/prediction_results.xlsx"
HEADER_SKIP_LINES <- 11