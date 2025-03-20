Sys.setenv(RETICULATE_PYTHON = "/home/ubuntu/miniconda3/envs/budget/bin/python")

library(Robyn)



library(reticulate)


source("src/data.R")
validation_date_range = c("2024-09-09", "2024-10-08")
prediction_date_range = c("2025-04-01", "2025-04-30")

countries <- list("DE",
                 "US"
                 #"IT",
                 #"ES",
                 #"FR"
)
management_regions <- c(US = "NA",
                 IT = "SEU",
                 ES= "SEU",
                 FR= "FRA",
                 DE= "DACH")

# for prediction time frame, used to scale previous month for prediciton time frame 
gmv_targets <- c(US = 2000000,
                 IT = 800000,
                 ES= 600000,
                 FR= 1200000,
                 DE= 5000000)
# for max response scenario constraints
channel_constr_low<- 0.2
channel_constr_up <- 2

# max budget for spend, for max_response_budget
max_budgets  <- c(US = 200000,
                 IT = 0,
                 ES= 0,
                 FR= 0,
                 DE= 300000)

# roas target, for efficiency scenario 
roas_targets <- c(US = 1,
                 IT = 0,
                 ES= 0,
                 FR= 0,
                 DE= 3)
# add bike race to dt_prophet_holidays, for all countries?
events <- read.csv("input/cycling_events.csv")

# add france holidays to dt_prophet_holidays
data("dt_prophet_holidays", package = "Robyn")
fr_holidays <- read.csv("input/fr_holidays.csv")
fr_holidays$ds <- as.Date(fr_holidays$ds)
dt_prophet_holidays <- rbind(dt_prophet_holidays, fr_holidays)

# Loop over the countries and map the GMV target
for (country in countries) {

    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")  # Format: YYYYMMDD_HHMMSS
    output_folder <- paste0("results/", country, "_", timestamp, "/")
    if (!dir.exists(output_folder)) {
      dir.create(output_folder, recursive = TRUE)
      dir.create(paste0(output_folder,"validation/pareto/"), recursive = TRUE)
      dir.create(paste0(output_folder,"validation/model/"), recursive = TRUE)
      dir.create(paste0(output_folder,"prediction/max_response/"), recursive = TRUE)
      dir.create(paste0(output_folder,"prediction/max_response_constrained/"), recursive = TRUE)
      dir.create(paste0(output_folder,"prediction/max_response_budget/"), recursive = TRUE)
      dir.create(paste0(output_folder,"prediction/efficiency/"), recursive = TRUE)
    }

  # Assigne country specific values
  management_region <- management_regions[[country]]
  gmv_target <- gmv_targets[[country]]
  max_budget <- max_budgets[[country]]
  roas_target <- roas_targets[[country]]
  # Construct the command to call the Python script
  fetch_data <- sprintf("python src/data.py %s %s %s", country, management_region, output_folder)
  # Execute the command
  system(fetch_data)
  # read csv snowflake export
  data_path <- paste0(output_folder, "/data.csv")
  df <- read.csv(data_path)
  print("Columns in df:")
  print(names(df))
  # If no data returned, skip to the next country
  if (nrow(df) == 0) {
      print(paste("Data frame is empty for", country, ". Skipping this country."))
      next
  }
  df <- fill_missing_days(df)

  # Programmatically define variable types
  # 1. Get the column names for potential independent vars
  column_names <- names(df)
  independent_columns <- setdiff(column_names, c("date", "gmv", "national_gmv", "crossborder_gmv", "management_region", "country"))
  # 2. Identify columns with no variance
  no_variance_cols <- independent_columns[sapply(df[independent_columns], function(x) length(unique(x)) == 1)]
  print(paste("Columns with no variance:", paste(no_variance_cols, collapse = ", ")))
  independent_columns <- setdiff(independent_columns, no_variance_cols) # Remove columns with no variance
  # 3. Define variables based on column names
  paid_media_spends <- independent_columns[grepl("_cost$", independent_columns)]
  paid_media_vars <- paid_media_spends
  print(paste("paid_media_vars:", paste(paid_media_vars, collapse = ", ")))
  organic_vars <- independent_columns[grepl("_sessions$", independent_columns)]
  print(paste("organic_vars:", paste(organic_vars, collapse = ", ")))
  context_vars <- setdiff(independent_columns, c(paid_media_spends, organic_vars))
  print(paste("context_vars:", paste(context_vars, collapse = ", ")))
  factor_vars <- intersect(c("tv_is_on"), independent_columns) # Ensure tv_is_on is still available
  print(paste("factor_vars:", paste(factor_vars, collapse = ", ")))
  # Define parameter ranges and fits
  alpha_range <- c(0.5, 3)
  gamma_range <- c(0.3, 1)
  # Assign hyperparameters with custom prefixes
  hyperparameters <- assign_hyperparameters(
    paid_media_spends,
    organic_vars,
    alpha_range,
    gamma_range,
    prefix_media = c("ga_", "google_", "meta_", "bing_"),
    prefix_tv = "tv_"
  )
  hyperparameters[["train_size"]] <- c(0.8, 0.9)
  # Print the assigned hyperparameters for debugging
  print("Assigned hyperparameters:")
  for (name in names(hyperparameters)) {
    print(paste(name, ":", paste(hyperparameters[[name]], collapse = ", ")))
  }

  if (country == "FR") {
    dt_holidays <- fr_holidays
  } else {
    dt_holidays <- dt_prophet_holidays
  }

   # replace country for cycling events
  events$country <- country
  dt_holidays <- rbind(dt_holidays, events)

  InputCollect <- robyn_inputs(
    dt_input = df,
    dt_holidays = dt_holidays,
    date_var = "date",
    dep_var = "gmv", # there should be only one dependent variable
    dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)
    prophet_vars = c("trend","season", "weekday", "holiday"),
    prophet_country = country,
    context_vars = context_vars,
    paid_media_spends = paid_media_spends,
    paid_media_vars = paid_media_vars,
    organic_vars = organic_vars,
    factor_vars = factor_vars,
    hyperparameters=hyperparameters,
    adstock = "geometric" # geometric, weibull_cdf or weibull_pdf.
  )
  hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)
  InputCollect <- robyn_inputs(InputCollect = InputCollect)
  OutputModel <- robyn_run(
    InputCollect = InputCollect,
    cores = 8, # Number of CPU cores to use
    iterations = 2000, # Number of iterations for the model
    trials = 5, # Number of trials for hyperparameter optimization, should be >= 5
    ts_validation = TRUE
  )
  OutputCollect <- robyn_outputs(
    InputCollect, OutputModel,
    # pareto_fronts = "auto",
    clusters = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
    plot_pareto = FALSE, # Set to FALSE to deactivate plotting and saving model one-pagers
    export = FALSE # this will create files locally
  )
  robyn_plots(
  InputCollect,
  OutputCollect,
  export = TRUE,
  plot_folder = paste0(output_folder, "validation/pareto/")
)
  # does not work
#robyn_onepagers(
#  InputCollect,
#  OutputCollect,
#  quiet = FALSE,
#  export = TRUE,
#  plot_folder = paste0(output_folder, "validation/pareto/")
#)

  # Automatically select the model with the best combined score
  pareto_models <- OutputCollect$allSolutions
  metrics <- OutputCollect$resultHypParam[OutputCollect$resultHypParam$solID %in% pareto_models, ]
  # Calculate combined score (lower is better)
  metrics$score <- sqrt(metrics$nrmse^2 + metrics$decomp.rssd^2)
  # Select the best model
  best_model <- metrics$solID[which.min(metrics$score)]
  select_model <- best_model
  # For safety, you might want to add:
  if(length(select_model) == 0) {
    stop("No valid model selected. Check model selection logic.")
  }
  print(paste("Automatically selected model:", select_model))
  #### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
  #ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model)
  # Run historic max_response Budget Allocator.
  HistoricAllocatorCollect <- robyn_allocator(
    InputCollect = InputCollect,
    OutputCollect = OutputCollect,
    select_model = select_model,
    date_range = validation_date_range,
    total_budget = NULL, # When NULL, use total spend of date_range
    channel_constr_low = 0.5,
    channel_constr_up = 1.5,
    channel_constr_multiplier = 3,
    scenario = "max_historical_response",
    export = TRUE,
    plot_folder = paste0(output_folder, "validation/model/")
  )
  # Predict future values
  PredictedData <- get_future_data(
    historical_df = df,
    prediction_date_range = prediction_date_range,
    folder = output_folder,
    target_gmv = gmv_target
  )
  print("future data is created")
  InputCollectPredict <- robyn_inputs(
    dt_input = PredictedData,
    dt_holidays = dt_holidays,
    date_var = "date",
    dep_var = "gmv", # there should be only one dependent variable
    dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)
    prophet_vars = c("trend","season", "weekday", "holiday"),
    prophet_country = country,
    context_vars = context_vars,
    paid_media_spends = paid_media_spends,
    paid_media_vars = paid_media_vars,
    organic_vars = organic_vars,
    factor_vars = factor_vars,
    hyperparameters=hyperparameters,
    adstock = "geometric" # geometric, weibull_cdf or weibull_pdf.
  )
  hyper_names(adstock = InputCollectPredict$adstock, all_media = InputCollectPredict$all_media)
  InputCollectPredict <- robyn_inputs(InputCollect = InputCollectPredict)
  # Run future max_response Budget Allocator with predicted data
  FutureAllocatorCollect <- robyn_allocator(
    InputCollect = InputCollectPredict,
    OutputCollect = OutputCollect,
    select_model = select_model,
    scenario = "max_response",
    total_budget = NULL,
    date_range = prediction_date_range,
    export = TRUE,
    dt_input = PredictedData, # Use predicted data for allocation
    plot_folder = paste0(output_folder, "prediction/max_response/")
  )
  # Save prediction results
  #saveRDS(FutureAllocatorCollect, file = file.path(prediction_folder, "FutureAllocatorCollect.rds"))
  print(paste("Max response scenario prediction for the country ", country, "is done."))
  FutureAllocatorCollect <- robyn_allocator(
    InputCollect = InputCollectPredict,
    OutputCollect = OutputCollect,
    select_model = select_model,
    scenario = "max_response",
    channel_constr_low = channel_constr_low,
    channel_constr_up = channel_constr_up,
    total_budget = NULL,
    date_range = prediction_date_range,
    export = TRUE,
    dt_input = PredictedData, # Use predicted data for allocation
    plot_folder = paste0(output_folder, "prediction/max_response_constrained/")
  )
  print(paste("Max response constrained scenario prediction for the country ", country, "is done."))
  FutureAllocatorCollect <- robyn_allocator(
    InputCollect = InputCollectPredict,
    OutputCollect = OutputCollect,
    select_model = select_model,
    scenario = "max_response",
    total_budget = max_budget,
    date_range = prediction_date_range,
    export = TRUE,
    dt_input = PredictedData, # Use predicted data for allocation
    plot_folder = paste0(output_folder, "prediction/max_response_budget/")
  )
  print(paste("Max response budget scenario prediction for the country ", country, "is done."))
  FutureAllocatorCollect <- robyn_allocator(
    InputCollect = InputCollectPredict,
    OutputCollect = OutputCollect,
    select_model = select_model,
    scenario = "target_efficiency",
    target_value = roas_target, # Customize target ROAS or CPA value
    total_budget = NULL,
    date_range = prediction_date_range,
    export = TRUE,
    dt_input = PredictedData, # Use predicted data for allocation
    plot_folder = paste0(output_folder, "prediction/efficiency/")
  )
  print(paste("Efficiency scenario prediction for the country ", country, "is done."))
}
