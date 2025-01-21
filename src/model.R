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

# read csv snowflake export
data_path <- "data/data.csv"
df <- read.csv(data_path)

df <- fill_missing_days(df)




inputcollect <- robyn_inputs(
  dt_input = df,
  dt_holidays = dt_prophet_holidays, 
  date_var = "date",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend", "season", "weekday", "holiday"),  #"trend","season", "weekday" & "holiday"
  prophet_country = "DE", # input one country. dt_prophet_holidays includes 59 countries by default

  # context_vars are external or contextual variables that might affect your dependent variable but are not part of the media spends.
  context_vars = c("uploads_total", "uploads_private", "uploads_commercial", "cum_private_uploads14day", "cum_commercial_uploads14day", "crossborder_sales", "n_searches", "n_distinct_searches", "app_installs", "android_installs", "apple_installs", "avg_buycycle_fee", "discount_amt", "tv_is_on"),

  paid_media_spends = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "ga_supply_pmax_spend", "ga_app_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "youtube_spend", "tv_spent_eur"),
  # ??? "google_ads_dg", "referal"cost?or not??? 

  # media exposure metrics like Facebook impressions, search clicks. If you have these metrics, Robyn will use them instead of spend for modeling.
  paid_media_vars = c(),

  # marketing activities, which are not tied to any paid media spend, like newsletters.
  organic_vars = c("newletter_daily_sessions", "blog_traffic"),
  # ??? "organic_google"

  # window_start = "",
  # window_end = "",

  factor_vars = c("tv_is_on"), # force variables in context_vars or organic_vars to be categorical

  adstock = "weibull_pdf" # geometric, weibull_cdf or weibull_pdf.
)

hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

hyperparameters <- list(
  # Paid Media Variables
  ga_brand_search_spend_alphas = c(1.5, 3)
  ga_brand_search_spend_gammas = c(0.7, 1)
  ga_brand_search_spend_shapes = c(1, 3)
  ga_brand_search_spend_scales = c(0.1, 0.3)

  ga_demand_search_spend_alphas = c(1.3, 2.5)
  ga_demand_search_spend_gammas = c(0.6, 0.9)
  ga_demand_search_spend_shapes = c(1, 3)
  ga_demand_search_spend_scales = c(0.2, 0.4)

  ga_demand_pmax_spend_alphas = c(1, 2)
  ga_demand_pmax_spend_gammas = c(0.5, 0.8)
  ga_demand_pmax_spend_shapes = c(2, 4)
  ga_demand_pmax_spend_scales = c(0.3, 0.5)

  ga_demand_shopping_spend_alphas = c(1, 2)
  ga_demand_shopping_spend_gammas = c(0.5, 0.8)
  ga_demand_shopping_spend_shapes = c(2, 4)
  ga_demand_shopping_spend_scales = c(0.2, 0.5)

  ga_supply_search_spend_alphas = c(1.2, 2)
  ga_supply_search_spend_gammas = c(0.6, 0.9)
  ga_supply_search_spend_shapes = c(1, 3)
  ga_supply_search_spend_scales = c(0.2, 0.4)

  ga_supply_pmax_spend_alphas = c(1, 1.8)
  ga_supply_pmax_spend_gammas = c(0.5, 0.8)
  ga_supply_pmax_spend_shapes = c(2, 4)
  ga_supply_pmax_spend_scales = c(0.3, 0.5)

  ga_app_spend_alphas = c(1.8, 2.5)
  ga_app_spend_gammas = c(0.8, 1)
  ga_app_spend_shapes = c(1, 2)
  ga_app_spend_scales = c(0.1, 0.3)

  meta_brand_spend_alphas = c(1.5, 2.5)
  meta_brand_spend_gammas = c(0.7, 0.9)
  meta_brand_spend_shapes = c(1, 3)
  meta_brand_spend_scales = c(0.2, 0.4)

  meta_supply_spend_alphas = c(1.3, 2)
  meta_supply_spend_gammas = c(0.6, 0.8)
  meta_supply_spend_shapes = c(2, 4)
  meta_supply_spend_scales = c(0.2, 0.5)

  meta_demand_spend_alphas = c(1, 2)
  meta_demand_spend_gammas = c(0.5, 0.7)
  meta_demand_spend_shapes = c(2, 4)
  meta_demand_spend_scales = c(0.3, 0.6)

  youtube_spend_alphas = c(0.8, 1.5)
  youtube_spend_gammas = c(0.4, 0.6)
  youtube_spend_shapes = c(2, 5)
  youtube_spend_scales = c(0.4, 0.8)

  tv_spent_eur_alphas = c(0.7, 1.2)
  tv_spent_eur_gammas = c(0.4, 0.6)
  tv_spent_eur_shapes = c(2, 5)
  tv_spent_eur_scales = c(0.5, 1)

  # Organic Variables
  newletter_daily_sessions_alphas = c(0.5, 1.2)
  newletter_daily_sessions_gammas = c(0.5, 0.8)
  newletter_daily_sessions_shapes = c(3, 5)
  newletter_daily_sessions_scales = c(0.2, 0.4)

  blog_traffic_alphas = c(0.4, 1.0)
  blog_traffic_gammas = c(0.4, 0.7)
  blog_traffic_shapes = c(4, 6)
  blog_traffic_scales = c(0.2, 0.5)

  # Contextual Variables
  uploads_total_alphas = c(0.8, 1.5)
  uploads_total_gammas = c(0.7, 0.9)
  uploads_total_shapes = c(2, 4)
  uploads_total_scales = c(0.2, 0.4)

  uploads_private_alphas = c(0.8, 1.5)
  uploads_private_gammas = c(0.7, 0.9)
  uploads_private_shapes = c(2, 4)
  uploads_private_scales = c(0.2, 0.4)

  uploads_commercial_alphas = c(0.8, 1.5)
  uploads_commercial_gammas = c(0.7, 0.9)
  uploads_commercial_shapes = c(2, 4)
  uploads_commercial_scales = c(0.2, 0.4)

  cum_private_uploads14day_alphas = c(0.6, 1.2)
  cum_private_uploads14day_gammas = c(0.6, 0.8)
  cum_private_uploads14day_shapes = c(3, 5)
  cum_private_uploads14day_scales = c(0.2, 0.5)

  cum_commercial_uploads14day_alphas = c(0.6, 1.2)
  cum_commercial_uploads14day_gammas = c(0.6, 0.8)
  cum_commercial_uploads14day_shapes = c(3, 5)
  cum_commercial_uploads14day_scales = c(0.2, 0.5)

  crossborder_sales_alphas = c(0.5, 1)
  crossborder_sales_gammas = c(0.4, 0.6)
  crossborder_sales_shapes = c(4, 6)
  crossborder_sales_scales = c(0.3, 0.6)

  n_searches_alphas = c(0.6, 1.2)
  n_searches_gammas = c(0.5, 0.7)
  n_searches_shapes = c(3, 5)
  n_searches_scales = c(0.2, 0.4)

  n_distinct_searches_alphas = c(0.6, 1.2)
  n_distinct_searches_gammas = c(0.5, 0.7)
  n_distinct_searches_shapes = c(3, 5)
  n_distinct_searches_scales = c(0.2, 0.4)

  app_installs_alphas = c(1, 2)
  app_installs_gammas = c(0.7, 0.9)
  app_installs_shapes = c(2, 4)
  app_installs_scales = c(0.2, 0.5)

  android_installs_alphas = c(0.9, 1.8)
  android_installs_gammas = c(0.6, 0.8)
  android_installs_shapes = c(2, 4)
  android_installs_scales = c(0.2, 0.4)

  apple_installs_alphas = c(0.9, 1.8)
  apple_installs_gammas = c(0.6, 0.8)
  apple_installs_shapes = c(2, 4)
  apple_installs_scales = c(0.2, 0.4)

  avg_buycycle_fee_alphas = c(0.3, 0.8)
  avg_buycycle_fee_gammas = c(0.4, 0.6)
  avg_buycycle_fee_shapes = c(4, 6)
  avg_buycycle_fee_scales = c(0.3, 0.6)

  discount_amt_alphas = c(0.5, 1.2)
  discount_amt_gammas = c(0.5, 0.7)
  discount_amt_shapes = c(3, 5)
  discount_amt_scales = c(0.2, 0.5)
)

inputcollect <- robyn_inputs(InputCollect = inputcollect, hyperparameters = hyperparameters)


OutputCollect <- robyn_run(
  InputCollect = inputcollect,
  cores = 4, # Number of CPU cores to use
  iterations = 2000, # Number of iterations for the model
  trials = 5 # Number of trials for hyperparameter optimization
)

# Save results
saveRDS(OutputCollect, file = "data/OutputCollect.rds"
# Plot the results
robyn_plot(OutputCollect)


