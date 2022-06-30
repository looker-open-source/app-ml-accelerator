include: "/views/bqml_type/boosted_tree.view"

explore: boosted_tree {
  hidden: yes

  join: boosted_tree_feature_info {
    type: cross
    relationship: many_to_many
  }

  join: boosted_tree_training_info {
    type: cross
    relationship: many_to_many
  }

  join: boosted_tree_evaluate {
    type: cross
    relationship: many_to_many
    fields: [boosted_tree_evaluate.classifier*, boosted_tree_evaluate.regressor*]
  }

  join: boosted_tree_predict {
    type: cross
    relationship: many_to_many
  }
}
