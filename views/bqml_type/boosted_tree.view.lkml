include: "/views/info_base.view"
include: "/views/evaluate_base.view"

view: boosted_tree {
  derived_table: { sql: SELECT '{% parameter boosted_tree.model_name %}' as model_name_field ;; }
## Boosted Tree Core
## Place Parameters Here

  parameter: model_name {
    type: unquoted
    hidden: no
  }
  parameter: model_type {
    type: unquoted
    default_value: "BOOSTED_TREE_CLASSIFIER" ## { 'BOOSTED_TREE_CLASSIFIER' | 'BOOSTED_TREE_REGRESSOR' }
  }

  ## Pre Training Parameters/Future Options
  parameter: booster_type {
    type: unquoted
    default_value: "GBTREE" # {'GBTREE' | 'DART'}
  }
  parameter: num_parallel_tree {
    type: unquoted
    default_value: "1" # int64_value
  }
  parameter: dart_normalize_type {
    type: unquoted
    default_value: "TREE" # {'TREE' | 'FOREST'}
  }
  parameter: tree_method {
    type: unquoted
    default_value: "AUTO" # {'AUTO' | 'EXACT' | 'APPROX' | 'HIST'}
  }
  parameter: min_tree_child_weight {
    type: unquoted
    default_value: "1" # int64_value
  }
  parameter: colsample_bytree {
    type: unquoted
    default_value: "1" # int64_value
  }
  parameter: colsample_bylevel {
    type: unquoted
    default_value: "1" # int64_value
  }
  parameter: colsample_bynode {
    type: unquoted
    default_value: "1" # int64_value
  }
  parameter: min_split_loss {
    type: unquoted
    default_value: "0" # int64_value
  }
  parameter: max_tree_depth {
    type: unquoted
    default_value: "6" # int64_value
  }
  parameter: subsample {
    type: unquoted
    default_value: "1.0"
  }
  parameter: auto_class_weights {
    type: unquoted
    default_value: "TRUE" # { TRUE | FALSE }
  }
  parameter: class_weights {
    type: unquoted
    default_value: "" # [STRUCT('example_label', .2)]
    # Can't be used when auto_class_weights = TRUE
  }
  parameter: l1_reg {
    type: unquoted
    default_value: "0" # float64_value
  }
  parameter: l2_reg {
    type: unquoted
    default_value: "0" # float64_value
  }
  parameter: early_stop {
    type: unquoted
    default_value: "TRUE" # { TRUE | FALSE }
  }
  parameter: learn_rate {
    type: unquoted
    default_value: "0.3" # float64_value
  }
  parameter: max_iterations {
    type: unquoted
    default_value: "20" # int64_value
  }
  parameter: min_rel_progress {
    type: unquoted
    default_value: "0.01" # float64_value
  }
  parameter: data_split_method {
    type: unquoted
    default_value: "AUTO_SPLIT" # { 'AUTO_SPLIT' | 'RANDOM' | 'CUSTOM' | 'SEQ' | 'NO_SPLIT' }
  }
  parameter: data_split_eval_fraction {
    type: unquoted
    default_value: "0.2" # float64_value
    ## Only used when data_split_method = 'RANDOM'|'SEQ'
  }
  parameter: data_split_col {
    type: unquoted
    default_value: "" # string_value
    ## Only used when data_split_method = 'CUSTOM'|'SEQ'
  }
  parameter: enable_global_explain {
    type: unquoted
    default_value: "FALSE" # { TRUE | FALSE }
  }

}


## Model Creation Phase


## Trial Info only usable when model has been trained with Hyperparameter tuning options
# view: boosted_tree_trial_info {
#   extends: [trial_info_base]
#   sql_table_name: ML.TRIAL_INFO(MODEL @{bqml_model_dataset_name}.{% parameter boosted_tree.model_name %}) ;;
# }

view: boosted_tree_feature_info {
  extends: [feature_info_base]
  sql_table_name: ML.FEATURE_INFO(MODEL @{bqml_model_dataset_name}.{% parameter boosted_tree.model_name %}) ;;
}

view: boosted_tree_training_info {
  extends: [training_info_base]
  sql_table_name: ML.TRAINING_INFO(MODEL @{bqml_model_dataset_name}.{% parameter boosted_tree.model_name %}) ;;
}

## Model Use Phase
view: boosted_tree_evaluate {
  label: "Evaluation Metrics"
  extends: [evaluate_base]

  sql_table_name: ML.EVALUATE(MODEL @{bqml_model_dataset_name}.{% parameter boosted_tree.model_name %}) ;;
}

view: boosted_tree_predict {

}
