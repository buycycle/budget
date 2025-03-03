import sys
import os
import pandas as pd
from buycycle.data import snowflake_sql_db_read
def fetch_and_save_data(country, management_region, table_name, output_folder, output_file, db_name="DB"):
    query = f"""
    SELECT *
    FROM {table_name}
    WHERE management_region = '{management_region}'
    AND country = '{country}'
    ORDER BY date ASC
    """
    df = snowflake_sql_db_read(query=query, DB=db_name, driver="snowflake")
    df = df.fillna(0)
    output_path = os.path.join(output_folder, output_file)
    df.to_csv(output_path, index=False)
def fetch_and_save_target(management_region, table_name, output_folder, output_file, db_name="DB"):
    query = f"""
    SELECT *
    FROM {table_name}
    WHERE management_region = '{management_region}'
    """
    df = snowflake_sql_db_read(query=query, DB=db_name, driver="snowflake")
    df = df.fillna(0)
    output_path = os.path.join(output_folder, output_file)
    df.to_csv(output_path, index=False)
if __name__ == "__main__":
    # Get arguments from command line
    country = sys.argv[1]
    management_region = sys.argv[2]
    output_folder = sys.argv[3]
    fetch_and_save_data(country=country,
                        management_region=management_region,
                        output_folder=output_folder,
                        output_file="data.csv",
                        table_name="dwh.bl.report_mmm_all")


    fetch_and_save_data(country=country,
                        management_region=management_region,
                        output_folder=output_folder,
                        output_file="data_campaigne.csv",
                        table_name="dwh.bl.report_mmm_all2")

    fetch_and_save_target(management_region=management_region,
                        db_name="DB_TARGET",
                        output_folder=output_folder,
                        output_file="data_target.csv",
                        table_name="dwh.il.dim_growth_targets")
