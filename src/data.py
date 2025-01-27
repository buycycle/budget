import sys
import pandas as pd
from buycycle.data import snowflake_sql_db_read
def fetch_and_save_data(country, management_region, db_name="DB", output_file="data/data.csv"):
    query = f"""
    SELECT *
    FROM dwh.bl.report_mmm_all
    WHERE management_region = '{management_region}'
    AND country = '{country}'
    ORDER BY date ASC
    """
    df = snowflake_sql_db_read(query=query, DB=db_name, driver="snowflake")
    df = df.fillna(0)
    df.to_csv(output_file, index=False)
if __name__ == "__main__":
    # Get arguments from command line
    country = sys.argv[1]
    management_region = sys.argv[2]
    fetch_and_save_data(country, management_region)


