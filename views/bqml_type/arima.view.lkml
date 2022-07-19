include: "/views/info_base.view"
include: "/views/evaluate_base.view"
include: "/views/forecast_base.view"

view: arima {
  derived_table: { sql: SELECT '{% parameter arima.model_name %}' as model_name_field ;; }
  parameter: model_name {
    type: unquoted
    hidden: no
  }

  parameter: input_table_name {
    type: unquoted
    hidden: no
  }

  ## Pre Training Parameters/Future Options

  parameter: time_series_timestamp_col {
    type: unquoted
    default_value: "" ## string_value
  }
  parameter: time_series_data_col {
    type: unquoted
    default_value: "" ## string_value
  }
  parameter: time_series_id_col {
    type: unquoted
    default_value: "" ## { string_value | string_array }
  }
  parameter: auto_arima {
    type: unquoted
    default_value: "TRUE" ## {TRUE | FALSE }
  }
  parameter: auto_arima_max_order {
    type: unquoted
    default_value: "5" ## 1-5
  }
  parameter: non_seasonal_order {
    type: unquoted
    default_value: "" ## (int64_value 1-5, int64_value 1-3, int64_value 1-5)
  }
  parameter: data_frequency {
    type: unquoted
    default_value: "AUTO_FREQUENCY" ## { 'AUTO_FREQUENCY' | 'PER_MINUTE' | 'HOURLY' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'QUARTERLY' | 'YEARLY' }
  }
  parameter: include_drift {
    type: unquoted
    default_value: "FALSE" ## { TRUE | FALSE }
  }
  parameter: holiday_region {
    type: unquoted
    default_value: "" ## { 'GLOBAL' | 'NA' | 'JAPAC' | 'EMEA' | 'LAC' | 'AE' | ... }
  }
  parameter: clean_spikes_and_dips {
    type: unquoted
    default_value: "TRUE" ## {TRUE | FALSE}
  }
  parameter: adjust_step_changes {
    type: unquoted
    default_value: "TRUE" ## {TRUE | FALSE }
  }
  parameter: decompose_time_series {
    type: unquoted
    default_value: "TRUE" ## {TRUE | FALSE }
  }

  parameter: set_horizon {
    label: "Forecast Horizon (optional)"
    description: "Choose the number of time points to forecast. The default value is 1,000. The maximum value is 10,000"
    type: number
    default_value: "1000"
  }
  parameter: set_holiday_region {
    label: "Holiday Effects Region (optional)"
    description: "Choose a geographical region if you would like to adjust for holiday effects. By default, holiday effect modeling is disabled."
    type: unquoted
    default_value: "none"
    allowed_value: {
      label: "No Holiday Adjustment"
      value: "none"
    }
    allowed_value: {
      label: "Global"
      value: "GLOBAL"
    }
    allowed_value: {
      label: "North America"
      value: "NA"
    }
    allowed_value: {
      label: "Japan and Asia Pacific"
      value: "JAPAC"
    }
    allowed_value: {
      label: "Europe, the Middle East and Africa"
      value: "EMEA"
    }
    allowed_value: {
      label: "Latin America and the Caribbean"
      value: "LAC"
    }
  }
  parameter: set_confidence_level {
    label: "Confidence Level (optional)"
    description: "The percentage of the future values that fall in the prediction interval. The default value is 0.95. The valid input range is [0, 1)."
    type: number
    default_value: "0.95"
  }
}


## Model Creation Phase

view: arima_coefficients {
  label: "Coefficients"

  sql_table_name: ML.ARIMA_COEFFICIENTS(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}) ;;

  dimension: ar_coefficients { hidden: yes }
  dimension: ma_coefficients { hidden: yes }
  dimension: intercept_or_drift {
    type: number
    sql: ${TABLE}.intercept_or_drift ;;
  }

  measure: count { type: count }
}
## Unnest these fields on explore. Field is array.
view: arima_ar_coefficients {
  label: "Coefficients"

  dimension: ar_coefficients {
    label: "AR Coefficients"
    type: number
    sql: ${TABLE} ;;
  }
}
view: arima_ma_coefficients {
  label: "Coefficients"

  dimension: ma_coefficients {
    label: "MA Coefficients"
    type: number
    sql: ${TABLE};;
  }
}

view: arima_feature_info {
  label: "Feature Info"
  extends: [feature_info_base]
  sql_table_name: ML.FEATURE_INFO(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}) ;;
}
view: arima_training_info {
  label: "Training Info"
  extends: [training_info_base]
  sql_table_name: ML.TRAINING_INFO(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}) ;;
}

## Model Use Phase

view: arima_evaluate {
  label: "Evaluation Metrics"
  extends: [evaluate_base]

  sql_table_name: ML.ARIMA_EVALUATE(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}
    , STRUCT(FALSE AS show_all_candidate_models)) ;;
}
view: arima_forecast {
  label: "Forecast"

  extends: [forecast_base]

  # sql_table_name: ML.FORECAST(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}
  #                           , STRUCT({% parameter arima.set_horizon %} AS horizon
  #                           , {% parameter arima.set_confidence_level %} AS confidence_level)) ;;

  derived_table: {
    sql: with
        -- get model forecast:
        forecast_values as (
          select forecast_timestamp
              ,  forecast_value
              ,  standard_error
              ,  confidence_level
              ,  prediction_interval_lower_bound
              ,  prediction_interval_upper_bound
          from ML.FORECAST(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}
                         , STRUCT({% parameter arima.set_horizon %} AS horizon
                         , {% parameter arima.set_confidence_level %} AS confidence_level)
                        )
        ),
        -- generate date series
        -- uses input_data for min_date and forecast_values for max date
        date_series as (
        select date from unnest(GENERATE_DATE_ARRAY(
            (select min({% parameter arima.time_series_timestamp_col %}) min_date from @{BQML_MODEL_DATASET_NAME}.{% parameter arima.input_table_name %}),
            (select max(date(forecast_timestamp)) max_date from forecast_values),
            INTERVAL 1 DAY)) date
        )

      select d.date
      , i.{% parameter arima.time_series_data_col %} as time_series_data_col
      , i.{% parameter arima.time_series_timestamp_col %} as time_series_timestamp_col
      , f.*
      from date_series d
      left join @{BQML_MODEL_DATASET_NAME}.{% parameter arima.input_table_name %} i
      on i.{% parameter arima.time_series_timestamp_col %} = d.date
      left join forecast_values f
      on date(f.forecast_timestamp) = d.date
      ;;
  }

  dimension: pk {
    type: string
    sql: TIMESTAMP(${TABLE}.date) ;;
    primary_key: yes
  }

  dimension_group: date {
    label: ""
    type: time
    sql: TIMESTAMP(${TABLE}.date) ;;
  }

  dimension: time_series_data_col {
    label_from_parameter: arima.time_series_data_col
    sql: ${TABLE}.time_series_data_col ;;
  }

  dimension: forecasted_time_series_data_col {
    label: "Forecasted Value"
    sql: ${TABLE}.forecast_value ;;
  }

  dimension: standard_error {
    type: string
    sql: ${TABLE}.standard_error ;;
  }

  dimension: confidence_level {
    type: string
    sql: ${TABLE}.confidence_level ;;
  }

  dimension: prediction_interval_lower_bound {
    type: string
    sql: ${TABLE}.prediction_interval_lower_bound ;;
  }

  dimension: prediction_interval_upper_bound {
    type: string
    sql: ${TABLE}.prediction_interval_upper_bound ;;
  }

  measure: total_time_series_data_col {
    type: number
    sql: sum(${time_series_data_col}) ;;
    value_format_name: decimal_2
  }

  measure: total_forecast {
    type: number
    sql: sum(${forecasted_time_series_data_col}) ;;
    value_format_name: decimal_2
  }
  measure: total_prediction_interval_lower_bound {
    type: sum
    sql: ${prediction_interval_lower_bound} ;;
    value_format_name: decimal_4
  }
  measure: total_prediction_interval_upper_bound {
    type: sum
    sql: ${prediction_interval_upper_bound} ;;
    value_format_name: decimal_4
  }
}

view: arima_explain_forecast {
  label: "Explain Forecast"

  sql_table_name: ML.EXPLAIN_FORECAST(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter arima.model_name %}
                                    , STRUCT({% parameter arima.set_horizon %} AS horizon
                                    , {% parameter arima.set_confidence_level %} AS confidence_level)) ;;

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: date_raw
    sql: ${TABLE}.time_series_timestamp ;;
  }
  dimension_group: time_series {
    type: time
    timeframes: [raw, time, date, week, month, year]
    sql: ${TABLE}.time_series_timestamp ;;
    convert_tz: no
  }
  dimension: time_series_type {
    type: string
    description: "A value of either history or forecast. The rows with history in this column are used in training, either directly from the training table, or from interpolation using the training data."
    sql: ${TABLE}.time_series_type ;;
  }
  dimension: time_series_data {
    hidden: yes
    type: number
    sql: ${TABLE}.time_series_data ;;
  }
  dimension: time_series_adjusted_data {
    hidden: yes
    type: number
    sql: ${TABLE}.time_series_adjusted_data ;;
  }
  dimension: standard_error {
    type: number
    description: "The standard error of the residuals during the ARIMA fitting. The values are the same for all history rows. For forecast rows, this value increases with time, as the forecast values become less reliable."
    sql: ${TABLE}.standard_error ;;
  }
  dimension: confidence_level {
    type: number
    description: "The user-specified confidence level or, if unspecified, the default value of 0.95. This value is the same for forecast rows and NULL for history rows."
    sql: ${TABLE}.confidence_level ;;
  }
  dimension: prediction_interval_lower_bound {
    hidden: yes
    type: number
    sql: ${TABLE}.prediction_interval_lower_bound ;;
  }
  dimension: prediction_interval_upper_bound {
    hidden: yes
    type: number
    sql: ${TABLE}.prediction_interval_upper_bound ;;
  }
  dimension: trend {
    hidden: yes
    type: number
    sql: ${TABLE}.trend ;;
  }
  dimension: seasonal_period_yearly {
    hidden: yes
    type: number
    sql: ${TABLE}.seasonal_period_yearly ;;
  }
  dimension: seasonal_period_quarterly {
    hidden: yes
    type: number
    sql: ${TABLE}.seasonal_period_quarterly ;;
  }
  dimension: seasonal_period_monthly {
    hidden: yes
    type: number
    sql: ${TABLE}.seasonal_period_monthly ;;
  }
  dimension: seasonal_period_weekly {
    hidden: yes
    type: number
    sql: ${TABLE}.seasonal_period_weekly ;;
  }
  dimension: seasonal_period_daily {
    hidden: yes
    type: number
    sql: ${TABLE}.seasonal_period_daily ;;
  }
  dimension: holiday_effect {
    hidden: yes
    type: number
    sql: ${TABLE}.holiday_effect ;;
  }
  dimension: spikes_and_dips {
    hidden: yes
    type: number
    sql: ${TABLE}.spikes_and_dips ;;
  }
  dimension: step_changes {
    hidden: yes
    type: number
    sql: ${TABLE}.step_changes ;;
  }
  measure: count {
    label: "Row Count"
    type: count
  }
  measure: total_time_series_data {
    type: sum
    description: "The data of the time series. For history rows, time_series_data is either the training data or the interpolated value using the training data. For forecast rows, time_series_data is the forecast value."
    sql: ${time_series_data} ;;
    value_format_name: decimal_4
  }
  measure: total_time_series_adjusted_data {
    type: sum
    description: "The adjusted data of the time series. For history rows, this is the value after cleaning spikes and dips, adjusting the step changes, and removing the residuals. It is the aggregation of all the valid components: holiday effect, seasonal components, and trend. For forecast rows, this is the forecast value, which is the same as the value of time_series_data"
    sql: ${time_series_adjusted_data} ;;
    value_format_name: decimal_4
  }
  measure: total_prediction_interval_lower_bound {
    type: number
    description: "The lower bound of the prediction result. Only forecast rows have values other than NULL in this column."
    sql: SUM(${prediction_interval_lower_bound}) ;;
    value_format_name: decimal_4
  }
  measure: total_prediction_interval_upper_bound {
    type: number
    description: "The upper bound of the prediction result. Only forecast rows have values other than NULL in this column."
    sql: SUM(${prediction_interval_upper_bound}) ;;
    value_format_name: decimal_4
  }
  measure: total_trend {
    type: sum
    description: "The long-term increase or decrease in the time series data."
    sql: ${trend} ;;
    value_format_name: decimal_4
  }
  measure: total_seasonal_period_yearly {
    type: sum
    description: "The time series data value affected by the time of the year. This value is NULL if no yearly effect is found."
    sql: ${seasonal_period_yearly} ;;
    value_format_name: decimal_4
  }
  measure: total_seasonal_period_quarterly {
    type: sum
    description: "The time series data value affected by the time of the quarter. This value is NULL if no quarterly effect is found."
    sql: ${seasonal_period_quarterly} ;;
    value_format_name: decimal_4
  }
  measure: total_seasonal_period_monthly {
    type: sum
    description: "The time series data value affected by the time of the month. This value is NULL if no monthly effect is found."
    sql: ${seasonal_period_monthly} ;;
    value_format_name: decimal_4
  }
  measure: total_seasonal_period_weekly {
    type: sum
    description: "The time series data value affected by the time of the week. This value is NULL if no weekly effect is found."
    sql: ${seasonal_period_weekly} ;;
    value_format_name: decimal_4
  }
  measure: total_seasonal_period_daily {
    type: sum
    description: "The time series data value affected by the time of the day. This value is NULL if no daily effect is found."
    sql: ${seasonal_period_daily} ;;
    value_format_name: decimal_4
  }
  measure: total_holiday_effect {
    type: sum
    description: "The time series data value affected by different holidays. This is the aggregation value of all the holiday effects. This value is NULL if no holiday effect is found."
    sql: ${holiday_effect} ;;
    value_format_name: decimal_4
  }
  measure: total_spikes_and_dips {
    type: sum
    description: "The unexpectedly high or low values of the time series. For history rows, the value is NULL if no spike or dip is found. This value is NULL for forecast rows."
    sql: ${spikes_and_dips} ;;
    value_format_name: decimal_4
  }
  measure: total_step_changes {
    type: sum
    description: "The abrupt or structural change in the distributional properties of the time series. For history rows, this value is NULL if no step change is found. This value is NULL for forecast rows."
    sql: ${step_changes} ;;
    value_format_name: decimal_4
  }
}