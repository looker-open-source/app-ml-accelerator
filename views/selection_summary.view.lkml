view: selection_summary {
  derived_table: {
    persist_for: "0 seconds"
    sql:
         SELECT column_stats.column_name
              , column_stats._nulls as count_nulls
              , column_stats._non_nulls as count_not_nulls
              , column_stats.corr_non_nulls as count_corr_not_nulls
              , column_stats.pct_not_null as pct_not_null
              , column_stats.count_distinct_values
              , column_stats.pct_unique
              , column_metadata.data_type
              , column_stats.* EXCEPT (table_catalog,
                                       table_schema,
                                       table_name,
                                       column_name,
                                       _nulls,
                                       _non_nulls,
                                       pct_not_null,
                                       table_rows,
                                       pct_unique,
                                       count_distinct_values)
         FROM (
          SELECT * FROM (
            WITH `table` AS (SELECT * FROM `@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}` )
                , corr_table as (SELECT * FROM `table` where {% parameter selection_summary.target_field_name %} is not null)
                , table_as_json AS (SELECT REGEXP_REPLACE(TO_JSON_STRING(t), r'^{|}$', '') AS ROW FROM `table` AS t )
                , corr_table_as_json AS (SELECT REGEXP_REPLACE(TO_JSON_STRING(t), r'^{|}$', '') AS ROW FROM corr_table AS t)
                , pairs AS (SELECT REPLACE(column_name, '"', '') AS column_name
                                 , IF (SAFE_CAST(column_value AS STRING)='null',NULL, column_value) AS column_value
                            FROM table_as_json,UNNEST(SPLIT(ROW, ',"')) AS z,UNNEST([SPLIT(z, ':')[SAFE_OFFSET(0)]]) AS column_name
                                ,UNNEST([SPLIT(z, ':')[SAFE_OFFSET(1)]]) AS column_value )
                , corr_pairs as (SELECT REPLACE(column_name, '"', '') AS column_name
                                 , IF (SAFE_CAST(column_value AS STRING)='null',NULL, column_value) AS column_value
                            FROM corr_table_as_json,UNNEST(SPLIT(ROW, ',"')) AS z,UNNEST([SPLIT(z, ':')[SAFE_OFFSET(0)]]) AS column_name
                                ,UNNEST([SPLIT(z, ':')[SAFE_OFFSET(1)]]) AS column_value )
                , corr_profile AS (
                    SELECT split(replace('`@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}`','`',''),'.' )[safe_offset(0)] as table_catalog,
                           split(replace('`@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}`','`',''),'.' )[safe_offset(1)] as table_schema,
                           split(replace('`@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}`','`',''),'.' )[safe_offset(2)] as table_name,
                           column_name,
                           COUNTIF(column_value IS NOT NULL) AS corr_non_nulls,
                    FROM corr_pairs
                    WHERE column_name <> ''
                      AND column_name NOT LIKE '%-%'
                    GROUP BY column_name
                    ORDER BY column_name)
                , profile AS (
                    SELECT
                      split(replace('`@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}`','`',''),'.' )[safe_offset(0)] as table_catalog,
                      split(replace('`@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}`','`',''),'.' )[safe_offset(1)] as table_schema,
                      split(replace('`@{GCP_PROJECT}.@{bqml_model_dataset_name}.{% parameter selection_summary.input_data_view_name %}`','`',''),'.' )[safe_offset(2)] as table_name,
                      column_name,
                      COUNT(*) AS table_rows,
                      COUNT(DISTINCT column_value) AS count_distinct_values,
                      safe_divide(COUNT(DISTINCT column_value),COUNT(*)) AS pct_unique,
                      COUNTIF(column_value IS NULL) AS _nulls,
                      COUNTIF(column_value IS NOT NULL) AS _non_nulls,
                      COUNTIF(column_value IS NOT NULL) / COUNT(*) AS pct_not_null,
                      min(column_value) as _min_value,
                      max(column_value) as _max_value,
                      avg(SAFE_CAST(column_value AS numeric)) as _avg_value
                    FROM
                      pairs
                    WHERE
                      column_name <> ''
                      AND column_name NOT LIKE '%-%'
                      GROUP BY
                      column_name
                    ORDER BY
                      column_name)
            select p.*, corr_p.corr_non_nulls
            from profile p
            left join corr_profile corr_p
              on p.table_catalog = corr_p.table_catalog
              and p.table_schema = corr_p.table_schema
              and p.table_name = corr_p.table_name
              and p.column_name = corr_p.column_name)
         ) column_stats
         LEFT OUTER JOIN (
          SELECT table_catalog
              ,  table_schema
              ,  table_name
              ,  column_name
              ,  data_type
          FROM
            `@{GCP_PROJECT}.@{bqml_model_dataset_name}`.INFORMATION_SCHEMA.COLUMNS
        ) column_metadata
        ON  column_stats.table_catalog = column_metadata.table_catalog
        AND column_stats.table_schema = column_metadata.table_schema
        AND column_stats.table_name = column_metadata.table_name
        AND column_stats.column_name = column_metadata.column_name
        ;;
  }

  parameter: input_data_view_name {
    # Model Name + "_input_data"
    type: unquoted
    default_value: "bqml_accelerator_input_data"
  }

  parameter: target_field_name {
    type: unquoted
    default_value: "income_bracket"
  }

  dimension: target_column {
    type: string
    sql: '{% parameter target_field_name %}' ;;
    hidden: yes
  }

  dimension: column_name {
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

  dimension: count_corr_not_nulls {
    type: number
    sql: ${TABLE}.count_corr_not_nulls ;;
    hidden: yes
  }

  dimension: target_correlation {
    type: number
    sql: ${count_corr_not_nulls}/nullif(${count_not_nulls},0) ;;
    value_format_name: percent_2
  }

  dimension: pct_not_null {
    type: number
    hidden: yes
    sql: ${TABLE}.pct_not_null ;;
    value_format_name: percent_2
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
}
