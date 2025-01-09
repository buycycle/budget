import pandas as pd
from buycycle.data import snowflake_sql_db_read
from datetime import datetime
timeframe= datetime.now() - pd.DateOffset(months=6)
timeframe= timeframe.strftime('%Y-%m-%d')
# Define the query to fetch filtered data
query = f"""
SELECT *
FROM dwh.bl.report_mmm_all
WHERE date >= '{timeframe}'
AND management_region= 'DACH'
AND country= 'DE'
ORDER BY date ASC
"""
# Execute the query and read the data into a DataFrame
df = snowflake_sql_db_read(query=query, DB="DB", driver="snowflake")
# Fill NaN values with 0
df = df.fillna(0)
# Save the filtered DataFrame to a CSV file
df.to_csv("data/data.csv", index=False)

