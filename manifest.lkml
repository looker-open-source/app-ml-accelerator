project_name: "marketplace_bqml_ext"

application: ml-accelerator {
  label: "Machine Learning Accelerator"
  file: "bundle.js"
  sri_hash: "Bf330NOp0B0RK3lAsFPd0mY2/wLNeuhSEnqz/e/vtX97ZDZX2P7HQSHOBMvQQn1V"
  entitlements: {
    core_api_methods: [
      "all_lookml_models",
      "create_query",
      "run_query",
      "lookml_model_explore",
      "model_fieldname_suggestions",
      "me",
      "user_attribute_user_values",
      "create_sql_query",
      "run_sql_query"
    ]

    use_form_submit: yes
    use_embeds: yes
    use_iframes: yes
    new_window: yes
    new_window_external_urls: ["https://en.wikipedia.org/wiki", "https://developers.google.com/machine-learning/glossary", "https://cloud.google.com/vertex-ai/docs/model-registry/introduction"]
    scoped_user_attributes: [
      "bigquery_connection_name",
      "bqml_model_dataset_name",
      "generate_text_model_name",
      "gcp_project",
    ]
  }
}

constant: CONNECTION_NAME {
  value: "ml-accelerator"
  export: override_required
}

constant: GCP_PROJECT {
  value: "{{_user_attributes['marketplace_bqml_ext_ml_accelerator_gcp_project']}}"
}

constant: BQML_MODEL_DATASET_NAME {
  value: "{{_user_attributes['marketplace_bqml_ext_ml_accelerator_bqml_model_dataset_name']}}"
}

constant: GENERATE_TEXT_MODEL_NAME {
  value: "{{_user_attributes['marketplace_bqml_ext_ml_accelerator_generate_text_model_name']}}"
}
# First create an LLM model in the same dataset as specified in constant "BQML_MODEL_DATASET_NAME", then provide model name here
# https://cloud.google.com/bigquery/docs/generate-text
# Also, modify the service account used for the connection to obtain a new permission: bigquery.connections.use
# This is available to users with role Bigquery Connection User (https://cloud.google.com/iam/docs/understanding-roles#bigquery.connectionUser)


