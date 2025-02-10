robyn_predict <- function(InputCollect, OutputCollect, select_model, date_range) {
  # 1. Prepare date range for future predictions
  start_date <- as.Date(date_range[1])
  end_date   <- as.Date(date_range[2])
  future_days <- seq.Date(from = start_date, to = end_date, by = "day")

  # 2. Gather historical data
  hist_data <- InputCollect$dt_input
  dep_var   <- InputCollect$dep_var
  date_var  <- InputCollect$date_var

  # For modeling (e.g., c ~ date), we’ll turn dates into numeric days for simplicity
  hist_data_numeric <- hist_data
  hist_data_numeric$.date_num <- as.numeric(hist_data_numeric[[date_var]])

  # Identify columns we want to predict (exclude date, dependent var)
  cols_to_predict <- setdiff(names(hist_data), c(date_var, dep_var))

  # 3. Build future data frame with numeric date for prediction
  future_df <- data.frame(date = future_days)
  future_df$.date_num <- as.numeric(future_days)

  # Initialize columns in future_df
  for (col_name in cols_to_predict) {
    future_df[[col_name]] <- NA
  }

  # 4. For each column, fit a minimal linear model on the historical trend, then predict
  for (col_name in cols_to_predict) {
    # If numeric, fit linear model
    if (is.numeric(hist_data[[col_name]])) {
      # Build a simple formula: col_name ~ .date_num
      form <- as.formula(paste(col_name, "~ .date_num"))

      # Some columns might be all NAs or 0’s, so handle errors
      tryCatch(
        {
          lm_fit <- lm(form, data = hist_data_numeric, na.action = na.exclude)
          # Predict for future dates
          future_df[[col_name]] <- predict(lm_fit, newdata = future_df)
        },
        error = function(e) {
          # If linear model fails, fallback to last known value
          fallback_val <- ifelse(
            all(is.na(hist_data[[col_name]])),
            0,  # fallback to 0 if everything is NA
            tail(na.omit(hist_data[[col_name]]), 1) # Last non-NA observation
          )
          future_df[[col_name]] <- fallback_val
        }
      )

      # Optional clamp for negative predictions if spend/certain columns must be >= 0
      # future_df[[col_name]] <- pmax(future_df[[col_name]], 0)

    } else {
      # For factor or character columns, replicate the mode
      col_data <- hist_data[[col_name]]
      ux       <- na.omit(col_data)
      if (length(ux) > 0) {
        freq_table <- table(ux)
        modal_val  <- names(freq_table)[which.max(freq_table)]
        # Preserve factor levels if needed
        if (is.factor(col_data)) {
          future_df[[col_name]] <- factor(modal_val, levels = levels(col_data))
        } else {
          future_df[[col_name]] <- modal_val
        }
      } else {
        # If everything is NA, fill with NA
        future_df[[col_name]] <- NA
      }
    }
  }

  # 5. Retrieve model coefficients (xDecompAgg table). Intercept stored as "(Intercept)"
  xDecompAgg <- OutputCollect$xDecompAgg
  coefs_all  <- xDecompAgg[xDecompAgg$solID == select_model, c("rn", "coef")]
  rownames(coefs_all) <- coefs_all$rn
  coefs <- coefs_all$coef
  names(coefs) <- coefs_all$rn

  # 6. Compute predicted GMV: sum of intercept + each variable * its coefficient
  if ("(Intercept)" %in% names(coefs)) {
    future_df$predicted_gmv <- coefs["(Intercept)"]
  } else {
    future_df$predicted_gmv <- 0
  }

  for (var in intersect(names(coefs), names(future_df))) {
    if (var != "(Intercept)") {
      future_df$predicted_gmv <- future_df$predicted_gmv + coefs[var] * future_df[[var]]
    }
  }

  # 7. Return future data with predicted GMV
  # If you wish to combine the date & predicted gmv only, you can do:
  # return(future_df[, c("date", "predicted_gmv", cols_to_predict)])
  # But we’ll return the entire frame:
  return(future_df)
}
