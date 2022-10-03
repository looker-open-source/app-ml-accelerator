project_name: "app-bqml-accelerator"

application: bqml-accelerator {
  label: "BQML Accelerator"
  # file: "bundle.js"
  url: "http://localhost:8080/bundle.js"
  entitlements: {
    use_form_submit: yes
    use_embeds: yes
    use_iframes: yes
    scoped_user_attributes: [
      "bigquery_connection_name",
      "google_client_id",
      "bqml_model_dataset_name",
      "gcp_project",
      "looker_client_id",
      "looker_client_secret",
      "access_token_server_endpoint"
    ]
      core_api_methods: ["all_lookml_models", "create_query", "run_query", "lookml_model_explore", "model_fieldname_suggestions", "me", "user_attribute_user_values", "create_sql_query"]
      external_api_urls: ["https://bigquery.googleapis.com", "https://bqml-accelerator.uw.r.appspot.com"]
      oauth2_urls: ["https://accounts.google.com/o/oauth2/v2/auth"]
    }
}

constant: CONNECTION_NAME {
  value: "bigquery"
  export: override_required
}

constant: BQML_MODEL_DATASET_NAME {
  value: "{{_user_attributes['bqml_model_dataset_name']}}"
}

constant: GCP_PROJECT {
  value: "{{_user_attributes['gcp_project']}}"
}
