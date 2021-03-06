#' Extract value column and present it as ts
#'
#' Extract value column and present it as ts
#'
#' Extract value column and present it as ts
#'
#' @param model_sample preferably tsibble
#' @param target name of the target variable, "value" by default
#' @return univariate time series
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' extract_value(test)
extract_value = function(model_sample, target = "value") {
  y = stats::as.ts(dplyr::select(model_sample, !!target))
  return(y)
}



#' Do forecast using auto ETS
#'
#' Do forecast using auto ETS
#'
#' Do forecast using auto ETS
#'
#' @param model_sample preferably tsibble with "value" column
#' @param h forecasting horizon, is ignored
#' @param target name of the target variable, "value" by default
#' @return auto ETS model
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' ets_fun(test, 1)
ets_fun = function(model_sample, h, target = "value") {
  # h is ignored!
  y = extract_value(model_sample, target = target)
  model = forecast::ets(y)
  return(model)
}


#' Do forecast using auto ARIMA
#'
#' Do forecast using auto ARIMA
#'
#' Do forecast using auto ARIMA
#'
#' @param model_sample preferably tsibble with "value" column
#' @param h forecasting horizon, is ignored
#' @param target name of the target variable, "value" by default
#' @return auto ARIMA model
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' arima_fun(test, 1)
arima_fun = function(model_sample, h, target = "value") {
  # h is ignored!
  y = extract_value(model_sample, target = target)
  model = forecast::auto.arima(y)
  return(model)
}

#' Do forecast using ARIMA(1,0,1)-SARIMA(1,0,1)
#'
#' Do forecast using ARIMA(1,0,1)-SARIMA(1,0,1)
#'
#' Do forecast using ARIMA(1,0,1)-SARIMA(1,0,1)
#'
#' @param model_sample preferably tsibble with "value" column
#' @param h forecasting horizon, is ignored
#' @param target name of the target variable, "value" by default
#' @return ARIMA(1,0,1)-SARIMA(1,0,1) model
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' arima101_101_fun(test, 1)
arima101_101_fun = function(model_sample, h = 0, target = "value") {
  # h is ignored!
  y = extract_value(model_sample, target = target)
  model = try(forecast::Arima(y, order = c(1, 0, 1), seasonal = c(1, 0, 1)))
  if (methods::is(model, "try-error")) {
    message('Switching to ML!')
    model = try(forecast::Arima(y, order = c(1, 0, 1), seasonal = c(1, 0, 1), method = "ML"))
    if (methods::is(model, "try-error")) {
      message('Fuck! It failed CSS-ML, it failed ML, we will use CSS')
      model = try(forecast::Arima(y, order = c(1, 0, 1), seasonal = c(1, 0, 1), method = "CSS"))
      if (methods::is(model, "try-error")) {
        message('CSS also failed. Choose another model!')
      }
    }
  }
  return(model)
}


#' Do forecast using auto TBATS
#'
#' Do forecast using auto TBATS
#'
#' Do forecast using auto TBATS
#'
#' @param model_sample preferably tsibble with "value" column
#' @param h forecasting horizon, is ignored
#' @param target name of the target variable, "value" by default
#' @return auto TBATS model
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' tbats_fun(test, 1)
tbats_fun = function(model_sample, h, target = "value") {
  # h is ignored!
  y = extract_value(model_sample, target = target)
  model = forecast::tbats(y)
  return(model)
}


#' Extract one scalar forecast from univariate model
#'
#' Extract one scalar forecast from univariate model
#'
#' Extract one scalar forecast from univariate model
#'
#' @param model univariate model
#' @param h forecasting horizon
#' @param model_sample ignored
#' @return mean scalar forecast
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' tbats = tbats_fun(test, 1)
#' uni_model_2_scalar_forecast(tbats, h = 2)
uni_model_2_scalar_forecast = function(model, h = 1, model_sample = NA) {
  # model_sample is unused in univariate models
  forecast_object = forecast::forecast(model, h = h)
  y_hat = forecast_2_scalar(forecast_object, h = h)
  return(y_hat)
}



#' Add fourier terms to tsibble
#'
#' Add fourier terms to tsibble
#'
#' Add fourier terms to tsibble
#'
#' @param original original tsibble
#' @param K_fourier number of fourier terms
#' @return tsibble with fourier terms
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' add_fourier(test_tsibble)
add_fourier = function(original, K_fourier = Inf) {
  original_ts = stats::as.ts(original)
  freq = stats::frequency(original)
  K_fourier = min(floor(freq/2), K_fourier)

  X_fourier = forecast::fourier(original_ts, K = K_fourier)
  fourier_names = colnames(X_fourier)
  fourier_names = stringr::str_replace(fourier_names, "-", "_") %>% stringr::str_to_lower()
  colnames(X_fourier) = fourier_names
  X_fourier_tibble = tibble::as_tibble(X_fourier)

  augmented = dplyr::bind_cols(original, X_fourier_tibble)
  return(augmented)
}



#' Add linear and root trends to tibble
#'
#' Add linear and root trends to tibble
#'
#' Add linear and root trends to tibble
#'
#' @param original tibble
#' @return tibble with trend_lin and trend_root columns
#' @export
#' @examples
#' # dumb example: add trend to cross section :) :)
#' add_trend(cars)
add_trend = function(original) {
  nobs = nrow(original)
  augmented = dplyr::mutate(original, trend_lin = 1:nobs, trend_root = sqrt(1:nobs))
  return(augmented)
}


#' Add lags of many variables
#'
#' Add lags of many variables
#'
#' Add lags of many variables
#' The name of variables should be with quotes.
#' Designed mainly for explanatory variables.
#' @param original original tsibble
#' @param variable_names variables to add lags, with quotes! Like "gdp" and not gdp.
#' @param lags desired lags, a vector
#' @return tsibble with lags of specified variables
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' add_lags(test_tsibble, "value", 1:7)
add_lags = function(original, variable_names, lags = c(1, 2)) {
  for (variable_name in variable_names) {
    for (lag in lags) {
      new_variable_name = paste0("lag", lag, "_", variable_name)
      new_value = dplyr::lag(dplyr::pull(original, variable_name), lag)
      original = dplyr::mutate(original, !!new_variable_name := new_value)
    }
  }
  return(original)
}


#' Get last date from tsibble
#'
#' Get last date from tsibble
#'
#' Get last date from tsibble
#' @param original original tsibble
#' @return last date
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' get_last_date(test_tsibble)
get_last_date = function(original) {
  date_variable = tsibble::index(original)
  date = dplyr::pull(original, !!date_variable)
  last_date = max(date)
  return(last_date)
}


#' Get first date from tsibble
#'
#' Get first date from tsibble
#'
#' Get first date from tsibble
#' @param original original tsibble
#' @return first date
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' get_first_date(test_tsibble)
get_first_date = function(original) {
  date_variable = tsibble::index(original)
  date = dplyr::pull(original, !!date_variable)
  last_date = min(date)
  return(last_date)
}






#' Augment tsibble with usual regressors
#'
#' Augment tsibble with usual regressors
#'
#' Augment tsibble with usual regressors.
#' Adds trend, fourier terms, lags of regressor and dependen variables.
#' Also appends h rows for forecasting.
#' @param original original tsibble
#' @param h forecasting horizon
#' h rows to append in the future, corresponding lags will be added to tsibble
#' @param target name of the target variable
#' @return augmented tibble
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' augment_tsibble_4_regression(test_tsibble, h = 4)
augment_tsibble_4_regression = function(original, target = "value", h = 1) {
  frequency = stats::frequency(original)
  augmented = original %>% tsibble::append_row(n = h) %>%
    add_trend() %>% add_fourier() %>%
    add_lags(target, lags = c(h, h + 1, frequency, frequency + 1))

  date_variable = tsibble::index(original) %>% as.character()
  regressor_names = dplyr::setdiff(colnames(original), c(target, date_variable))
  augmented = augmented %>% add_lags(regressor_names, lags = c(h, h + 1, frequency, frequency + 1))
  augmented = dplyr::select(augmented, -!!regressor_names)
  return(augmented)
}




#' Estimate lasso model using tsibble with regressors
#'
#' Estimate lasso model using tsibble with regressors
#'
#' Estimate lasso model using tsibble with regressors
#' Regressors should already include lags, fourier terms, trend etc
#' @param augmented tsibble with all predictors with lags.
#' May be obtained using `augment_tsibble_4_regression`.
#' @param seed random seed
#' @param target name of the target variable
#' @return lasso model
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts) %>% dplyr::rename(date = index)
#' augmented = augment_tsibble_4_regression(test_tsibble, h = 4)
#' model = lasso_augmented_estimate(augmented)
lasso_augmented_estimate = function(augmented, target = "value", seed = 777) {
  yX_tsibble = stats::na.omit(augmented)
  y = yX_tsibble %>% dplyr::pull(target)

  date_variable = tsibble::index(augmented)
  X = tibble::as_tibble(yX_tsibble) %>% dplyr::select(-!!target, -!!date_variable) %>% as.matrix()

  set.seed(seed)
  lasso_model = glmnet::cv.glmnet(X, y)
  return(lasso_model)
}


#' Estimate random forest (ranger) model using tsibble with regressors
#'
#' Estimate random forest (ranger) using tsibble with regressors
#'
#' Estimate random forest (ranger) model using tsibble with regressors.
#' Regressors should already include lags, fourier terms, trend etc
#' @param augmented tsibble with all predictors with lags.
#' May be obtained using `augment_tsibble_4_regression`.
#' @param seed random seed
#' @param target name of the target variable
#' @return lasso model
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' augmented = augment_tsibble_4_regression(test_tsibble, h = 4)
#' model = ranger_augmented_estimate(augmented)
ranger_augmented_estimate = function(augmented, target = "value", seed = 777) {
  yX_tsibble = stats::na.omit(augmented)

  set.seed(seed)
  date_variable = tsibble::index(augmented)
  formula = paste0(target, " ~ . - ", date_variable)

  ranger_model = ranger::ranger(data = yX_tsibble, formula = formula)
  return(ranger_model)
}


#' Augment data and estimate lasso model
#'
#' Augment data and estimate lasso model
#'
#' Augment data and estimate lasso model.
#' Trend, fourier terms, lags are added before estimation of lasso model.
#' @param model_sample tsibble that will be augmented with trend etc
#' @param seed random seed
#' @param target name of the target variable
#' @param h forecasting horizon
#' @return lasso model
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' model = lasso_fun(test_tsibble)
lasso_fun = function(model_sample, seed = 777, target = "value", h = 1) {
  augmented_sample = augment_tsibble_4_regression(model_sample, target = target, h = h)
  model = lasso_augmented_estimate(augmented_sample, seed = 777, target = target)

  return(model)
}

#' Augment data and estimate ranger model
#'
#' Augment data and estimate ranger model
#'
#' Augment data and estimate random forest (ranger) model.
#' Trend, fourier terms, lags are added before estimation of lasso model.
#' @param model_sample tsibble that will be augmented with trend etc
#' @param seed random seed
#' @param target name of the target variable
#' @param h forecasting horizon
#' @return ranger model
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' model = ranger_fun(test_tsibble)
ranger_fun = function(model_sample, seed = 777, target = "value", h = 1) {
  augmented_sample = augment_tsibble_4_regression(model_sample, target = target, h = h)
  model = ranger_augmented_estimate(augmented_sample, seed = 777, target = target)

  return(model)
}




#' Obtain scalar forecast from lasso model
#'
#' Obtain scalar forecast from lasso model
#'
#' Obtain scalar forecast from lasso model.
#' The function automatically augments data with lags, fourier terms, trend etc.
#' @param model estimated lasso model
#' @param model_sample non-augmented data set for model estimation
#' @param s criterion to select best regularization lambda in lasso
#' @param target name of the target variable
#' @param h forecasting horizon
#' @return scalar forecast for given h
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' model = lasso_fun(test_tsibble, h = 1)
#' lasso_2_scalar_forecast(model, h = 1, model_sample = test_tsibble)
lasso_2_scalar_forecast = function(model, h = 1, target = "value", model_sample, s = c("lambda.min", "lambda.1se")) {
  s = match.arg(s)

  augmented_sample = augment_tsibble_4_regression(model_sample, h = h, target = target)
  yX_future_tsibble = utils::tail(augmented_sample, 1)

  date_variable = tsibble::index(augmented_sample)
  X_future = tibble::as_tibble(yX_future_tsibble) %>% dplyr::select(-!!target, -!!date_variable) %>% as.matrix()

  point_forecast = stats::predict(model, X_future, s = s)

  return(point_forecast)
}


#' Obtain scalar forecast from random forest (ranger) model
#'
#' Obtain scalar forecast from random forest (ranger) model
#'
#' Obtain scalar forecast from random forest (ranger) model.
#' The function automatically augments data with lags, fourier terms, trend etc.
#' @param model estimated ranger model
#' @param model_sample non-augmented data set for model estimation
#' @param target name of the target variable
#' @param h forecasting horizon
#' @return scalar forecast for given h
#' @export
#' @examples
#' test_ts = stats::ts(rnorm(100), start = c(2000, 1), freq = 12)
#' test_tsibble = tsibble::as_tsibble(test_ts)
#' model = ranger_fun(test_tsibble, h = 1)
#' ranger_2_scalar_forecast(model, h = 1, model_sample = test_tsibble)
ranger_2_scalar_forecast = function(model, h = 1, target = "value", model_sample) {

  augmented_sample = augment_tsibble_4_regression(model_sample, h = h, target = target)
  yX_future_tsibble = utils::tail(augmented_sample, 1)

  ranger_pred = stats::predict(model, data = yX_future_tsibble)
  point_forecast = ranger_pred$predictions

  return(point_forecast)
}



#' Prepare model tibble for cross-validation
#'
#' Prepare model tibble for cross-validation
#'
#' Prepare model tibble for cross-validation
#' @param h_all vector of forecasting horizons
#' @param window_type sliding or stretching
#' @param target name of the target variable
#' @param model_fun_tibble tibble with names of estimator functions and scalar forecast extractors
#' @param series_data tsibble with full data sample
#' @param dates_test test dates
#' @return tibble with one row per model
#' @export
#' @examples
#' # no yet
prepare_model_list = function(h_all = 1, model_fun_tibble, series_data, dates_test,
                              window_type = c("sliding", "stretching"), target = "value") {
  model_list = tidyr::crossing(date = dates_test, h = h_all, model_fun = model_fun_tibble$model_fun)
  message("You may see the warning: `.named` can no longer be a width")
  message("Don't worry :) :) Origin: crossing function")
  window_type = match.arg(window_type)

  date_variable = tsibble::index(series_data) %>% as.character()
  data_frequency = stats::frequency(series_data)

  model_list = dplyr::left_join(model_list, dplyr::select(series_data, !!target), by = date_variable)
  model_list = dplyr::rename(model_list, value = !!target) # in model list dependent value is called "value"

  # as_date(date) is needed because date may be yearmonth
  model_list = dplyr::mutate(model_list, train_end_date = lubridate::as_date(date) - months(h * 12 / data_frequency))

  full_sample_start_date = min(series_data$date)
  full_sample_last_date = max(series_data$date)
  test_sample_start_date = min(model_list$date)
  window_min_length = round(lubridate::interval(full_sample_start_date, test_sample_start_date) /  months(12 / data_frequency)) - max(h_all) + 1


  if (window_type == "stretching") {
    model_list = dplyr::mutate(model_list, train_start_date = min(dplyr::pull(series_data, date)))
  } else {
    # sliding window case
    model_list = dplyr::mutate(model_list, train_start_date = train_end_date - months((window_min_length - 1) * 12 / data_frequency ))
  }

  model_list = dplyr::mutate(model_list,
                      train_sample = purrr::pmap(list(x = train_start_date, y = train_end_date),
                                          ~ dplyr::filter(series_data, date >= .x, date <= .y)))


  # we estimate some models only with maximal h -----------------------------------

  model_list = dplyr::left_join(model_list,  model_fun_tibble, by = "model_fun")

  model_list = model_list %>% dplyr::group_by(train_end_date, train_start_date, model_fun) %>%
    dplyr::mutate(duplicate_model = h_agnostic & (h < max(h))) %>% dplyr::ungroup()
  model_list = dplyr::mutate(model_list, target = target)

  return(model_list)
}




#' Prepare model tibble for forecasts
#'
#' Prepare model tibble for forecasts
#'
#' Prepare model tibble for forecasts
#' @param h_all vector of forecasting horizons
#' @param target name of the target variable
#' @param model_fun_tibble tibble with names of estimator functions and scalar forecast extractors
#' @param series_data tsibble with full data sample
#' @return tibble with one row per model
#' @export
#' @examples
#' # no yet
prepare_model_list2 = function(h_all = 1, model_fun_tibble, series_data, target = "value") {

  full_sample_last_date = as.Date(max(series_data$date))
  full_sample_start_date = as.Date(min(series_data$date))

  model_list = tidyr::crossing(h = h_all, model_fun = model_fun_tibble$model_fun)
  model_list = dplyr::mutate(model_list, date = full_sample_last_date + months(h * 12 / stats::frequency(series_data)))
  model_list = dplyr::mutate(model_list, train_end_date = full_sample_last_date)
  model_list = dplyr::mutate(model_list, train_start_date = full_sample_start_date)


  model_list = dplyr::mutate(model_list,
                      train_sample = purrr::pmap(list(x = train_start_date, y = train_end_date),
                                          ~ dplyr::filter(series_data, date >= .x, date <= .y)))


  # we estimate some models only with maximal h -----------------------------------

  model_list = dplyr::left_join(model_list,  model_fun_tibble, by = "model_fun")

  model_list = model_list %>% dplyr::group_by(train_end_date, train_start_date, model_fun) %>%
    dplyr::mutate(duplicate_model = h_agnostic & (h < max(h))) %>% dplyr::ungroup()
  model_list = dplyr::mutate(model_list, target = target)
  return(model_list)
}






#' Estimate non-duplicate models from model tibble
#'
#' Estimate non-duplicate models from model tibble
#'
#' Estimate non-duplicate models from model tibble.
#' If model is the same for different h it is estimated only once.
#' @param model_list tibble with one model per row
#' @param store_models inside tibble or in one separate file per model
#' @return rows of the orignal tibble correspinding to non-duplicate models plus column with estimated models
#' @export
#' @examples
#' # no yet
estimate_nonduplicate_models = function(model_list, store_models = c("tibble", "file")) {
  store_models = match.arg(store_models)

  if (store_models == "file") {
    stop("File storage of models not implemented yet")
  }

  model_list_half_fitted = dplyr::filter(model_list, !duplicate_model)
  model_list_half_fitted = model_list_half_fitted %>% dplyr::mutate(
    fitted_model = purrr::pmap(list(train_sample, h, model_fun, target),
                               ~ do.call(..3, list(h = ..2, model_sample = ..1, target = ..4)))
  )
  return(model_list_half_fitted)
}



#' Fill duplicate models into model tibble
#'
#' Fill duplicate models into model tibble
#'
#' Fill duplicate models into model tibble.
#' @param model_list_half_fitted tibble with estimated non-duplicate models
#' @param full_model_list tibble with complete list of duplicated and non-duplicated models
#' @return full original tibble with one estimated model per row
#' @export
#' @examples
#' # no yet
fill_duplicate_models = function(model_list_half_fitted, full_model_list) {
  right_tibble = model_list_half_fitted %>% dplyr::filter(h_agnostic) %>%
    dplyr::select(model_fun, train_start_date, train_end_date, fitted_model)

  duplicate_models = full_model_list %>% dplyr::filter(duplicate_model)

  duplicate_models_fitted = dplyr::left_join(duplicate_models, right_tibble,
                                      by = c("model_fun", "train_start_date", "train_end_date"))

  model_list_fitted = dplyr::bind_rows(model_list_half_fitted, duplicate_models_fitted)
  return(model_list_fitted)
}


#' Add point forecast to models tibble
#'
#' Add point forecast to models tibble
#'
#' Add point forecast to models tibble.
#' @param model_list_fitted tibble with one model per row
#' @return original tibble plus point forecasts
#' @export
#' @examples
#' # no yet
add_point_forecasts = function(model_list_fitted) {
  model_list_fitted = dplyr::mutate(model_list_fitted,
                             point_forecast = purrr::pmap_dbl(list(fitted_model, h, train_sample, forecast_extractor),
                                                       ~ do.call(..4, list(model = ..1, h = ..2, model_sample = ..3))
                             ))
  return(model_list_fitted)
}



#' Estimate and forecast all models from model tibble
#'
#' Estimate and forecast all models from model tibble
#'
#' Estimate and forecast all models from model tibble
#' In this tibble target variable is always named value.
#' @param model_list tibble with one model per row
#' @return tibble with estimated models and point forecasts
#' @export
#' @examples
#' # no yet
estimate_and_forecast = function(model_list) {
  message("Estimating non-duplicate models.")
  non_duplicate_fitted = estimate_nonduplicate_models(model_list)

  message("Filling duplicate models.")
  model_list_fitted = fill_duplicate_models(non_duplicate_fitted, model_list)

  message("Extracting point forecasts.")
  model_list_fitted = add_point_forecasts(model_list_fitted)

  return(model_list_fitted)
}







#' Calculate mae table from estimated models tibble
#'
#' Calculate mae table from estimated models tibble
#'
#' Calculate mae table from estimated models tibble.
#' In this tibble target variable is always named value.
#' @param model_list_fitted tibble with one model per row
#' @return tibble with mae
#' @export
#' @examples
#' # no yet
calculate_mae_table = function(model_list_fitted) {
  mae_table = model_list_fitted %>% dplyr::select(h, model_fun, value, point_forecast) %>%
    dplyr::mutate(abs_diff = abs(value - point_forecast))  %>%
    dplyr::group_by(h, model_fun) %>% dplyr::summarise(mae = mean(abs_diff, na.rm = TRUE))

  # sort by mae for each h:
  mae_table = dplyr::arrange(mae_table, h, mae)

  return(mae_table)
}


#' Do forecast using ARIMA(1,0,1)-SARIMA(0,1,0)
#'
#' Do forecast using ARIMA(1,0,1)-SARIMA(0,1,0)
#'
#' Do forecast using ARIMA(1,0,1)-SARIMA(0,1,0)
#'
#' @param model_sample preferably tsibble
#' @param h forecasting horizon, is ignored
#' @param target name of the target variable, "value" by default
#' @return ARIMA(1,0,1)-SARIMA(0,1,0) model
#' @export
#' @examples
#' test = dplyr::tibble(date = as.Date("2017-01-01") + 0:9, value = rnorm(10))
#' arima101_010_fun(test, 1)
arima101_010_fun = function(model_sample, h, target = "value") {
  # h is ignored!
  y = extract_value(model_sample, target = target)
  model = forecast::Arima(y, order = c(1, 0, 1), seasonal = c(0, 1, 0), method = "ML")
  return(model)
}




#' @title transforms forecast object into point forecast
#' @description transforms forecast object into point forecast
#' @details transforms forecast object into point forecast for common model types.
#' @param fcst_object complex forecast from model
#' @param h forecasting horizon
#' @return point forecast, single number
#' @export
#' @examples
#' fcst_object = forecast::forecast(rnorm(100), h = 6)
#' forecast_2_scalar(fcst_object, h = 3)
forecast_2_scalar = function(fcst_object, h = 1) {
  point_forecast = NA_real_
  if (class(fcst_object) == "numeric") {
    if (length(fcst_object) == 1) {
      point_forecast = fcst_object
    }
    if (length(fcst_object) >= h) {
      point_forecast = fcst_object[h]
    }
  }
  if (class(fcst_object) == "forecast") {
    point_forecast = fcst_object$mean[h]
  }
  if (class(fcst_object) == "ranger.prediction") {
    rngr_predictions = fcst_object$predictions
    if (length(rngr_predictions) == 1) {
      point_forecast = rngr_predictions
    }
    if (length(rngr_predictions) >= h) {
      point_forecast = rngr_predictions[h]
    }
  }
  return(point_forecast)
}





