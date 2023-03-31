project_name: "app-ml-accelerator"

application: ml-accelerator {
  label: "Machine Learning Accelerator"
  file: "bundle.js"
  sri_hash: "jujWtES/3qvYhDWBkJzE3dgph4Y7iJ6CWnshRq3Cb9KfhNf5OXuit4bgITXEc0bH"
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
    new_window_external_urls: ["https://developers.google.com/machine-learning/glossary", "https://cloud.google.com/vertex-ai/docs/model-registry/introduction"]
    scoped_user_attributes: [
      "app_ml_accelerator_bigquery_connection_name",
      "app_ml_accelerator_bqml_model_dataset_name",
      "app_ml_accelerator_gcp_project",
    ]
  }
}

constant: CONNECTION_NAME {
  value: "bigquery_public_data_looker"
  export: override_required
}

constant: BQML_MODEL_DATASET_NAME {
  value: "looker_scratch"
  export: none
}

constant: GCP_PROJECT {
  value: "{{_user_attributes['app_ml_accelerator_gcp_project']}}"
  export: none
}
