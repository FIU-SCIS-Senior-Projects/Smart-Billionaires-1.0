# Smart-Billionaires-1.0
Smart Billionaires 1.0

Download MetaTrader 5

1. Navigate to www.mql5.com
2. Download MetaTrader 5 and follow the steps in the installation wizard
3. The MetaEditor can be access from MetaTrader via the MetaEditor button on the toolbar

The file structure is relative to the folder named "MQL5." All include statements are searching for path relative to this folder.
1. After downloading MQL5 Editor. Open the editor. In the navigator window, the root directory of the project will be MQL5. 
2. Can access the containing folder by right clicking and select "Open Folder"
3. Move and replace the folders from this repository to the containing folder MQL5. 
4. Once the files are there, the project will be able to be compiled from the editor.

Adding new files:
1. New Expert Advisers must be added in the Expert folder.
2. Indicators must reside in the Indicators folder.
3. Indicator classes must reside in the Include/Indicators folder. These classes are the indicator interface that the trade signal uses to
   communicate with.
4. Trade Signals must reside in the Include/Expert/Signal folder.
5. Using the MQL5 wizard will properly place the files in the appropriate location.

Using Strategy tester and running the Expert Adviser:
1. Follow the guide in the link: https://www.metatrader5.com/en/terminal/help/acc_open. Using the broker mention in the link will allow the use of hedging and filling trades.
2. A helpful guide to run the test can be found here: https://www.metatrader5.com/en/terminal/help/testing
3. The server used for demo in this project is access.metrader5.com:443. This server allows hedging and trading. 
   Any server with these characteristics can be used, the default server, AMPGlobalClearing is not compatable.