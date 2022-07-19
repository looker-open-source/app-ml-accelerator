project_name: "app_bqml_accelerator"

application: bqml-accelerator {
  label: "BQML Accelerator"
  file: "bundle.js"
  entitlements: {
    core_api_methods: ["all_lookml_models", "create_query", "run_query", "lookml_model_explore", "model_fieldname_suggestions", "me", "user_attribute_user_values"]
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
    external_api_urls: ["https://bigquery.googleapis.com","https://looker-machine-learning.wl.r.appspot.com"]
    oauth2_urls: ["https://accounts.google.com/o/oauth2/v2/auth"]
  }
}

constant: CONNECTION_NAME {
  value: "bqml_accelerator"
  export: override_required
}

constant: bqml_model_dataset_name {
  value: "{{_user_attributes['bqml_model_dataset_name']}}"
  export: override_required
}

constant: GCP_PROJECT {
  value: "{{_user_attributes['gcp_project']}}"
  export: override_required
}
