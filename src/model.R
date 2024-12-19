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
library(RobynLearn)



# Load the reticulate package
library(reticulate)


################################

#France Data Frame
##last data frame used: MMM_robyn

################################################
############# START ROBYN MODEL ################
################################################

data("dt_prophet_holidays")
head(dt_prophet_holidays)

robyn_object <- "/Users/konstantinsorger/Desktop/MMM/Buycycle/US"

InputCollect <- robyn_inputs(
  dt_input = df,
  dt_holidays = dt_prophet_holidays,

  date_var = "DATE", # date format must be "2020-01-01"
  dep_var = "revenue", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (ROI) or "conversion" (CPA)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  #prophet_country = "DE", # input one country. dt_prophet_holidays includes 59 countries by default

  context_vars = c("Uploads_private","Uploads_commercial","cross_boarder_rev_p","brand_search_volume", "App_installs"), # e.g. competitors, discount, unemployment etc

  paid_media_spends =  c("google_ads_brand_spend","google_ads_demandsearch_spend","google_ads_demandpmax_spend","google_ads_demandshoppingproduct_spend","google_ads_supplysearch_spend","google_ads_supplypmax_spend", "meta_ads_brand_spend", "meta_ads_supply_spend","meta_ads_demand_spend", "TV_Ad_spend", "google_ads_app","google_ads_YT_prosp",	"google_ads_YT_ret","google_ads_DG_brand",	"google_ads_DG_supply",	"google_ads_DG_demand", "YT_Flobikes"), # mandatory input
  paid_media_vars =  c("google_ads_brand_spend","google_ads_demandsearch_spend","google_ads_demandpmax_spend","google_ads_demandshoppingproduct_spend","google_ads_supplysearch_spend","google_ads_supplypmax_spend","meta_ads_brand_spend", "meta_ads_supply_spend","meta_ads_demand_spend","TV_Ad_spend","google_ads_app","google_ads_YT_prosp",	"google_ads_YT_ret","google_ads_DG_brand",	"google_ads_DG_supply",	"google_ads_DG_demand","YT_Flobikes"), # mandatory.
  # paid_media_vars must have same order as paid_media_spends. Use media exposure metrics like
  # impressions, GRP etc. If not applicable, use spend instead.
  organic_vars = c("organic_google","blog_traffic","referral"), # marketing activity without media spend
  #factor_vars = c("m_tdf"), # force variables in context_vars or organic_vars to be categorical
  window_start = "2024-01-01",
  window_end = "2024-10-05",
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

OutputModels <- robyn_run(
  InputCollect = InputCollect, # feed in all model specification
  # cores = 4, # default to max available
  # add_penalty_factor = FALSE, # Untested feature. Use with caution.
  ts_validation = FALSE,
  iterations = 3000, # 2000 recommended for the dummy dataset with no calibration
  trials = 5, # 5 recommended for the dummy dataset
  outputs = FALSE # outputs = FALSE disables direct model output - robyn_outputs()
)

  OutputCollect <- robyn_outputs(
    InputCollect, OutputModels,
    # pareto_fronts = "auto",
    # calibration_constraint = 0.1, # range c(0.01, 0.1) & default at 0.1
    csv_out = "pareto", # "pareto", "all", or NULL (for none)
    clusters = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
    plot_pareto = TRUE, # Set to FALSE to deactivate plotting and saving model one-pagers
    plot_folder = robyn_object, # path for plots export
    export = TRUE # this will create files locally
  )
print(OutputModels)


select_model <- "5_358_5" # Pick one of the models from OutputCollect to proceed

#### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model)
print(ExportedModel)

AllocatorCollect1 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_min = "2023-10-20",
  date_max = "2023-11-19",
  #date_range = 30, # When NULL, will set last month (30 days, 4 weeks, or 1 month)
  total_budget = NULL, # When NULL, use total spend of date_range
  channel_constr_low = c(0.3, 0.3, 0.3, 0.3, 0.3, 0.3),
  channel_constr_up = c(1.1, 2, 2, 2, 2, 2),
  channel_constr_multiplier = 3,
  scenario = "max_historical_response",
  export = TRUE
)

#run historic max_response Budget Allocator.
AllocatorCollect1 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  scenario = "max_historical_response",
  #paid_media_spends = c("TV",	"Influencer",	"BTL" ,	"OOH", "FB_OLV_s", "Google_OLV_s", "FB_acq_s", "Google_acq_s", "TikTok_s", "Strike", "Voucher_acq")
  channel_constr_low = 0.5,
  channel_constr_up = 1.5,
  export = TRUE,
  date_min = "2024-04-27",
  date_max = "2024-05-26"
)

print(AllocatorCollect1)

AllocatorCollect2 <- robyn_allocator(
  InputCollect = InputCollectX,
  OutputCollect = OutputCollectX,
  select_model = select_modelX,
  scenario = "max_response",
  channel_constr_low = 0.5,
  channel_constr_up = 1.5,
  total_budget = 150000, # Total spend to be simulated
  date_range = c("2024-09-09", "2024-10-08"), # Last 10 periods, same as c("2018-10-22", "2018-12-31")
  export = TRUE
)

## QA optimal response
# Pick any media variable: InputCollect$all_media
select_media <- "google_ads_DG"
# For paid_media_spends set metric_value as your optimal spend
metric_value <- AllocatorCollect2$dt_optimOut$optmSpendUnit[
  AllocatorCollect2$dt_optimOut$channels == select_media
]; metric_value
]; metric_value

json_file <- "/Users/konstantinsorger/Desktop/MMM/Buycycle/US/Robyn_202410011359_init/RobynModel-2_425_1.json"

RobynRefresh <- robyn_refresh(
  json_file = json_file,
  dt_input = df,
  dt_holidays = dt_prophet_holidays,
  refresh_steps = 10,
  refresh_iters = 1000, # 1k is an estimation
  refresh_trials = 1
)

InputCollectX <- RobynRefresh$listRefresh1$InputCollect
OutputCollectX <- RobynRefresh$listRefresh1$OutputCollect
select_modelX <- RobynRefresh$listRefresh1$OutputCollect$selectID
