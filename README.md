# INTEL FEED v2 Dashboard

## Quick Start Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/HLPFLCG/hlpfl-news.git
   cd hlpfl-news
   ```  
2. Install the required dependencies:
   ```bash
   npm install
   ```  
3. Start the application:
   ```bash
   npm start
   ```  

## Feature Overview
The INTEL FEED v2 dashboard provides real-time updates and analysis on various financial feeds. Users can easily customize their dashboard, monitor market trends, and receive notifications on critical updates.

## List of All 23 Feeds
1. Market News
2. Stock Analysis
3. Economic Indicators
4. Forex Updates
5. Commodity Prices
6. Cryptocurrency Trends
7. Corporate Earnings
8. Mergers & Acquisitions
9. IPO Listings
10. Analyst Recommendations
11. Insider Trading
12. Global Markets Overview
13. Interest Rate Changes
14. Currency Strength
15. Sentiment Analysis
16. Trading Volume
17. Market Capitalization
18. Dividend Announcements
19. Stock Splits
20. Financial Reports
21. Market Forecasts
22. Risk Assessments
23. Economic Calendar

## API Key Setup
To configure the API key for the data feeds, follow these steps:
1. Sign up for a Finnhub account at [Finnhub.io](https://finnhub.io/).
2. Obtain your API key.
3. Save your API key in the environment variable:
   ```bash
   export FINNHUB_API_KEY="d73oe9pr01qjjol3o4igd73oe9pr01qjjol3o4j0"
   ```  

## Keyboard Shortcuts
- `Ctrl + N`: Create a new dashboard
- `Ctrl + R`: Refresh data
- `Ctrl + S`: Save changes
- `Ctrl + D`: Delete selected feed

## Topstep Account Configuration
1. Create an account on [Topstep](https://www.topsteptrader.com/).
2. Go to account settings and integrate with the INTEL FEED v2 dashboard.
3. Follow the on-screen instructions to link your brokerage account.

## Known Limitations
- Data latency may occur during peak trading hours.
- Some feeds may experience temporary outages due to API issues.
- User interface may have bugs in certain versions of browsers.

## Deployment Instructions
1. Clone the repository as described in the Quick Start Instructions.
2. Set up your environment variables (including the API key).
3. Build the project:
   ```bash
   npm run build
   ```  
4. Deploy using your preferred method (e.g., Docker, cloud services).

For detailed deployment options, please refer to the documentation in the repository.