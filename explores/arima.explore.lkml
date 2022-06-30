include: "/views/bqml_type/arima.view"

explore: arima {
  hidden: yes

  join: arima_coefficients {
    type: cross
    relationship: many_to_many
  }
  join: arima_ar_coefficients {
    sql: LEFT JOIN UNNEST(${arima_coefficients.ar_coefficients}) as arima_ar_coefficients ;;
    relationship: one_to_many
  }
  join: arima_ma_coefficients {
    sql: LEFT JOIN UNNEST(${arima_coefficients.ma_coefficients}) as arima_ma_coefficients ;;
    relationship: one_to_many
  }

  join: arima_evaluate {
    type: cross
    relationship: many_to_many
    fields: [arima_evaluate.arima_evaluate*]
  }

  join: arima_feature_info {
    type: cross
    relationship: many_to_many
  }

  join: arima_training_info {
    type: cross
    relationship: many_to_many
  }

  join: arima_forecast {
    type: cross
    relationship: many_to_many
  }

  join: arima_explain_forecast {
    type: cross
    relationship: many_to_many
  }

}
