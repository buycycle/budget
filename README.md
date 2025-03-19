# Marketing Mix Modeling with Robyn
This project leverages the `Robyn` package to perform marketing mix modeling (MMM) for various countries. The model helps in understanding the impact of different marketing channels on sales and optimizes budget allocation to maximize return on investment (ROI).
## Overview
Marketing Mix Modeling (MMM) is a statistical analysis technique used to estimate the impact of various marketing tactics on sales and then forecast the impact of future sets of tactics. This project automates and optimizes MMM using Bayesian statistics and machine learning.
## Features
- **Data Fetching**: Automatically fetches and processes data for specified countries.
- **Variable Identification**: Identifies and categorizes variables into paid media spends, organic variables, and context variables.
- **Hyperparameter Optimization**: Utilizes Bayesian optimization to find the best hyperparameters for the model.
- **Scenario Analysis**: Provides various budget allocation scenarios, including max response, max response constrained, max response with budget, and target efficiency.
- **Visualization**: Generates plots to visualize model performance and predictions.
## Prerequisites
- Conda (Anaconda or Miniconda)
- Make
## Setup
The project uses a Makefile to automate the setup of a conda environment with both R and Python. Follow these steps to set up the environment:
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/buycycle/budget
   cd budget
   ```
2. **Set Up the Environment**:
   Use the Makefile to create and configure the conda environment:
   ```bash
   make setup
   ```
   This command will:
   - Create a conda environment named `budget` with the specified Python and R versions.
   - Install the required R packages listed in `requirements_R.R`.
   - Install the required Python packages listed in `requirements_py.txt`.
3. **Configuration**:
   Update the `config/config.ini` file to set parameters such as:
   - **Countries**: Specify which countries to include in the analysis.
   - **Date Ranges**: Set `validation_date_range` and `prediction_date_range` to define the periods for model validation and prediction.
   - **Budget and Targets**: Adjust `gmv_targets`, `max_budgets`, and `roas_targets` to reflect your specific goals and constraints for each country.
## Usage
1. **Run the Model**:
   Execute the R script to run the model for the specified countries:
   ```bash
   make run
   ```
2. **View Results**:
   The results, including plots and model outputs, will be saved in the `results` directory, organized by country and timestamp.
3. **Interpret Outputs**:
   - **Validation Results**: Check the `validation` folder for model validation results.
   - **Prediction Scenarios**: Explore different budget allocation scenarios in the `prediction` folder.
## Scenarios Calculated
The model calculates several scenarios to help optimize marketing spend:
- **Max Response**: Allocates budget to maximize the response (e.g., sales or conversions) without constraints. This scenario answers the question, "What is the maximum response given a total budget level?"
- **Max Response Constrained**: Similar to max response but with constraints on channel spend to ensure realistic allocations. It operates as a zero-sum game, where some channels increase while others decrease.
- **Max Response with Budget**: Allocates a specified budget to maximize response.
- **Target Efficiency**: This new scenario allows users to set ROAS (Return on Advertising Spend) or CPA (Cost Per Acquisition) targets in the budget allocation. It is particularly useful for growth advertisers who want to know "how much can I spend without budget limit until marketing hits break-even?" The scenario explores how much can be spent until a desired efficiency metric is achieved, without any upper budget limit. This scenario is designed to provide insights into the potential of budget allocation and assist in decision-making.
## Prediction Date Range and Budget Scaling
The prediction date range is used to scale the previous month's budget and other variables to set an initial budget for future predictions. This approach involves:
- **Scaling**: The budget, along with all spend and context variables from the previous month, is adjusted based on the prediction date range to estimate the budget needed for the future period. This helps in setting a realistic starting point for budget allocation in the prediction scenarios.
- **Drawbacks**:
  - **Assumptions**: This method assumes that past spending patterns and their effectiveness will continue into the future, which may not always be the case due to market changes or new marketing strategies.
  - **Static Scaling**: The scaling is static and does not account for dynamic changes in market conditions or competitive actions that could affect the effectiveness of the budget allocation.
  - **Potential Over/Underestimation**: If the previous month's budget or context variables were unusually high or low due to specific events, the scaled values might not accurately reflect typical spending needs or market conditions.
## Insights from the Robyn Budget Allocator
- **ROAS and mROAS**: The budget allocator uses ROAS (total response divided by raw spend) and mROAS (marginal response divided by marginal spend) to guide budget allocation. The focus is on maximizing the response of the "next dollar spent."
- **Saturation Curves**: The allocator visualizes saturation curves for each media channel, showing how additional spend impacts response. The curves are derived using the Hill function, which can model both C- and S-shaped saturation.
- **Convergence of mROAS**: As more freedom is given to the allocator, mROAS tends to converge to an equilibrium state across channels, indicating an optimal allocation of resources.
- **Risk of Conservative Constraints**: The allocator demonstrates the potential benefits of relaxing budget constraints, showing how wider bounds can lead to more effective optimization.
## Makefile Commands
- `make setup`: Set up both R and Python environments in a single conda environment.
- `make setup_env`: Create the conda environment with Python and R.
- `make setup_r`: Set up the R environment.
- `make setup_python`: Set up the Python environment.
- `make run`: Run the marketing mix model.
- `make clean`: Remove the conda environment.
## Troubleshooting
- Ensure that all data files are correctly formatted and available in the specified directories.
- Verify that the conda environment is correctly configured and accessible.
- Check for any error messages in the console for guidance on resolving issues.
## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue to discuss improvements or bug fixes.
## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
## Known Bugs
- **Pareto Model One-Pager**: There is a known issue where the Pareto model one-pager fails with an "opng device error." This is being investigated, and a fix will be implemented in a future update.
## Further Development
- To enhance the model's predictive accuracy and efficiency by experimenting with various hyperparameter optimization techniques.
- Write results to S3.
