view: forecast_base {
  extension: required

  ## SQL Table Name Required, Add in Extended View

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: date_raw
    sql: ${TABLE}.forecast_timestamp ;;
  }
  dimension_group: forecast {
    type: time
    timeframes: [raw, time, date, week, month, year]
    sql: ${TABLE}.forecast_timestamp ;;
    convert_tz: no
  }
  dimension: forecast_value {
    hidden: yes
    type: number
    sql: ${TABLE}.forecast_value ;;
  }
  dimension: standard_error {
    type: number
    sql: ${TABLE}.standard_error ;;
  }
  dimension: confidence_level {
    type: number
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

  measure: forecast_count {
    label: "Count of Forecasts"
    type: count
  }
  measure: total_forecast {
    type: sum
    sql: ${forecast_value} ;;
    value_format_name: decimal_4
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
