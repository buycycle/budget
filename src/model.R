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

df$date = as.Date(df$date,  format = "%Y-%m-%d")
df <- df[order(df$date),]
df$date_mock <- seq.Date(from = as.Date("2024-01-01"),
                    by = "day",
                    length.out = nrow(df))



country_code <- "FR"
df_filtered <- df %>% filter(country == country_code) %>% select(-country, -management_region)

abs.Date <- function(x){x}

inputcollect <- robyn_inputs(
  dt_input = df_filtered,
  dt_holidays = dt_prophet_holidays,
  date_var = "date_mock",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  #prophet_country = "de", # input one country. dt_prophet_holidays includes 59 countries by default

  context_vars = c("uploads_private", "uploads_commercial", "crossborder_sales", "n_distinct_searches", "app_installs", "android_installs", "apple_installs", "uploads_total", "cum_private_uploads14day", "cum_commercial_uploads14day", "avg_buycycle_fee", "discount_amt", "n_searches","newsletter_daily_sessions","tv_is_on"),
  paid_media_spends = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "ga_supply_pmax_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "ga_app_spend", "youtube_spend", "google_ads_dg"),
  paid_media_vars = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "ga_supply_pmax_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "ga_app_spend", "youtube_spend", "google_ads_dg"),
  organic_vars = c("organic_google", "blog_traffic", "referral"),
  factor_vars = c("tv_is_on"), # force variables in context_vars or organic_vars to be categorical
  window_start = "2024-01-01",
  window_end = "2024-02-05",
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


