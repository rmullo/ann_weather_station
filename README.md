# ANN Weather Station - Evapotranspiration Estimation

## Description

Evapotranspiration (ETo) estimation system using Artificial Neural Networks (ANN) based on hourly meteorological data. The project implements an ensemble of multiple training algorithms (backprop, rprop+, rprop-, sag, slr) and combines their predictions through a secondary neural network to improve accuracy.

## Objective

Calculate reference evapotranspiration (ETo) through:
1. Application of the Penman-Monteith equation (FAO-56) to generate reference values
2. Training of 5 neural networks with different algorithms
3. Combination of predictions through an ensemble model
4. Export of comparative results

## Requirements

- R >= 4.0.0
- Required R packages:
  ```r
  install.packages(c("dplyr", "plyr", "Metrics", "xlsx", "neuralnet"))
  ```

## Folder Structure

```
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
```

## Input Data Format

The `dados.csv` file must contain:
- **Header (lines 1-10):** Station metadata (latitude, longitude, altitude)
- **Hourly data (line 11+):** 
  - Measurement date and time
  - Precipitation, atmospheric pressure, solar radiation
  - Temperatures (dry bulb, dew point, maximum/minimum)
  - Relative humidity
  - Wind speed and direction

## How to Run

1. **Prepare the data:**
   - Place the `dados.csv` file in the `data/raw/` folder

2. **Run the complete pipeline:**
   ```r
   source("main.R")
   ```

3. **Results:**
   - Excel file generated in `output/` containing:
     - Actual ETo values
     - Predictions from 5 individual models
     - Combined model prediction

## Algorithms Used

| Algorithm | Description |
|-----------|-----------|
| backprop  | Classic backpropagation |
| rprop+    | Resilient propagation (positive version) |
| rprop-    | Resilient propagation (negative version) |
| sag       | Stochastic average gradient |
| slr       | Stepwise learning rate |

## Neural Network Architecture

- **Hidden layers:** [8, 5] neurons
- **Activation function:** Logistic (sigmoid)
- **Learning rate:** 0.001
- **Convergence threshold:** 0.05
- **Maximum iterations:** 10,000

## Predictor Variables

1. Total hourly precipitation (mm)
2. Atmospheric pressure (mB)
3. Global radiation (kJ/m²)
4. Dry bulb temperature (°C)
5. Dew point temperature (°C)
6. Maximum temperature (°C)
7. Minimum temperature (°C)
8. Relative humidity (%)
9. Wind speed (m/s)

## Methodology

1. **Reference calculation:** Penman-Monteith FAO-56 (hourly data)
2. **Preprocessing:** Min-max normalization of all variables
3. **Data split:** 80% training, 20% testing (random shuffle)
4. **Parallel training:** 5 independent neural networks
5. **Ensemble:** Neural network combining the 5 predictions
6. **Evaluation:** Comparison with reference values

## License

GNU General Public License v3.0 - See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please:
1. Fork the project
2. Create a branch for your feature (`git checkout -b feature/MyFeature`)
3. Commit your changes (`git commit -m 'Add MyFeature'`)
4. Push to the branch (`git push origin feature/MyFeature`)
5. Open a Pull Request

## References

- Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). *Crop evapotranspiration - Guidelines for computing crop water requirements*. FAO Irrigation and drainage paper 56. Rome: FAO.
