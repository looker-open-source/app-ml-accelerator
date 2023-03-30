# Machine Learning Accelerator

The ML Accelerator is a purpose-built Looker application designed to give business users access to BigQuery and Vertex AI's machine learning capabilities. It provides a user-friendly interface designed to guide the user through each step of creating a machine learning model. Because of its simple, no-code interface, the application serves as a pathway for business analysts to learn and use predictive analytics in Looker.

View the [ML Model Creation Flow](https://github.com/looker-open-source/app-ml-accelerator/blob/main/ML%20Model%20Creation%20Flow.md) document for an example of an end-to-end user journey.

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
  - [Create a blank LookML project](https://cloud.google.com/looker/docs/create-projects#creating_a_blank_project)
  - [Connect the blank LookML project to the new fork repository](https://cloud.google.com/looker/docs/setting-up-git-connection)
  - Update the value of the CONNECTION_NAME constant in the `manifest.lkml` file
  - [Commit and deploy changes to production](https://cloud.google.com/looker/docs/version-control-and-deploying-changes#getting_your_changes_to_production)

#### 5. Configure Application with User Attributes

The application uses three [Looker user attributes](https://cloud.google.com/looker/docs/admin-panel-users-user-attributes) to store its configuration settings. The following user attributes are required for the application to work properly. Each user attribute needs to be named exactly as listed below with a data type of `String` and user access set to `None`.

The application should be configured using each of the user attribute's default values.

  | **Required User Attribute Name**                  | **Default Value Description**                             |
  |---------------------------------------------------|-----------------------------------------------------------|
  | app_ml_accelerator_bigquery_connection_name       | Connection name chosen in Step 1                          |
  | app_ml_accelerator_gcp_project                    | Projectd ID for connection chosen in Step 1               |
  | app_ml_accelerator_bqml_model_dataset_name        | BigQuery dataset created in Step 3 (e.g., `looker_bqml`   |

#### 6. Create a Looker Role to Manage User Access

The application is designed for users with access to Explores and SQL Runner in Looker. Users will need the following permissions to use the application.
  - `explore`
  - `use_sql_runner`

We recommend creating a new Looker role to easily manage user access to the application and guarantee users have the required permissions above.
  - Create a new Looker model set named `ML Accelerator` containing the LookML model `ml_accelerator`
  - Create a new Looker permission set named `ML Accelerator` containing all the permisions in the [default User permission set](https://cloud.google.com/looker/docs/admin-panel-users-roles#default_permission_sets) AND the `use_sql_runner` permission
  - Create a new Looker role named `ML Accelerator` using the new model and permission set
  - Assign the `ML Accelerator` role to Looker users and groups
