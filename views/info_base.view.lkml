view: trial_info_base {
  extension: required

  dimension: trial_id {
    type: number
    sql: ${TABLE}.trial_id ;;
  }
  dimension: hyperparameters {
    # STRUCT, Unnest?
    hidden: yes
  }
  dimension: hparam_tuning_evaluation_metrics {
    # STRUCT, Unnest?
    hidden: yes
  }
  dimension: training_loss {
    type: number
    sql: ${TABLE}.training_loss ;;
  }
  dimension: eval_loss {
    type: number
    sql: ${TABLE}.eval_loss ;;
  }
  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }
  dimension: error_message {
    type: string
    sql: ${TABLE}.error_message ;;
  }
  dimension: is_optimal {
    type: yesno
    sql: ${TABLE}.is_optimal ;;
  }
}

view: feature_info_base {
  extension: required

  ## SQL Table Name Required, Add in Extended View

  dimension: input {
    type: string
    sql: ${TABLE}.input ;;
  }
  dimension: min {
    type: number
    sql: ${TABLE}.min ;;
  }
  dimension: max {
    type: number
    sql: ${TABLE}.max ;;
  }
  dimension: mean {
    type: number
    sql: ${TABLE}.mean ;;
  }
  dimension: median {
    type: number
    sql: ${TABLE}.median ;;
  }
  dimension: stddev {
    type: number
    sql: ${TABLE}.stddev ;;
  }
  dimension: category_count {
    type: number
    sql: ${TABLE}.category_count ;;
  }
  dimension: null_count {
    type: number
    sql: ${TABLE}.null_count ;;
  }
}

view: training_info_base {
  extension: required

  ## SQL Table Name Required, Add in Extended View

  dimension: training_run {
    type: number
    sql: ${TABLE}.training_run ;;
  }
  dimension: iteration {
    type: number
    sql: ${TABLE}.iteration ;;
  }
  dimension: duration_ms {
    type: number
    sql: ${TABLE}.duration_ms ;;
  }
}
