view: evaluate_base {
  extension: required

  ## SQL Table Name Required, Add in Extended View

  ## Arima Evaluate Fields
  dimension: non_seasonal_p {
    label: "Non Seasonal p"
    type: number
    sql: ${TABLE}.non_seasonal_p ;;
  }
  dimension: non_seasonal_d {
    label: "Non Seasonal d"
    type: number
    sql: ${TABLE}.non_seasonal_d ;;
  }
  dimension: non_seasonal_q {
    label: "Non Seasonal q"
    type: number
    sql: ${TABLE}.non_seasonal_q ;;
  }
  dimension: has_drift {
    type: string
    sql: ${TABLE}.has_drift ;;
  }
  dimension: log_likelihood {
    type: number
    sql: ${TABLE}.log_likelihood ;;
  }
  dimension: aic {
    label: "AIC"
    type: number
    sql: ${TABLE}.AIC ;;
    value_format_name: decimal_4
  }
  dimension: variance {
    type: number
    sql: ${TABLE}.variance ;;
    value_format_name: decimal_4
  }
  dimension: seasonal_periods {
    type: string
    sql: ARRAY_TO_STRING(${TABLE}.seasonal_periods, ", ") ;;
  }
  dimension: has_holiday_effect {
    type: string
    sql: ${TABLE}.has_holiday_effect ;;
  }
  dimension: has_spikes_and_dips {
    type: string
    sql: ${TABLE}.has_spikes_and_dips ;;
  }
  dimension: has_step_changes {
    type: string
    sql: ${TABLE}.has_step_changes ;;
  }
  dimension: error_message {
    type: string
    sql: ${TABLE}.error_message ;;
  }
  set: arima_evaluate {
    fields: [non_seasonal_p
      ,non_seasonal_d
      ,non_seasonal_q
      ,has_drift
      ,log_likelihood
      ,aic
      ,variance
      ,seasonal_periods
      ,has_holiday_effect
      ,has_spikes_and_dips
      ,has_step_changes
      ,error_message]
  }

  # Regressor Fields
  dimension: mean_absolute_error {
    group_label: "Metrics for Models with Numerical Targets"
    type: number
    sql: ${TABLE}.mean_absolute_error ;;
  }
  dimension: mean_squared_error {
    group_label: "Metrics for Models with Numerical Targets"
    type: number
    sql: ${TABLE}.mean_squared_error ;;
  }
  dimension: mean_squared_log_error {
    group_label: "Metrics for Models with Numerical Targets"
    type: number
    sql: ${TABLE}.mean_squared_log_error ;;
  }
  dimension: median_absolute_error {
    group_label: "Metrics for Models with Numerical Targets"
    type: number
    sql: ${TABLE}.median_absolute_error ;;
  }
  dimension: r2_score {
    group_label: "Metrics for Models with Numerical Targets"
    type: number
    sql: ${TABLE}.r2_score ;;
  }
  dimension: explained_variance {
    group_label: "Metrics for Models with Numerical Targets"
    type: number
    sql: ${TABLE}.explained_variance ;;
  }
  set: regressor {
    fields: [mean_absolute_error
      ,mean_squared_error
      ,mean_squared_log_error
      ,median_absolute_error
      ,r2_score
      ,explained_variance]
  }

  # Classifier Fields
  dimension: precision {
    group_label: "Metrics for Models with Categorical Targets"
    type: number
    sql: ${TABLE}.precision ;;
  }
  dimension: recall {
    group_label: "Metrics for Models with Categorical Targets"
    type: number
    sql: ${TABLE}.recall ;;
  }
  dimension: accuracy {
    group_label: "Metrics for Models with Categorical Targets"
    type: number
    sql: ${TABLE}.accuracy ;;
  }
  dimension: f1_score {
    group_label: "Metrics for Models with Categorical Targets"
    type: number
    sql: ${TABLE}.f1_score ;;
  }
  dimension: log_loss {
    group_label: "Metrics for Models with Categorical Targets"
    type: number
    sql: ${TABLE}.log_loss ;;
  }
  dimension: roc_auc {
    group_label: "Metrics for Models with Categorical Targets"
    label: "ROC AUC"
    type: number
    sql: ${TABLE}.roc_auc ;;
  }
  set: classifier {
    fields: [precision
      ,recall
      ,accuracy
      ,f1_score
      ,log_loss
      ,roc_auc]
  }

  # K-Means Fields

}
