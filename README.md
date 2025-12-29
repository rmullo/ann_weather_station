ANN Weather Station - Evapotranspiration Estimation
Description
Evapotranspiration (ETo) estimation system using Artificial Neural Networks (ANN) based on hourly meteorological data. The project implements an ensemble of multiple training algorithms (backprop, rprop+, rprop-, sag, slr) and combines their predictions through a secondary neural network to improve accuracy.

Objective
Calculate reference evapotranspiration (ETo) through:

Application of the Penman-Monteith equation (FAO-56) to generate reference values
Training of 5 neural networks with different algorithms
Combination of predictions through an ensemble model
Export of comparative results
Requirements
R >= 4.0.0
Required R packages:
r
  install.packages(c("dplyr", "plyr", "Metrics", "xlsx", "neuralnet"))
Folder Structure
ann_weather_station/
├── config/              # Model configurations
├── data/               
│   ├── raw/            # Raw meteorological data (dados.csv)
│   └── processed/      # Processed data (auto-generated)
├── src/
│   ├── domain/         # Business logic (ETo calculation)
│   ├── services/       # ML services (training, preprocessing)
│   ├── infrastructure/ # Data I/O (read/write)
│   └── utils/          # Utility functions (normalization)
├── output/             # Prediction results
└── main.R              # Main execution script
Input Data Format
The dados.csv file must contain:

Header (lines 1-10): Station metadata (latitude, longitude, altitude)
Hourly data (line 11+):
Measurement date and time
Precipitation, atmospheric pressure, solar radiation
Temperatures (dry bulb, dew point, maximum/minimum)
Relative humidity
Wind speed and direction
Note: Column names in the CSV should be in Portuguese (e.g., precipitacao, temperatura_bulbo_seco, umidade_relativa).

How to Run
Prepare the data:
Place the dados.csv file in the data/raw/ folder
Run the complete pipeline:
r
   source("main.R")
Results:
Excel file generated in output/ containing:
Actual ETo values
Predictions from 5 individual models
Combined model prediction
Algorithms Used
Algorithm	Description
backprop	Classic backpropagation
rprop+	Resilient propagation (positive version)
rprop-	Resilient propagation (negative version)
sag	Stochastic average gradient
slr	Stepwise learning rate
Neural Network Architecture
Hidden layers: [8, 5] neurons
Activation function: Logistic (sigmoid)
Learning rate: 0.001
Convergence threshold: 0.05
Maximum iterations: 10,000
Input Variables (Portuguese column names)
precipitacao - Total hourly precipitation (mm)
pressao_atmosferica - Atmospheric pressure (mB)
radiacao - Global radiation (kJ/m²)
temperatura_bulbo_seco - Dry bulb temperature (°C)
temperatura_ponto_de_orvalho - Dew point temperature (°C)
temperatura_maxima - Maximum temperature (°C)
temperatura_minima - Minimum temperature (°C)
umidade_relativa - Relative humidity (%)
vento_velocidade - Wind speed (m/s)
Methodology
Reference calculation: Penman-Monteith FAO-56 (hourly data)
Preprocessing: Min-max normalization of all variables
Data split: 80% training, 20% testing (random shuffle)
Parallel training: 5 independent neural networks
Ensemble: Neural network combining the 5 predictions
Evaluation: Comparison with reference values
Project Structure
.
├── config/
│   └── model_config.R              # Model hyperparameters and configuration
├── src/
│   ├── domain/
│   │   └── evapotranspiration_calculator.R  # Penman-Monteith implementation
│   ├── services/
│   │   ├── data_preprocessor.R     # Data preparation and normalization
│   │   └── neural_network_trainer.R # Model training and prediction
│   ├── infrastructure/
│   │   ├── data_loader.R           # CSV reading and parsing
│   │   └── file_exporter.R         # Results export
│   └── utils/
│       └── normalization.R         # Min-max scaling utilities
├── main.R                          # Main execution pipeline
├── diagnose_csv.R                  # CSV diagnostic tool
└── penman_hourly.R               # Legacy Penman-Monteith function
License
GNU General Public License v3.0 - See the LICENSE file for details.

Contributing
Contributions are welcome! Please:

Fork the project
Create a branch for your feature (git checkout -b feature/MyFeature)
Commit your changes (git commit -m 'Add MyFeature')
Push to the branch (git push origin feature/MyFeature)
Open a Pull Request
References
Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop evapotranspiration - Guidelines for computing crop water requirements. FAO Irrigation and drainage paper 56. Rome: FAO.
