view: kmeans {
## KMEANS Core
## Place Parameters Here

  parameter: model_name {
    type: unquoted
    hidden: no
  }

  ## Pre Training Parameters/Future Options
  parameter: num_clusters {
    type: unquoted
    default_value: "" ## int64_value
  }
  parameter: kmeans_init_method {
    type: unquoted
    default_value: "RANDOM" ## { 'RANDOM' | 'KMEANS++' | 'CUSTOM' },
  }
  parameter: kmeans_init_col {
    type: unquoted
    default_value: "" ## string_value
  }
  parameter: distance_type {
    type: unquoted
    default_value: "EUCLIDEAN" ## { 'EUCLIDEAN' | 'COSINE' }
  }
  parameter: standardize_features {
    type: unquoted
    default_value: "TRUE" ## { TRUE | FALSE }
  }
  parameter: max_iterations {
    type: unquoted
    default_value: "20" ## int64_value
  }
  parameter: early_stop {
    type: unquoted
    default_value: "TRUE" ## { TRUE | FALSE }
  }
  parameter: min_rel_progress {
    type: unquoted
    default_value: "0.01" ## float64_value
  }
  parameter: warm_start {
    type: unquoted
    default_value: "FALSE" ## { TRUE | FALSE }
  }
}


## Model Creation Phase

## view: k_means_trial_info

view: k_means_predict {
  label: "Predictions"

  sql_table_name: ML.PREDICT(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter kmeans.model_name %}_k_means_model_{{ _explore._name }},
                      TABLE @{BQML_MODEL_DATASET_NAME}.{% parameter kmeans.model_name %}_input_data
                    )
  ;;

    dimension: item_id {
      primary_key: yes
      type: string
      sql: ${TABLE}.item_id ;;
    }

    dimension: centroid_id {
      label: "Nearest Centroid"
      type: number
      sql: ${TABLE}.CENTROID_ID ;;
    }

    dimension: nearest_centroids_distance {
      hidden: yes
      type: string
      sql: ${TABLE}.NEAREST_CENTROIDS_DISTANCE ;;
    }

    measure: item_count {
      label: "Count of Observations"
      type: count
      description: "Number of Observations"
    }

    measure: item_count_percent_of_total {
      label: "Percent of Total Observations"
      type: percent_of_total
      description: "Percent of Total Observations in Data Set"
      sql: ${item_count} ;;
    }

    measure: total_item_count {
      type: number
      label: "Total Observations in Data Set"
      description: "Total Number of Observations in Data Set"
      sql: (select count(item_id) from ${k_means_predict.SQL_TABLE_NAME}) ;;
    }

  }
  view: nearest_centroids_distance {
    label: "[7] BQML: Predictions"

    dimension: item_centroid_id {
      hidden: yes
      primary_key: yes
      sql: CONCAT(${k_means_predict.item_id}, ${centroid_id}) ;;
    }

    dimension: centroid_id {
      group_label: "Centroid Distances"
      label: "Centroid"
      type: number
      sql: ${TABLE}.CENTROID_ID ;;
    }

    dimension: distance {
      group_label: "Centroid Distances"
      type: number
      sql: ${TABLE}.DISTANCE ;;
    }
  }
  #find number of observations by centroid and compute % of Total for use as a weighting value for overall averages
  view: k_means_centroid_item_count {
    label: "Centroids"

    derived_table: {
      sql:  SELECT centroid_id
                , item_count
                , item_count / sum(item_count) OVER () AS item_pct_total
              FROM (SELECT CENTROID_ID AS centroid_id
                    , count(distinct item_id) AS item_count
                    FROM ${k_means_predict.SQL_TABLE_NAME}
                    GROUP BY 1) a
        ;;
    }

    dimension: centroid_id {
      hidden: yes
      primary_key: yes
    }

    dimension: item_count {
      label: "Count of Observations"
      description: "Number of Observations in Centroid"
      type: number
    }

    dimension: item_pct_total {
      label: "Percent of Total Observations"
      description: "Centroid's Percent of Total Observations"
      type: number
      sql: ${TABLE}.item_pct_total ;;
      value_format_name: percent_1
    }
  }

  view: k_means_evaluate {
    label: "Evaluation Metrics"

    sql_table_name: ML.EVALUATE(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter model_name.select_model_name %}_k_means_model_{{ _explore._name }}) ;;

    dimension: davies_bouldin_index {
      type: number
      description: "The lower the value, the better the separation of the centroids and the 'tightness' inside the centroids. If creating multiple versions of a model with different number of clusters, the version which minimizes the Davies-Boudin Index is considered best."
      sql: ${TABLE}.davies_bouldin_index ;;
      value_format_name: decimal_4
    }

    dimension: mean_squared_distance {
      type: number
      description: "The lower the value, the better the cluster solution. A goal of k-means clustering is to minimize the distance of any data point and its cluster center (the 'tightness' inside centroids)."
      sql: ${TABLE}.mean_squared_distance ;;
      value_format_name: decimal_4
    }
  }
  view: k_means_evaluate_create {
    derived_table: {
      create_process: {
        sql_step: CREATE TABLE IF NOT EXISTS @{BQML_MODEL_DATASET_NAME}.{% parameter model_name.select_model_name %}_k_means_evaluation_metrics_{{ _explore._name }}
              (item_id              STRING,
              features              STRING,
              number_of_clusters    STRING,
              created_at            TIMESTAMP,
              davies_bouldin_index  FLOAT64,
              mean_squared_distance FLOAT64)
              ;;

          sql_step: MERGE @{BQML_MODEL_DATASET_NAME}.{% parameter model_name.select_model_name %}_k_means_evaluation_metrics_{{ _explore._name }} AS T
                USING (SELECT  '{% parameter k_means_training_data.select_item_id %}' AS item_id,
                {% assign features = _filters['k_means_training_data.select_features'] | sql_quote | remove: '"' | remove: "'" %}
                '{{ features }}' AS features,
                '{% parameter k_means_hyper_params.choose_number_of_clusters %}' AS number_of_clusters,
                CURRENT_TIMESTAMP AS created_at,
                davies_bouldin_index,
                mean_squared_distance
                FROM ML.EVALUATE(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter model_name.select_model_name %}_k_means_model_{{ _explore._name }})
                ) AS S
                ON T.item_id = S.item_id AND T.features = S.features AND T.number_of_clusters = S.number_of_clusters
                WHEN MATCHED THEN
                UPDATE SET created_at=S.created_at
                , davies_bouldin_index=S.davies_bouldin_index
                , mean_squared_distance=S.mean_squared_distance
                WHEN NOT MATCHED THEN
                INSERT (item_id,
                features,
                number_of_clusters,
                created_at,
                davies_bouldin_index,
                mean_squared_distance)
                VALUES(item_id,
                features,
                number_of_clusters,
                created_at,
                davies_bouldin_index,
                mean_squared_distance) ;;
        }
      }
    }
    view: k_means_evaluate_history {
      label: "[6] BQML: Evaluation Metrics"

      sql_table_name: @{BQML_MODEL_DATASET_NAME}.{% parameter model_name.select_model_name %}_k_means_evaluation_metrics_{{ _explore._name }} ;;

      dimension: item_id {
        group_label: "Metric History"
        type: string
        description: "Item or observation which was clustered."
        sql: ${TABLE}.item_id ;;
      }

      dimension: features {
        group_label: "Metric History"
        type: string
        description: "Metrics or attributes used to create the clusters"
        sql: ${TABLE}.features ;;
      }

      dimension: number_of_clusters {
        group_label: "Metric History"
        type: string
        sql: ${TABLE}.number_of_clusters ;;
      }

      dimension_group: created_at {
        group_label: "Metric History"
        type: time
        timeframes: [raw, time]
        sql: ${TABLE}.created_at ;;
      }

      dimension: davies_bouldin_index {
        group_label: "Metric History"
        type: number
        description: "The lower the value, the better the separation of the centroids and the 'tightness' inside the centroids. If creating multiple versions of a model with different number of clusters, the version which minimizes the Davies-Boudin Index is considered best."
        sql: ${TABLE}.davies_bouldin_index ;;
        value_format_name: decimal_4
      }

      dimension: mean_squared_distance {
        group_label: "Metric History"
        type: number
        description: "The lower the value, the better the cluster solution. A goal of k-means clustering is to minimize the distance of any data point and its cluster center (the 'tightness' inside centroids)."
        sql: ${TABLE}.mean_squared_distance ;;
        value_format_name: decimal_4
      }
    }

    view: k_means_centroids {
      label: "Centroids"

      sql_table_name: ML.CENTROIDS(MODEL @{BQML_MODEL_DATASET_NAME}.{% parameter model_name.select_model_name %}_k_means_model_{{ _explore._name }}) ;;

      dimension: centroid_id {
        hidden: yes
        primary_key: yes
        type: number
        sql: coalesce(${TABLE}.centroid_id,0) ;;
      }

      dimension: feature {
        hidden: yes
        type: string
        sql: ${TABLE}.feature ;;
      }

      dimension: numerical_value {
        hidden: yes
        type: number
        sql: ${TABLE}.numerical_value ;;
      }

      dimension: categorical_value {
        hidden: yes
        type: string
        sql: ${TABLE}.categorical_value ;;
      }
    }
    view: categorical_value {
      label: "Centroids"

      dimension: centroid_category_id {
        hidden: yes
        primary_key: yes
        sql: CONCAT(${k_means_centroids.centroid_id}, ${k_means_centroids.feature}, coalesce(${category},'n/a')) ;;
      }

      dimension: category {
        hidden: yes
      }

      dimension: value {
        hidden: yes
      }

      dimension: feature_category {
        label: "Feature and Category"
        type: string
        hidden: yes #user will select from k_means_centroid_profiles
        sql:  CONCAT(${k_means_centroids.feature},
            CASE
              WHEN ${category} IS NOT NULL THEN CONCAT(': ', ${category})
              ELSE ''
            END) ;;
      }

      dimension: feature_category_value {
        hidden: yes
        label: "Value"
        description: "Nearest Centroid Average Value"
        type: number
        sql: COALESCE(${k_means_centroids.numerical_value}, ${value}) ;;
      }
    }

    ############################################################################################################################
    # Logic to generate the weighted average mean for each feature_category in k-means model
    # Then compare each centroid to that weighted average and compute percent difference from average and index value to average
    # Values can then be used in visualization to highlight the differences
    # also UNION the overall weighted average to the Centroids Profile with centroid_id = 0
    ############################################################################################################################

    #combine centroid values from numerical and categorical variables
    view: k_means_centroid_feature_category {
      derived_table: {
        sql:  SELECT k_means_centroids.centroid_id AS centroid_id
            , CONCAT(k_means_centroids.feature,
            CASE
            WHEN categorical_value.category IS NOT NULL THEN CONCAT(': ', categorical_value.category)
            ELSE ''
            END) AS feature_category
            , COALESCE(k_means_centroids.numerical_value, categorical_value.value) AS value
            , case when categorical_value.category IS NOT NULL then 1 else 0 end as is_categorical
            FROM ${k_means_centroids.SQL_TABLE_NAME} AS k_means_centroids
            LEFT JOIN UNNEST(k_means_centroids.categorical_value) as categorical_value
      ;;
      }
    }



    #find the weighted average value by feature_category (weight each centroid by % of total in training set)
    view: k_means_overall_feature_category {
      derived_table: {
        sql:
        select
          0 as centroid_id
          ,cfc.feature_category
          ,cfc.is_categorical
          ,sum(cfc.value * cc.item_pct_total) as value
          ,max(cc.item_count) as item_count
        from ${k_means_centroid_feature_category.SQL_TABLE_NAME} as cfc
        join ${k_means_centroid_item_count.SQL_TABLE_NAME} as cc on cfc.centroid_id = cc.centroid_id
        group by 1,2, 3
        ;;
      }
    }

    view: k_means_centroids_indexed_values {
      label: "Centroids"

      derived_table: {
        sql:  SELECT k_means_centroid_feature_category.centroid_id AS centroid_id
                  , k_means_centroid_feature_category.feature_category AS feature_category
                  , k_means_centroid_feature_category.value AS value
                  , k_means_centroid_feature_category.is_categorical as is_categorical
                  , 100 * (value / SUM(value * k_means_centroid_item_count.item_pct_total) OVER (PARTITION BY k_means_centroid_feature_category.feature_category)) AS index_to_weighted_avg
                  , (value / SUM(value * k_means_centroid_item_count.item_pct_total) OVER (PARTITION BY k_means_centroid_feature_category.feature_category)) - 1 AS pct_diff_from_training_set_weighted_avg
            FROM ${k_means_centroid_feature_category.SQL_TABLE_NAME} AS k_means_centroid_feature_category
            LEFT JOIN ${k_means_centroid_item_count.SQL_TABLE_NAME} AS k_means_centroid_item_count
              ON k_means_centroid_feature_category.centroid_id = k_means_centroid_item_count.centroid_id

            UNION ALL
               select centroid_id
                      ,feature_category
                      ,value
                      ,is_categorical
                      ,100 as index_to_avg
                      ,0 as pct_diff_from_avg
               from ${k_means_overall_feature_category.SQL_TABLE_NAME}
      ;;
      }

      dimension: pk {
        hidden: yes
        primary_key: yes
        sql: CONCAT(${centroid_id}, ${feature_category}) ;;
      }

      dimension: centroid_id {
        hidden: yes
      }

      dimension: centroid_id_label {
        label: "Centroid ID"
        description: "Centroid ID including Overall for Comparison"
        type: string
        sql: case when ${centroid_id} = 0 then "Overall Weighted Average" else cast(${centroid_id} as string) end ;;
      }

      dimension: centroid_id_label_with_pct_of_total {
        label: "Centroid ID (with % of Total)"
        description: "Centroid ID (xx.x% of Total)"
        type: string
        sql: case when ${centroid_id} = 0 then "Overall Weighted Average" else cast(${centroid_id} as string) end ;;
        html: {% if centroid_id._value == 0 %}
            {{rendered_value}}
                  {% else %}
                <a style="color:#003f5c;font-size:16px"> <b> {{rendered_value}} </b> </a>     <a style="font-size: 10px">({{ k_means_centroid_item_count.item_pct_total._rendered_value }})
                  {% endif %};;
      }

      dimension: feature_category {
        hidden: no
        label: "Feature and Category"
      }

      dimension: is_categorical {
        type: yesno
        hidden: yes
        sql: ${TABLE}.is_categorical = 1 ;;
      }
      dimension: value {
        type: number
        hidden: yes
      }
      dimension: index_to_weighted_avg {
        type: number
        description: "(Centroid Average / Traning Set Weighted Average) * 100"
        hidden: yes
      }

      dimension: pct_diff_from_training_set_weighted_avg {
        type: number
        hidden: yes
        label: "Percent Difference from Training Set Average"
        description: "(Centroid Average / Training Set Weighted Average) - 1"
        value_format_name: percent_2
      }

      measure: pct_diff_from_weighted_avg {
        label: "Percent Difference from Training Set Average"
        type: average
        description: "(Centroid Average / Training Set Weighted Average) - 1"
        sql: ${pct_diff_from_training_set_weighted_avg} ;;
        value_format_name: percent_1
      }

      measure: average_value {
        type: average
        label: "Centroid Average"
        sql: case when ${is_categorical} then ${value} * 100
          else ${value} end;;
        value_format_name: decimal_2
      }

      #for highlight chart, plot pct_diff_from_avg but display average_value._rendered_value
      measure: average_value_highlight {
        label: "Centroid Average (for conditional formatting)"
        description: "Use to Highlight which features are driving each cluster. Centroid value is displayed while underlying value is Percent Difference from Weighted Average. Use Percent Difference from Average in Table Conditional Formatting to highlight differences."
        type: average
        sql: ${pct_diff_from_training_set_weighted_avg} ;;
        html: {% if is_categorical._value == 'Yes' %}{{ average_value._rendered_value | round:1 }}%
          {% else %} {{ average_value._rendered_value }}
          {% endif %}
      ;;
      }

    }