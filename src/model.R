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

library(dplyr)

# read csv snowflake export
data_path <- "data/data.csv"
df <- read.csv(data_path)

country_code <- "FR"
df_filtered <- df %>% filter(country == country_code)

# Determine the minimum and maximum dates
window_start <- min(df_filtered$date, na.rm = TRUE)
window_end <- max(df_filtered$date, na.rm = TRUE)


inputcollect <- robyn_inputs(
  dt_input = df_filtered,
  dt_holidays = dt_prophet_holidays,

  date_var = "date", # date format must be "2020-01-01"
  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  #prophet_country = "de", # input one country. dt_prophet_holidays includes 59 countries by default

  context_vars = c("uploads_private", "uploads_commercial", "crossborder_sales", "n_distinct_searches", "app_installs", "android_installs", "apple_installs", "uploads_total", "cum_private_uploads14day", "cum_commercial_uploads14day", "avg_buycycle_fee", "discount_amt", "n_searches","newsletter_daily_sessions"),
  paid_media_spends = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "ga_supply_pmax_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "ga_app_spend", "youtube_spend", "google_ads_dg"),
  paid_media_vars = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "ga_supply_pmax_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "ga_app_spend", "youtube_spend", "google_ads_dg"),
  organic_vars = c("organic_google", "blog_traffic", "referral")
  #factor_vars = c("m_tdf"), # force variables in context_vars or organic_vars to be categorical
  window_start = window_start,
  window_end = window_end,
  adstock = "weibull_pdf" # geometric, weibull_cdf or weibull_pdf.
)
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


