# Machine Learning Accelerator

The ML Accelerator is a purpose-built Looker application designed to give business users access to BigQuery and Vertex AI's machine learning capabilities. It provides a user-friendly interface designed to guide the user through each step of creating a machine learning model. Because of its simple, no-code interface, the application serves as a pathway for business analysts to learn and use predictive analytics in Looker.

View the [ML Model Creation Flow](https://github.com/looker-open-source/app-ml-accelerator/blob/main/ML_Model_Creation_Flow.md) document for an example of an end-to-end user journey.

#### **IMPORTANT**

**Additional configuration is required after installation. A Looker Admin should complete the application configuration using the Installation Instructions below.**

Report bugs or feature requests with [this form](https://docs.google.com/forms/d/e/1FAIpQLSd97ptoU3TUuasZeFjSBHT9FQiyrDzjHUm7NTspEjz5kwNSAA/viewform). Contact [ml-accelerator-feedback@google.com](mailto:ml-accelerator-feedback@google.com) with questions or comments.

---

### INSTALLATION INSTRUCTIONS

#### 1. Choose a BigQuery Connection

You will need to select a BigQuery connection during installation. The application can only be used with a single connection to prevent data from moving between connections. The connection chosen will determine which Looker Explores will be accessible from within the application.

#### 2. Adjust Service Account Roles

The service account used by the BigQuery connection chosen in Step 1 should have the following IAM predefined roles.
  - BigQuery Data Editor
  - BigQuery Job User
  - Vertex AI User

#### 3. Create BigQuery Dataset for ML Models

Create a dataset (e.g., `looker_bqml`) in the BigQuery connection's GCP project.

#### 4. Install Application

The application can be installed directly from [Looker Marketplace](https://marketplace.looker.com/) (recommended) or manually installed following the steps below.

  ##### Option A: Marketplace Install
  Refer to the [Looker Docs for installing a tool from Marketplace](https://cloud.google.com/looker/docs/marketplace#installing_a_tool_from_the_marketplace). Select the BigQuery connection name chosen in Step 1 during installation.

  ##### Option B: Manual Install
  - [Fork this GitHub repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo#forking-a-repository)
  - [Create a blank LookML project](https://cloud.google.com/looker/docs/create-projects#creating_a_blank_project) named `marketplace_bqml_ext`

      **IMPORTANT: The LookML project must be named `marketplace_bqml_ext`**

  - [Connect the new LookML project to the forked repository](https://cloud.google.com/looker/docs/setting-up-git-connection)
  - Update the value of the CONNECTION_NAME constant in the `manifest.lkml` file
  - [Commit and deploy changes to production](https://cloud.google.com/looker/docs/version-control-and-deploying-changes#getting_your_changes_to_production)

#### 5. Configure Application with User Attributes

The application uses three [Looker user attributes](https://cloud.google.com/looker/docs/admin-panel-users-user-attributes) to store its configuration settings. The following user attributes are required for the application to work properly. Each user attribute needs to be named exactly as listed below with a data type of `String`. The recommended setting for user access is `View`.

Create the following user attributes and set their default values.

  | **Required User Attribute Name**                                | **Default Value Description**                                     |
  |-----------------------------------------------------------------|-------------------------------------------------------------------|
  | marketplace_bqml_ext_ml_accelerator_bigquery_connection_name    | Connection name chosen in Step 1                                  |
  | marketplace_bqml_ext_ml_accelerator_gcp_project                 | Projectd ID of the BigQuery dataset created in Step 3             |
  | marketplace_bqml_ext_ml_accelerator_bqml_model_dataset_name     | Name of BigQuery dataset created in Step 3 (e.g., `looker_bqml`)  |

#### 6. Create a Looker Role to Manage User Access

The application is designed for users with access to Explores and SQL Runner in Looker. Users will need the following permissions to use the application.
  - `explore`
  - `use_sql_runner`

We recommend creating a new Looker role to easily manage user access to the application and guarantee users have the required permissions above.
  - Create a new Looker model set named `ML Accelerator` containing the LookML model `ml_accelerator`
  - Create a new Looker permission set named `ML Accelerator` containing all the permisions in the [default User permission set](https://cloud.google.com/looker/docs/admin-panel-users-roles#default_permission_sets) AND the `use_sql_runner` permission
  - Create a new Looker role named `ML Accelerator` using the new model and permission set
  - Assign the `ML Accelerator` role to Looker users and groups

#### 7. Setup AI-Generated Model Evaluation Summaries

After release 2.2, the application can use text generating AI to summarize the model evaluation to more clearly communicate model performance. This optional feature requires additional setup.

  ##### 7a: Add an External Connection from Bigquery to Vertex
  In BigQuery, an [external connection](https://cloud.google.com/bigquery/docs/external-data-sources) is required to connect it to pre-trained models in Vertex AI.  If one is not already set up, you must do so. A tutorial can also be found [here](https://cloud.google.com/bigquery/docs/generate-text-tutorial). 
1. Under the same gcp project already in use for the application, verify the [BigQuery Connection](https://console.cloud.google.com/apis/library/bigqueryconnection.googleapis.com) and [Vertex AI](https://console.cloud.google.com/apis/library/aiplatform.googleapis.com) APIs are both enabled. 
2. In BigQuery click “add,” then "Connections to external data sources." 
3. Select "BigLake and remote function" and use the same location as the dataset already in use by the application
4. The ID will be the name of your connection. Since it could be used to connect to any number of pre-trained models in vertex it is wise to choose something generic, such as “ext-vertex-ai”
5. Create the connection
6. Go to the connection and copy the service account ID. In order to access remote functions from Vertex AI, the [BigQuery connection delegation service agent](https://cloud.google.com/iam/docs/service-agents#bigquery-connection-delegation-service-agent) (of the form bqcx-[#]@gcp-sa-bigquery-condel.iam.gserviceaccount.com) that is associated with this connection must have the "Vertex AI User" role, which can be added in IAM.

  ##### 7b: Create the Remote Text-Generation Model

In BigQuery, enter the following statement in the query editor (this code uses the suggested naming conventions for the the steps above and assumes region is US-Multi). The text-bison@002 model is suggested, but other LLM models with good performance generating text could also be used. The model_name will be later added as a User Attribute value. A suggestion for model_name is "mla-text-bison"
```
CREATE OR REPLACE MODEL project_id.dataset_id.model_name
  REMOTE WITH CONNECTION `us.ext-vertex-ai`
  OPTIONS (endpoint = 'text-bison@002');
```
This will take a few minutes to load and will not return any results. 

  ##### 7c: Update the Relevant User Attribute

  Similar to section 5 above.
  
  | **Required User Attribute Name**                                | **Default Value Description**  |
  |-----------------------------------------------------------------|--------------------------------|
  | marketplace_bqml_ext_ml_accelerator_generate_text_model_name    | Name chosen in step 7b above   |
