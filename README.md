# Project description
## Objectives
1. **Vest Code and Data**:
   - **Goal**: Check Implementation and Data, fix issues.
2. **Automation and Scalability**:
   - **Goal**: Transition the current locally run model, which requires manual steps, into a fully automated pipeline.
3. **Model Enhancement**:
   - **Goal**: Improve the performance of the MMM by incorporating additional variables and features, seasonality, bike events, run tests.
4. **Optimization Layer**:
   - **Goal**: Implement a dual-level optimization strategy to enhance budget allocation efficiency.
   - **MMM Level Optimization**: Optimize budget allocation between countries and channels on a monthly basis, ensuring strategic alignment and resource distribution.
   - **Campaign-Specific Optimization**: Fine-tune the budget for specific campaigns on a weekly basis, allowing for agile adjustments and maximized campaign effectiveness.

## Application

1. Optimize budgets
2. Run scenarios
3. Data informed target setting

## Next steps
* lets do a weekly
* first start with country region
* use desired uploads as bridge to campaine level optimization
    * then in which country to achieve which uploads in country
    * bridge upload in germany GMV effect in Italy
    * uploads pro country, in which country more uploads, this as goal, how to achieve
    * bridge budget optimazation
    * check which uploads
* Make model run for one country on a EC2 cluster
* output is monthly
    * Fethu makes user
    either run on management region or campany
* automize data ingestion, output and report writing
    * Missing in DB
    * ad spent campainge in language region
    * tell him what is missing
    * "TV_ad_spend", "google_ads_DG_brand",	"google_ads_DG_supply",	"google_ads_DG_demand","YT_Flobikes
* Vest code and hyperparameters
    * cross validation supported
    * enable output
    * model selection seems to be a craft




# Background
## Metabase Reporting
### Weekly Growth Update
[Weekly Growth Update](https://buycycle.metabaseapp.com/public/dashboard/f92e7058-e6d6-47b4-88ea-2010b2a340af?tab=529-daily&management_region=&country_code_2=&yearweek=&date__(conversion_date=&channel_filter=&campaign_name=&campaign_status=&campaign_goal=&bidding_type=&campaign_country_=&ad_platform=)
## GitHub
### Create Tables in Snowflake
You can see respective names in the code:
1. **Raw Data Being Transformed**
   - **Event Attribution**: [Attribution logic for sales_ad_created and order_completed events](https://github.com/buycycle/data/blob/main/sqls/st_il/st_event_attribution.sql).
   - **FCT User Sessions**: [Sessionization of events and attribution logic of sessions](https://github.com/buycycle/data/blob/main/sqls/il/fct_user_sessions.sql).
   There are 3 models: first click, last click, and U-shape (40/20/40).
2. **Business Data Model**
   - **Weekly Growth Update**: [Code that creates the Metabase reporting](https://github.com/buycycle/data/blob/main/sqls/bl/report_weekly_growth_update.sql).
3. **Functions**
   - **Channel Grouping Logic**: [Functions that clean data issues and group UTM parameters into channels](https://github.com/buycycle/data/blob/main/sqls/functions.sql).
**FYI about our GitHub (sqls folder):**
- IL = Semantic Layer = Fact and dimensions for business analytics.
- ST_IL = Staging for IL if the code needs to be broken down.
- BL = Business Layer, pre-joined dataset for a specific function (here marketing reporting).
## Google Drive
- An ad-hoc review (working file) of MMM I did a few weeks ago with potential improvements [here](https://docs.google.com/spreadsheets/d/1mX1jJwlDOWa-unirtTVQLzWKKvJfjwda51koO2ZPeJU/edit?gid=3D0#gid=3D0).
- MMM output I received for FR and DE [here](https://drive.google.com/drive/folders/1ExB7ryRB2V0PCBHHvt6R8CaoXcEWx8xO?usp=3Dsharing).
## Analysis
- Basic notebook from Fethu with some relationships in the MMM input file that Koko used to build the recommendation. It was just to understand if the model output "makes sense" compared to descriptive data.
## Business Process
- Simon can tell you more about it than me.
- At the moment there are two things that help optimization:
  - ROAS of attribution logic.
  - MMM output for budget allocation.
**Status Quo:**
- I am currently automating data feeds and updating channel grouping logic.
- Next steps would be: automate ingestion to MMM model and output of MMM model back to Google Drive and a few more data inclusions (TV).
Hope this helps. Let me know if you want to talk about anything.
## MMM handbook
https://facebookexperimental.github.io/Robyn/docs/analysts-guide-to-MMM/ (


## Koko meeting
variables names cleanup
internes channel grouping

Fethu automati
check Koko model

target and paid variables
organic is input
context variables

also good to check for non marketing contribution

zeitraum, variables and ad stock für marketing channels
rich regression, 15k iterations, get time series validation
geo lift tests genauigkeit von marketing channels,
solver on top for in between counties
only marketing spend no attribution, only topline

add interaction features
saisonality, there is a calendar fine, add bike events



lets do a roadmap over time
I read and align when ready

end of week meeting with Fethu

