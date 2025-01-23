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




InputCollect <- robyn_inputs(
  dt_input = df,
  dt_holidays = dt_prophet_holidays,
  date_var = "date",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  #prophet_country = "de", # input one country. dt_prophet_holidays includes 59 countries by default


  context_vars = c("uploads_private", "uploads_commercial", "crossborder_sales", "n_distinct_searches", "app_installs", "android_installs", "apple_installs", "uploads_total", "cum_private_uploads14day", "cum_commercial_uploads14day", "avg_buycycle_fee", "discount_amt", "n_searches", "tv_is_on"),
  paid_media_spends = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "google_ads_dg"),
  paid_media_vars = c("ga_brand_search_spend", "ga_demand_search_spend", "ga_demand_pmax_spend", "ga_demand_shopping_spend", "ga_supply_search_spend", "meta_brand_spend", "meta_supply_spend", "meta_demand_spend", "tv_spent_eur", "google_ads_dg"),

  organic_vars = c(),
  factor_vars = c("tv_is_on"), # force variables in context_vars or organic_vars to be categorical
  adstock = "weibull_pdf" # geometric, weibull_cdf or weibull_pdf.
)

hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

hyperparameters <- list(
  #App_Installs_alphas = c(0.5, 3),
  #App_Installs_gammas = c(0.3, 1),
  #App_Installs_thetas = c(0.3, 0.8),
  #backlinks_alphas = c(0.5, 3),
  #backlinks_gammas= c(0.3, 1),
  #backlinks_thetas= c(0, 0.3),
  #biketest_referral_alphas = c(0.5, 3),
  #biketest_referral_gammas= c(0.3, 1),
  #biketest_referral_thetas= c(0, 0.3),
  #bing_alphas= c(0.5, 3),
  #bing_gammas= c(0.3, 1),
  #bing_thetas= c(0, 0.3),
  #ecosia.org_referral_alphas= c(0.5, 3),
  #ecosia.org_referral_gammas= c(0.3, 1),
  #ecosia.org_referral_thetas= c(0, 0.3),
  #eurosport_traffic_alphas= c(0.5, 3),
  #eurosport_traffic_gammas= c(0.3, 1),
  #eurosport_traffic_thetas= c(0, 0.3),
  google_ads_brand_spend_alphas= c(0.5, 3),
  google_ads_brand_spend_gammas= c(0.3, 1),
  #google_ads_brand_spend_thetas= c(0, 0.9),
  google_ads_brand_spend_shapes = c(0.0001, 10),
  google_ads_brand_spend_scales = c(0, 0.1),

  google_ads_demandsearch_spend_alphas= c(0.5, 3),
  google_ads_demandsearch_spend_gammas= c(0.3, 1),
  google_ads_demandsearch_spend_shapes = c(0.0001, 10),
  google_ads_demandsearch_spend_scales = c(0, 0.1),

  google_ads_demandpmax_spend_alphas= c(0.5, 3),
  google_ads_demandpmax_spend_gammas= c(0.3, 1),
  google_ads_demandpmax_spend_shapes = c(0.0001, 10),
  google_ads_demandpmax_spend_scales = c(0, 0.1),

  google_ads_demandshoppingproduct_spend_alphas= c(0.5, 3),
  google_ads_demandshoppingproduct_spend_gammas= c(0.3, 1),
  google_ads_demandshoppingproduct_spend_shapes = c(0.0001, 10),
  google_ads_demandshoppingproduct_spend_scales = c(0, 0.1),

  #google_ads_demand_spend_thetas= c(0, 0.9),
  google_ads_supplysearch_spend_alphas= c(0.5, 3),
  google_ads_supplysearch_spend_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_supplysearch_spend_shapes = c(0.0001, 10),
  google_ads_supplysearch_spend_scales = c(0, 0.1),

  google_ads_supplypmax_spend_alphas= c(0.5, 3),
  google_ads_supplypmax_spend_gammas= c(0.3, 1),
  google_ads_supplypmax_spend_shapes = c(0.0001, 10),
  google_ads_supplypmax_spend_scales = c(0, 0.1),

  #google_ads_supplypmaxCAL_spend_alphas= c(0.5, 3),
  #google_ads_supplypmaxCAL_spend_gammas= c(0.3, 1),
  #google_ads_supplypmaxCAL_spend_shapes = c(0.0001, 10),
  #google_ads_supplypmaxCAL_spend_scales = c(0, 0.1),

  #linkinbio_referral_alphas= c(0.5, 3),
  #linkinbio_referral_gammas= c(0.3, 1),
  #linkinbio_referral_thetas= c(0.1, 0.4),
  meta_ads_brand_spend_alphas= c(0.5, 3),
  meta_ads_brand_spend_gammas= c(0.3, 1),
  meta_ads_brand_spend_shapes = c(0.0001, 10),
  meta_ads_brand_spend_scales = c(0, 0.1),

  meta_ads_supply_spend_alphas= c(0.5, 3),
  meta_ads_supply_spend_gammas= c(0.3, 1),
  meta_ads_supply_spend_shapes = c(0.0001, 10),
  meta_ads_supply_spend_scales = c(0, 0.1),

  meta_ads_demand_spend_alphas= c(0.5, 3),
  meta_ads_demand_spend_gammas= c(0.3, 1),
  meta_ads_demand_spend_shapes = c(0.0001, 10),
  meta_ads_demand_spend_scales = c(0, 0.1),

  #meta_supply_spend_alphas= c(0.5, 3),
  #meta_supply_spend_gammas= c(0.3, 1),
  #meta_supply_spend_thetas= c(0, 0.3),
  #newsletter_alphas= c(0.5, 3),
  #newsletter_gammas= c(0.3, 1),
  #newsletter_thetas= c(0.1, 0.4),
  #ninetyninespokes_alphas= c(0.5, 3),
  #ninetyninespokes_gammas= c(0.3, 1),
  #ninetyninespokes_thetas= c(0, 0.3),
  organic_google_alphas= c(0.5, 3),
  organic_google_gammas= c(0.3, 1),
  #organic_google_thetas= c(0, 0.9),
  organic_google_shapes = c(0.0001, 10),
  organic_google_scales = c(0, 0.1),

  #bing_alphas= c(0.5, 3),
  #bing_gammas= c(0.3, 1),
  #bing_thetas= c(0, 0.9),
  #bing_shapes = c(0.0001, 10),
  #bing_scales = c(0, 0.1),

  blog_traffic_alphas= c(0.5, 3),
  blog_traffic_gammas= c(0.3, 1),
  #blog_traffic_thetas= c(0, 0.9),
  blog_traffic_shapes = c(0.0001, 10),
  blog_traffic_scales = c(0, 0.1),
  #partnerhsips_alphas= c(0.5, 3),
  #partnerhsips_gammas= c(0.3, 1),
  #partnerhsips_thetas= c(0.1, 0.4),
  referral_alphas= c(0.5, 3),
  referral_gammas= c(0.3, 1),
  #referral_thetas= c(0.1, 0.9),
  referral_shapes = c(0.0001, 10),
  referral_scales = c(0, 0.1),
  TV_Ad_spend_alphas= c(0.5, 3),
  TV_Ad_spend_gammas= c(0.3, 1),
  #referral_thetas= c(0.1, 0.9),
  TV_Ad_spend_shapes = c(0.0001, 10),
  TV_Ad_spend_scales = c(0, 0.1),
  google_ads_app_alphas= c(0.5, 3),
  google_ads_app_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_app_shapes = c(0.0001, 10),
  google_ads_app_scales = c(0, 0.1),

  google_ads_YT_prosp_alphas= c(0.5, 3),
  google_ads_YT_prosp_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_YT_prosp_shapes = c(0.0001, 10),
  google_ads_YT_prosp_scales = c(0, 0.1),

  google_ads_YT_ret_alphas= c(0.5, 3),
  google_ads_YT_ret_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_YT_ret_shapes = c(0.0001, 10),
  google_ads_YT_ret_scales = c(0, 0.1),

  google_ads_DG_brand_alphas= c(0.5, 3),
  google_ads_DG_brand_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_DG_brand_shapes = c(0.0001, 10),
  google_ads_DG_brand_scales = c(0, 0.1),

  google_ads_DG_supply_alphas= c(0.5, 3),
  google_ads_DG_supply_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_DG_supply_shapes = c(0.0001, 10),
  google_ads_DG_supply_scales = c(0, 0.1),

  google_ads_DG_demand_alphas= c(0.5, 3),
  google_ads_DG_demand_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  google_ads_DG_demand_shapes = c(0.0001, 10),
  google_ads_DG_demand_scales = c(0, 0.1),

  YT_Flobikes_alphas= c(0.5, 3),
  YT_Flobikes_gammas= c(0.3, 1),
  #google_ads_supply_spend_thetas= c(0, 0.9),
  YT_Flobikes_shapes = c(0.0001, 10),
  YT_Flobikes_scales = c(0, 0.1)
)

InputCollect <- robyn_inputs(InputCollect = InputCollect, hyperparameters = hyperparameters)


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


