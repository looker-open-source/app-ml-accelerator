view: model_info {
  sql_table_name: `@{GCP_PROJECT}`.@{bqml_model_dataset_name}.bqml_model_info ;;

  dimension: model_guid {
    type: string
    sql: ${TABLE}.model_guid ;;
  }

  dimension: model_name {
    type: string
    sql: ${TABLE}.model_name ;;
  }

  dimension: state_json {
    type: string
    sql: ${TABLE}.state_json ;;
  }

  dimension: created_by_email {
    type: string
    sql: ${TABLE}.created_by_email ;;
  }

  dimension: created_by_first_name {
    type: string
    sql: ${TABLE}.created_by_first_name ;;
  }

  dimension: created_by_last_name {
    type: string
    sql: ${TABLE}.created_by_last_name ;;
  }

  dimension: shared_with_emails {
    type: string
    sql: ${TABLE}.shared_with_emails ;;
  }

  dimension: full_email_list {
    type: string
    sql: "\""||${created_by_email}||"\" "||IFNULL(${shared_with_emails},'') ;;
  }

  dimension: model_created_at {
    type: date_time
    sql: TIMESTAMP_MILLIS(${TABLE}.model_created_at) ;;
  }

  dimension: model_updated_at {
    type: date_time
    sql: TIMESTAMP_MILLIS(${TABLE}.model_updated_at) ;;
  }

}
