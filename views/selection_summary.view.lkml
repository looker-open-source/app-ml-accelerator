view: selection_summary {
  derived_table: {
    sql:  SELECT column_stats.column_name
            , column_stats._nulls AS count_nulls
            , column_stats._non_nulls AS count_not_nulls
            , column_stats.pct_not_null AS pct_not_null
            , column_stats.count_distinct_values
            , column_stats.pct_unique
            , column_metadata.data_type
            , column_metadata.input_data_column_count
            , column_stats.input_data_row_count
            , column_stats._min_value
            , column_stats._max_value
            , column_stats._avg_value

          FROM (SELECT column_name,
                  COUNT(0) AS input_data_row_count
                  , COUNT(DISTINCT column_value) AS count_distinct_values
                  , SAFE_DIVIDE(COUNT(DISTINCT column_value),COUNT(*)) AS pct_unique
                  , COUNTIF(column_value IS NULL) AS _nulls
                  , COUNTIF(column_value IS NOT NULL) AS _non_nulls
                  , COUNTIF(column_value IS NOT NULL) / COUNT(0) AS pct_not_null
                  , MIN(SAFE_CAST(column_value as numeric)) AS _min_value
                  , MAX(SAFE_CAST(column_value as numeric)) AS _max_value
                  , AVG(SAFE_CAST(column_value AS numeric)) AS _avg_value


-- unpivot input data into column_name, column_value
--  capture all fields in each row AS JSON string (e.g., "field_a": valueA, "field_b": valueB)
--  unnest array created by split of row_json by ','
--      "field_a": valueA
--      "field_b": valueB
--  split further on : to get separate columns for name and value
--  format to trim "" from column name and replace any string nulls with true NULLs
                FROM (SELECT trim(column_name, '"') AS column_name
                        , IF(SAFE_CAST(column_value AS STRING)='null',NULL, column_value) AS column_value

                      FROM (SELECT REGEXP_REPLACE(TO_JSON_STRING(t), r'^{|}$', '') AS row_json
                            FROM `@{GCP_PROJECT}.@{BQML_MODEL_DATASET_NAME}.{% parameter selection_summary.input_data_view_name %}` AS t ) table_AS_json
                            , UNNEST(SPLIT(row_json, ',"')) AS cols
                            , UNNEST([SPLIT(cols, ':')[SAFE_OFFSET(0)]]) AS column_name
                            , UNNEST([SPLIT(cols, ':')[SAFE_OFFSET(1)]]) AS column_value

                      ) AS col_val

                WHERE column_name <> '' AND column_name NOT LIKE '%-%'
                GROUP BY column_name
                ) AS column_stats

          INNER JOIN (SELECT table_catalog
                          , table_schema
                          , table_name
                          , column_name
                          , data_type
                          , count(0) over (partition by 1) AS input_data_column_count
                      FROM `@{GCP_PROJECT}.@{BQML_MODEL_DATASET_NAME}`.INFORMATION_SCHEMA.COLUMNS
                      WHERE table_name = '{% parameter selection_summary.input_data_view_name %}'
                      ) column_metadata
            ON column_stats.column_name = column_metadata.column_name
    ;;
  }


  parameter: input_data_view_name {
    type: unquoted
  }

  parameter: target_field_name {
    type: unquoted
  }

  dimension: target_column {
    type: string
    sql: '{% parameter target_field_name %}' ;;
    hidden: yes
  }

  dimension: column_name {
    primary_key: yes
    type: string
    sql: ${TABLE}.column_name ;;
  }

  dimension: count_nulls {
    type: number
    sql: ${TABLE}.count_nulls ;;
  }

  dimension: count_not_nulls {
    type: number
    sql: ${TABLE}.count_not_nulls ;;
  }

  dimension: pct_not_null {
    type: number
    hidden: yes
    sql: ${TABLE}.pct_not_null ;;
    value_format_name: percent_4
  }

  dimension: pct_null {
    type: number
    sql: 1 - ${pct_not_null} ;;
    value_format_name: percent_2
  }

  dimension: count_distinct_values {
    label: "Distinct Values"
    type: number
    sql: ${TABLE}.count_distinct_values ;;
  }

  dimension: pct_unique {
    type: number
    sql: ${TABLE}.pct_unique ;;
    value_format_name: percent_2
  }

  dimension: data_type {
    type: string
    sql: ${TABLE}.data_type ;;
  }

  dimension: _min_value {
    type: string
    sql: ${TABLE}._min_value ;;
  }

  dimension: _max_value {
    type: string
    sql: ${TABLE}._max_value ;;
  }

  dimension: _avg_value {
    type: number
    sql: ${TABLE}._avg_value ;;
  }

  dimension: input_data_column_count {
    type: number
    sql: ${TABLE}.input_data_column_count ;;
  }

  dimension: input_data_row_count {
    type: number
    sql: ${TABLE}.input_data_row_count ;;
  }
}

view: arima_selection_summary {
  derived_table: {
    sql:
    {% if arima_selection_summary.arimaTimeframe._parameter_value == 'minute' %}{% assign date_fmt = '%Y-%m-%d %H:%M' %}
    {% elsif arima_selection_summary.arimaTimeframe._parameter_value == 'hour' %}{% assign date_fmt = '%Y-%m-%d %H' %}
    {% elsif arima_selection_summary.arimaTimeframe._parameter_value == 'month' %}{% assign date_fmt = '%Y-%m' %}
    {% elsif arima_selection_summary.arimaTimeframe._parameter_value == 'quarter' %}{% assign date_fmt = '%Y-Q%Q' %}
    {% elsif arima_selection_summary.arimaTimeframe._parameter_value == 'year' %}{% assign date_fmt = '%Y' %}
    {% else %}{% assign date_fmt = '%Y-%m-%d' %}{% endif %}

    SELECT column_stats.column_name
            , column_metadata.data_type
            , column_metadata.input_data_column_count
            , column_stats.input_data_row_count
            , column_stats._min_value
            , column_stats._max_value
            , column_stats._avg_value

          FROM (SELECT column_name,
                  COUNT(0) AS input_data_row_count
                  , MIN(CASE WHEN '{% parameter arima_selection_summary.arimaTimeColumn %}' = column_name THEN PARSE_DATETIME('{{date_fmt}}', column_value) ELSE SAFE_CAST(column_value AS numeric) END) AS _min_value
                  , MAX(CASE WHEN '{% parameter arima_selection_summary.arimaTimeColumn %}' = column_name THEN PARSE_DATETIME('{{date_fmt}}', column_value) ELSE SAFE_CAST(column_value AS numeric) END) AS _max_value
                  , AVG(SAFE_CAST(column_value AS numeric)) AS _avg_value

                FROM (SELECT trim(column_name, '"') AS column_name
                        , IF(SAFE_CAST(column_value AS STRING)='null',NULL, column_value) AS column_value

                      FROM (SELECT REGEXP_REPLACE(TO_JSON_STRING(t), r'^{|}$', '') AS row_json
                            FROM `@{GCP_PROJECT}.@{BQML_MODEL_DATASET_NAME}.{% parameter arima_selection_summary.input_data_view_name %}` AS t ) table_AS_json
                            , UNNEST(SPLIT(row_json, ',"')) AS cols
                            , UNNEST([SPLIT(cols, ':')[SAFE_OFFSET(0)]]) AS column_name
                            , UNNEST([SPLIT(cols, ':')[SAFE_OFFSET(1)]]) AS column_value

                      ) AS col_val

                WHERE column_name <> '' AND column_name NOT LIKE '%-%'
                GROUP BY column_name
                ) AS column_stats

          INNER JOIN (SELECT table_catalog
                          , table_schema
                          , table_name
                          , column_name
                          , data_type
                          , count(0) over (partition by 1) AS input_data_column_count
                      FROM `@{GCP_PROJECT}.@{BQML_MODEL_DATASET_NAME}`.INFORMATION_SCHEMA.COLUMNS
                      WHERE table_name = '{% parameter arima_selection_summary.input_data_view_name %}'
                      ) column_metadata
            ON column_stats.column_name = column_metadata.column_name
    ;;
  }

  parameter: target_field_name {
    type: unquoted
  }

    parameter: arimaTimeColumn {
    type: unquoted
  }

  dimension: arimaTimeframe_dimension {
    type: string
    sql: '{% parameter arimaTimeframe %}' ;;
    #hidden: yes
  }

  # added to test with Tom
  parameter: arimaTimeframe {
    type: unquoted
  }

  parameter: input_data_view_name {
    type: unquoted
  }

  dimension: target_column {
    type: string
    sql: '{% parameter target_field_name %}' ;;
    hidden: yes
  }

  dimension: column_name {
    primary_key: yes
    type: string
    sql: ${TABLE}.column_name ;;
  }

  dimension: data_type {
    type: string
    sql: ${TABLE}.data_type ;;
  }

  dimension: _min_value {
    type: string
    sql: ${TABLE}._min_value ;;
  }

  dimension: _max_value {
    type: string
    sql: ${TABLE}._max_value ;;
  }

  dimension: _avg_value {
    type: number
    sql: ${TABLE}._avg_value ;;
  }

  dimension: input_data_column_count {
    type: number
    sql: ${TABLE}.input_data_column_count ;;
  }

  dimension: input_data_row_count {
    type: number
    sql: ${TABLE}.input_data_row_count ;;
  }


  }
