import pandas as pd
from buycycle.data import snowflake_sql_db_read

query="""select * FROM dwh.bl.report_mmm_all limit 100"""
df = snowflake_sql_db_read(query=query, DB="DB", driver="snowflake")

df.to_csv("data/data.csv")

