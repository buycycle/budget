#https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R

#also den python pfad aufs richtige verzeichnis zu legen bevor man die packages installiert (Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/r-reticulate/bin/python")


#### Step 0: Setup environment

## Install, load, and check (latest) version.
## Install the stable version from CRAN.
# install.packages("Robyn")
## Install the dev version from GitHub
# install.packages("remotes") # Install remotes first if you haven't already
# remotes::install_github("facebookexperimental/Robyn/R")
library(Robyn)

# Load the reticulate package
library(reticulate)


################################




################################################
############# START ROBYN MODEL ################
################################################


source("src/data.R")

country <- "DE"
management_region <- "DACH"
# Construct the command to call the Python script
fetch_data <- sprintf("python src/data.py %s %s", country, management_region)
# Execute the command
system(fetch_data)

# read csv snowflake export
data_path <- "data/data.csv"
df <- read.csv(data_path)

df <- fill_missing_days(df)

hyperparameters <- list(
  ga_brand_search_spend_alphas = c(0.5, 3),
  ga_brand_search_spend_gammas = c(0.3, 1),
  ga_brand_search_spend_scales = c(0, 0.1),
  ga_brand_search_spend_shapes = c(0.0001, 10),
  ga_demand_pmax_spend_alphas = c(0.5, 3),
  ga_demand_pmax_spend_gammas = c(0.3, 1),
  ga_demand_pmax_spend_scales = c(0, 0.1),
  ga_demand_pmax_spend_shapes = c(0.0001, 10),
  ga_demand_search_spend_alphas = c(0.5, 3),
  ga_demand_search_spend_gammas = c(0.3, 1),
  ga_demand_search_spend_scales = c(0, 0.1),
  ga_demand_search_spend_shapes = c(0.0001, 10),
  ga_demand_shopping_spend_alphas = c(0.5, 3),
  ga_demand_shopping_spend_gammas = c(0.3, 1),
  ga_demand_shopping_spend_scales = c(0, 0.1),
  ga_demand_shopping_spend_shapes = c(0.0001, 10),
  ga_supply_search_spend_alphas = c(0.5, 3),
  ga_supply_search_spend_gammas = c(0.3, 1),
  ga_supply_search_spend_scales = c(0, 0.1),
  ga_supply_search_spend_shapes = c(0.0001, 10),
  google_ads_dg_alphas = c(0.5, 3),
  google_ads_dg_gammas = c(0.3, 1),
  google_ads_dg_scales = c(0, 0.1),
  google_ads_dg_shapes = c(0.0001, 10),
  meta_brand_spend_alphas = c(0.5, 3),
  meta_brand_spend_gammas = c(0.3, 1),
  meta_brand_spend_scales = c(0, 0.1),
  meta_brand_spend_shapes = c(0.0001, 10),
  meta_demand_spend_alphas = c(0.5, 3),
  meta_demand_spend_gammas = c(0.3, 1),
  meta_demand_spend_scales = c(0, 0.1),
  meta_demand_spend_shapes = c(0.0001, 10),
  meta_supply_spend_alphas = c(0.5, 3),
  meta_supply_spend_gammas = c(0.3, 1),
  meta_supply_spend_scales = c(0, 0.1),
  meta_supply_spend_shapes = c(0.0001, 10),
  tv_spent_eur_alphas = c(0.5, 3),
  tv_spent_eur_gammas = c(0.3, 1),
  tv_spent_eur_scales = c(0, 0.1),
  tv_spent_eur_shapes = c(0.0001, 10)
)



InputCollect <- robyn_inputs(
  dt_input = df,
  dt_holidays = dt_prophet_holidays,
  date_var = "date",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  prophet_country = country, # input one country. dt_prophet_holidays includes 59 countries by default


  context_vars = c("uploads_private", "uploads_commercial", "crossborder_sales", "n_distinct_searches", "app_installs", "android_installs", "apple_installs", "uploads_total", "cum_private_uploads14day", "cum_commercial_uploads14day", "avg_buycycle_fee", "discount_amt", "n_searches", "tv_is_on"),
  paid_media_spends = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "google_ads_dg"),
  paid_media_vars = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "google_ads_dg"),

  organic_vars = c(),
  factor_vars = c("tv_is_on"), # force variables in context_vars or organic_vars to be categorical
  hyperparameters=hyperparameters,
  adstock = "weibull_pdf" # geometric, weibull_cdf or weibull_pdf.
)

hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

InputCollect <- robyn_inputs(InputCollect = InputCollect)


OutputModel <- robyn_run(
  InputCollect = InputCollect,
  cores = 32, # Number of CPU cores to use
  iterations = 2000, # Number of iterations for the model
  trials = 5 # Number of trials for hyperparameter optimization
)

saveRDS(OutputModel, file = "data/OutputModel.rds")

OutputCollect <- robyn_outputs(
  InputCollect, OutputModel,
  # pareto_fronts = "auto",
  csv_out = "pareto", # "pareto", "all", or NULL (for none)
  clusters = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
  plot_pareto = TRUE, # Set to FALSE to deactivate plotting and saving model one-pagers
  plot_folder = "plot/", # path for plots export
  export = TRUE # this will create files locally
)


select_model <- "1_216_6" # Pick one of the models from OutputCollect to proceed

#### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model)

AllocatorCollect1 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = c("2024-11-01", "2024-12-01"), # Last 10 periods, same as c("2018-10-22", "2018-12-31")
  #date_range = 30, # When NULL, will set last month (30 days, 4 weeks, or 1 month)
  total_budget = NULL, # When NULL, use total spend of date_range
  channel_constr_low = 0.5,
  channel_constr_up = 1.5,
  channel_constr_multiplier = 3,
  scenario = "low 05 high 15",
  export = TRUE
)
