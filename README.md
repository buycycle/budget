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




