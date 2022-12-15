# Machine Learning Accelerator

The Machine Learning Accelerator is an application built on Looker's extension framework that provides a no-code user interface for creating machine learning models using BigQuery and Vertex AI.

### SETUP INSTRUCTIONS

After adding these files to your application in Looker, there are some values that need to be set.

1. [Install this application from Looker Marketplace](https://cloud.google.com/looker/docs/marketplace#installing_a_tool_from_the_marketplace) or [manually create a new LookML project](https://cloud.google.com/looker/docs/create-projects#cloning_a_public_git_repository) using this repository.

   *If installing manually, update the `CONNECTION_NAME` constant in the `manifest.lkml` file with a Looker database connection name for BigQuery.*

2. Create the following user attributes for storing application configuration settings. These settings will be used by the application to create BigQuery objects, including views, tables and ML models. The connection name user attribute value must match the  CONNECTION_NAME LookML constant value.

   - `app_bqml_accelerator_bigquery_connection_name`
   - `app_bqml_accelerator_gcp_project`
   - `app_bqml_accelerator_bqml_model_dataset_name`
