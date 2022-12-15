# Machine Learning Accelerator

### SETUP INSTRUCTIONS

After adding these files to your application in Looker, there are some values that need to be set.

In the `manifest.lkml` file:

1. Set value for the `CONNECTION_NAME` constant

1. Add the following user attributes to your Looker instance:

   - `bigquery_connection_name`
   - `client_id`
   - `bqml_model_dataset_name`
   - `gcp_project`

1. (Optional) If you plan to use a service account for BigQuery auth:

   1. Set these user attributes:

      - `looker_client_id`
      - `looker_client_secret`
      - `access_token_server_endpoint`

   1. Add your access token server's URL to the `external_api_urls` entitlements list.

1. (Optional, for developing) Comment out the `file` property and set a `url` property to the url of your bundle.js, either localhost or wherever you are hosting the code.
