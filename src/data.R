library(DBI)
library(dplyr)
library(dbplyr)
library(odbc)
library(config)
# Read configuration from config.ini
config <- config::get(file = "config.ini")
# Extract parameters from the configuration
user <- config$DATABASE$USER
pw <- config$DATABASE$PW
account <- config$DATABASE$ACCOUNT
region <- config$DATABASE$REGION
warehouse <- config$DATABASE$WAREHOUSE
database <- config$DATABASE$DATABASE
schema <- config$DATABASE$SCHEMA
role <- config$DATABASE$ROLE
# Establish a DSN-less connection to the Snowflake database
myconn <- DBI::dbConnect(
  odbc::odbc(),
  Driver = "SnowflakeDSIIDriver",  # Ensure this matches the installed driver name
  Server = paste0(account, ".", region, ".snowflakecomputing.com"),  # Construct the server URL
  UID = user,
  PWD = pw,
  Warehouse = warehouse,
  Database = database,
  Schema = schema,
  Role = role
)
# Execute the query to retrieve data
mydata <- DBI::dbGetQuery(myconn, "SELECT * FROM dwh.bl.report_mmm_all LIMIT 100")
# Display the first few rows of the data
head(mydata)

