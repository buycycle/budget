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
library(Robyn)
# Load the reticulate package
library(reticulate)
################################
################################################
############# START ROBYN MODEL ################
################################################
data("dt_prophet_holidays")
head(dt_prophet_holidays)
library(dplyr)
# Create a mock data frame with 10 rows
mock_length = 200
df <- tibble(
  date = seq.Date(from = as.Date("2024-01-01"), by = "days", length.out = mock_length),
  revenue = runif(mock_length, 1000, 5000),  # Random revenue values between 1000 and 5000
  trend = runif(mock_length, 0, 1),
  season = runif(mock_length, 0, 1),
  weekday = sample(0:6, mock_length, replace = TRUE),  # Random weekdays
  uploads_private = runif(mock_length, 50, 200),
  uploads_commercial = runif(mock_length, 30, 150),
  google_ads_brand_spend = runif(mock_length, 30, 150),
  organic_google = runif(mock_length, 30, 150),
)
inputcollect <- robyn_inputs(
  dt_input = df,
  dt_holidays = dt_prophet_holidays,
  date_var = "date", # date format must be "2020-01-01"
  dep_var = "revenue", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)
  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  #prophet_country = "de", # input one country. dt_prophet_holidays includes 59 countries by default
  context_vars = c("uploads_private","uploads_commercial"),
  paid_media_spends =  c("google_ads_brand_spend"),
  paid_media_vars =  c("google_ads_brand_spend"),
  # paid_media_vars must have same order as paid_media_spends. use media exposure metrics like
  # impressions, grp etc. if not applicable, use spend instead.
  organic_vars = c("organic_google"), # marketing activity without media spend
  #factor_vars = c("m_tdf"), # force variables in context_vars or organic_vars to be categorical
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
# Save the results to a file
saveRDS(OutputCollect, file = "OutputCollect.rds")
# Check the results
print(OutputCollect)
# Plot the results
robyn_plot(OutputCollect)

