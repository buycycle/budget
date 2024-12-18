ENV_NAME = budget
PYTHON_VERSION = 3.9
R_VERSION = 4.2.0  # Specify the R version you want to use
# Default target
setup: setup_env setup_r setup_python
# Set up conda environment with Python and R
setup_env:
	@echo "Creating conda environment with Python and R..."
	@conda create --name $(ENV_NAME) python=$(PYTHON_VERSION) r-base=$(R_VERSION) -y
# Set up R environment
setup_r:
	@echo "Setting up R environment..."
	@conda run -n $(ENV_NAME) Rscript requirements_R
# Set up Python environment
setup_python:
	@echo "Setting up Python environment..."
	@conda run -n $(ENV_NAME) pip install -r requirements_py.txt
# Clean environments
clean:
	@echo "Cleaning up environments..."
	@conda remove --name $(ENV_NAME) --all -y
# Help
help:
	@echo "Makefile for setting up a conda environment with both R and Python for Robyn MMM"
	@echo "Usage:"
	@echo "  make setup        - Set up both R and Python environments in a single conda environment"
	@echo "  make setup_env    - Create the conda environment with Python and R"
	@echo "  make setup_r      - Set up R environment"
	@echo "  make setup_python - Set up Python environment"
	@echo "  make clean        - Clean up environments"
	@echo "  make help         - Display this help message"

