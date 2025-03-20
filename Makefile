ENV_NAME = budget
PYTHON_VERSION = 3.9
R_VERSION = 4.2.0  # Specify the R version you want to use
# Default target
setup: setup_env setup_r setup_python
# Set up conda environment with Python and R
setup_env:
	@echo "Creating conda environment with Python and R..."
	@conda create --name $(ENV_NAME) python=$(PYTHON_VERSION)
# Set up R environment
setup_r:
	@echo "Setting up R environment..."
	@conda run -n $(ENV_NAME) Rscript requirements_R.R
# Set up Python environment
setup_python:
	@echo "Setting up Python environment..."
	@conda run -n $(ENV_NAME) pip install -r requirements_py.txt
# Run the model
run:
	@echo "Running the marketing mix model..."
	@conda run -n $(ENV_NAME) Rscript src/model.R
# Clean environments
clean:
	@echo "Cleaning up environments..."
	@conda remove --name $(ENV_NAME) --all -y
