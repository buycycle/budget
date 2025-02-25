
# Predict future values
PredictedData <- predict_data(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = prediction_date_range,
  monthly_targets =monthly_targets
)

InputCollectPredict <- robyn_inputs(
  dt_input = PredictedData,
  dt_holidays = dt_prophet_holidays,
  date_var = "date",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  prophet_country = country, # input one country. dt_prophet_holidays includes 59 countries by default

  context_vars = context_vars,
  paid_media_spends = paid_media_spends,
  paid_media_vars = paid_media_vars,
  organic_vars = organic_vars,
  factor_vars = factor_vars,
  hyperparameters=hyperparameters,
  adstock = "weibull_pdf" # geometric, weibull_cdf or weibull_pdf.
)

hyper_names(adstock = InputCollectPredict$adstock, all_media = InputCollectPredict$all_media)

InputCollectPredict <- robyn_inputs(InputCollect = InputCollectPredict)
# Run future max_response Budget Allocator with predicted data
FutureAllocatorCollect <- robyn_allocator(
  InputCollect = InputCollectPredict,
  OutputCollect = OutputCollect,
  select_model = select_model,
  scenario = "max_response",
  channel_constr_low = 0.5,
  channel_constr_up = 1.5,
  total_budget = 150000,
  date_range = prediction_date_range,
  export = TRUE,
  dt_input = PredictedData # Use predicted data for allocation
)
