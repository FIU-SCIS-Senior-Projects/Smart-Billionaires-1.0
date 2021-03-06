//+------------------------------------------------------------------+
//|                                                ZonedRecovery.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalZonedRecovery.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneySizeOptimized.mqh>

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title            ="ZonedRecovery"; // Document name
ulong                    Expert_MagicNumber      =28333;           // 
bool                     Expert_EveryTick        =false;           // 
input double             Expert_RecoveryZone     =0.0005;         // Width of the Recovery zone in pips
input double             Expert_ForcedTakeLevel  =0.0015;         // Take level used during zone recovery
input ulong              Expert_ChartPeriod      =14400;           // Period in seconds to read next heiken ashi bar
//--- inputs for main signal
input int                Signal_ThresholdOpen    =10;              // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose   =10;              // Signal threshold value to close [0...100]
input double             Signal_PriceLevel       =0.0;             // Price level to execute a deal
input double             Signal_StopLevel        =0;            // Stop Loss level (in points)
input double             Signal_TakeLevel        =50.0;            // Take Profit level (in points)
input int                Signal_Expiration       =4;               // Expiration of pending orders (in bars)
input int                Signal_MACD_PeriodFast  =12;              // MACD(12,24,9,PRICE_CLOSE) Period of fast EMA
input int                Signal_MACD_PeriodSlow  =24;              // MACD(12,24,9,PRICE_CLOSE) Period of slow EMA
input int                Signal_MACD_PeriodSignal=9;               // MACD(12,24,9,PRICE_CLOSE) Period of averaging of difference
input ENUM_APPLIED_PRICE Signal_MACD_Applied     =PRICE_CLOSE;     // MACD(12,24,9,PRICE_CLOSE) Prices series
input double             Signal_MACD_Weight      =1.0;             // MACD(12,24,9,PRICE_CLOSE) Weight [0...1.0]
//--- inputs for money
input double             Money_FixLot_Percent    =20.0;            // Percent
input double             Money_FixLot_Lots       =0.1;             // Fixed volume

//+------------------------------------------------------------------+
//| This class is based on the Zone recovery algorithm presented by  |
//| Joseph Nemeth. The video can be found in here:                   |
//| https://www.youtube.com/watch?v=DJz4E7VyeSw                      |
//|                                                                  |
//| The algorithm is composed of two basic parts; Entering the market|
//| and exiting the market.                                          |
//+------------------------------------------------------------------+
class CZonedExpert : public CExpert
   {
   protected:
      double               m_opening_price; // The price the orignal trade was open at
      bool                 is_MarketUp; // Flag used to represent the expected direction of the market
   public:
         MqlTradeRequest   m_request;         // request data
         CZonedExpert() : CExpert(){};
         ~CZonedExpert(void){ Deinit(); }
         virtual void      OnTick(void);
         virtual void      OnTimer(void);
         void              SetFillingMethod(void);
         bool              IsFillingTypeAllowed(const string symbol, int filling_type); 
   };
//+------------------------------------------------------------------+
//| The algorithm is composed of two basic parts; Entering the market|
//| and exiting the market.                                          |
//|                                                                  |
//| When Entering first check the market conditions. If the market is|
//| going up then it is ok to enter.                                 |
//| When exiting, if there is a profit, then close the position      |
//| If there is no profit but entrance conditions still hold, then   |
//| increase volume to improve cost basis.                           |
//| If there is no profit and the entrance condition do not hold then|
//| execute zone recovery.                                           |
//| Zone recovery is to close the position once a target price is    |
//| reached. If the market goes against the most recent position,    |
//| then open a opposite position if it goes past the recovery zone. |
//| The recovery zone is from the initial position opening price, and|
//| a predetermined width below.                                     |
//+------------------------------------------------------------------+   
void CZonedExpert::OnTick(void)
  {
   CSignalZonedRecovery *signal = m_signal;
   double lot;
   //---Refresh symbol information
   if(m_symbol.RefreshRates())
     {
     //--- Attempt to get position to determine if currently in the market.
      if(!m_position.Select(_Symbol)) 
        {
         signal.ExitMode(EXIT_MODE_DEFAULT);  
        }
        //--- Already in the market, determine how to leave
      else
        {
         switch(signal.GetExitMode())
           {
            case(EXIT_MODE_DEFAULT): //--- Leave market via Exit Rule 1 or 2
               if(signal.CheckRenko()==BAR_RED) //Check how to exit the market when the bar changes color to red.
                 {
                  if(m_position.Profit() > 0) // Take the profit and exit market
                    {
                     PrintFormat("Exit with profit: %f", m_position.Profit());
                     m_trade.PositionClose(_Symbol);
                    }
                  else
                    {
                     signal.ExitMode(EXIT_MODE_COSTAVERAGING);
                    }   
                 }
                 break;
            case(EXIT_MODE_ZONERECOVERY): //--- Execute zone recovery
            //--- Expected market direction was up
              if(is_MarketUp) 
                {
                 if(m_symbol.TickValue() <= m_opening_price - Expert_RecoveryZone)
                   {
                   //--- Open a sell position once the market goes down past the recovery zone
                    lot = Money_FixLot_Lots * 1.4;
                    if(m_trade.Sell(lot,_Symbol))
                     {
                        is_MarketUp = false;
                     }
                   }
                 else if(m_symbol.TickValue() >= m_opening_price + Expert_ForcedTakeLevel)
                   {
                    m_trade.PositionClose(_Symbol);
                   }
                }
                //--- Expected market direction was down
              else if(!is_MarketUp) 
                {
                 if(m_symbol.TickValue() >= m_opening_price)
                   {
                   //--- Open a buy position once the market goes up past the initial price
                    lot = Money_FixLot_Lots;
                    if(m_trade.Buy(lot,_Symbol))
                     {
                        is_MarketUp = true;
                     }
                   }
                 else if(m_symbol.TickValue() <= m_opening_price - Expert_RecoveryZone - Expert_ForcedTakeLevel)
                   {
                    m_trade.PositionClose(_Symbol);
                   }
                }
                break;
           }
        }  
     }
     else 
       {
        Print("SymbolInfoTick() failed, error = ",GetLastError());
       }  
  }
  
//+------------------------------------------------------------------+
//| Every time frame(DEFAULT: 240 min) check market conditions.      |
//| Except during zone recovery                                      |
//+------------------------------------------------------------------+
void CZonedExpert::OnTimer(void)
  {
   CSignalZonedRecovery *signal = m_signal;
   double lot;
   //--- Only read chart every period when not executing zone recovery
   if(signal.GetExitMode() == EXIT_MODE_ZONERECOVERY)
     {
      return;
     }
   //---Refresh symbol information
   if(m_symbol.RefreshRates())
     {
     //--- Attempt to get position to determine if currently in the market.
      if(!m_position.Select(_Symbol)) 
        {
         //--- Then check if we can enter market
         if(signal.CheckMarketCondition())
           {
            Print("Good Market Conditions");
            lot = Money_FixLot_Lots;
            //--- Attempt to open a long position
            if(m_trade.Buy(lot,_Symbol))
              {
               is_MarketUp = true;
               m_opening_price = m_trade.RequestPrice();
              }
              //--- Print error code if failed to open position
            else
              {
               Print("Error Code: " + m_trade.ResultRetcode() + "; Description: " + m_trade.ResultRetcodeDescription() + "; Filling: " + m_trade.RequestTypeFillingDescription());
              }
           }
         signal.ExitMode(EXIT_MODE_DEFAULT);  
        }
      else
        {
         if(signal.GetExitMode() == EXIT_MODE_COSTAVERAGING)
           {
            if(signal.CheckMarketCondition()) // Improve cost basis by double cost averaging
              {
               Print("Improving cost Basis");
               lot = Money_FixLot_Lots;
               m_trade.Buy(lot,_Symbol);
               signal.ExitMode(EXIT_MODE_DEFAULT);
              }
            else //Bad Market Conditions so enter zone recovery
              {
               Print("Starting zone recovery");
               signal.ExitMode(EXIT_MODE_ZONERECOVERY);
              }
           }
        }
     }
   else 
       {
        Print("SymbolInfoTick() failed, error = ",GetLastError());
       }
  }

//+------------------------------------------------------------------+
//| Set filling method to the accepted method of the broker          |
//+------------------------------------------------------------------+
void CZonedExpert::SetFillingMethod(void)
  {
   string asset = m_symbol.Name();
   if (IsFillingTypeAllowed(asset, SYMBOL_FILLING_IOC))
   {
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   } 
   else if (IsFillingTypeAllowed(asset, SYMBOL_FILLING_FOK)) 
   {
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   }
   else
   {
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }
   m_trade.SetDeviationInPoints(8);
  }

//+------------------------------------------------------------------+
//| Determine if filling method is accepted by the broker.           |
//+------------------------------------------------------------------+  
bool CZonedExpert::IsFillingTypeAllowed(const string symbol, int filling_type)
  {
   int filling=(int)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE); 
   return((filling & filling_type)==filling_type); 
  }
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CZonedExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
     PrintFormat("The symbol is %s", _Symbol);
//--- Creating signal
   CSignalZonedRecovery *signal = new CSignalZonedRecovery;
   if(signal==NULL)
   {
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-2);
   }
   if(!ExtExpert.InitSignal(signal))
   {
      printf(__FUNCTION__+": error initializing signal");
      ExtExpert.Deinit();
      return(-3);
   }
//---
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
//--- Check signal parameters
   if(!signal.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error signal parameters");
      ExtExpert.Deinit();
      return(-4);
     }   
   signal.Expiration(Signal_Expiration);

//--- Add money to expert (will be deleted automatically))
   CExpertMoney *money=new CExpertMoney;
   if(!ExtExpert.InitMoney())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }     
   ExtExpert.SetFillingMethod();    
   EventSetTimer(Expert_ChartPeriod);
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| Function-event handler "trade"                                   |
//+------------------------------------------------------------------+
void OnTrade(void)
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| Function-event handler "timer"                                   |
//+------------------------------------------------------------------+
void OnTimer(void)
  {
   ExtExpert.OnTimer();
  }  
//+------------------------------------------------------------------+
