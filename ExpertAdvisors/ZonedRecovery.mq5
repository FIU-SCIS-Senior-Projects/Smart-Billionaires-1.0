//+------------------------------------------------------------------+
//|                                                ZonedRecovery.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalZonedMACD.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  

CPositionInfo  *extposition;                   // trade position object
CTrade         *exttrade;                      // trading object
CSignalZonedMACD    *extsignal;                    // signal object
CSymbolInfo    *extsymbol;

bool is_MarketUp;
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title            ="ZonedRecovery"; // Document name
ulong                    Expert_MagicNumber      =28333;           // 
bool                     Expert_EveryTick        =false;           // 
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
input double             Money_FixLot_Percent    =10.0;            // Percent
input double             Money_FixLot_Lots       =0.1;             // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
class CZonedExpert : public CExpert
{
public:
      MqlTradeRequest   m_request;         // request data
      CZonedExpert() : CExpert(){};
      ~CZonedExpert(void){ Deinit(); }
      
      CTrade *getTrade(void){ return m_trade; }
      
      CPositionInfo *getPosition(void){ return GetPointer(m_position); }
      
      bool getData(void)
      {
         MqlDateTime time;
      //--- refresh rates
         if(!m_symbol.RefreshRates())
            return(false); 
         TimeToStruct(m_symbol.Time(),time);
         m_last_tick_time=time;
      //--- refresh indicators
         m_indicators.Refresh();
      //--- ok
         return(true);
      }
      
      CSymbolInfo *getSymbol(void){ return m_symbol; }
      
      bool InitSignal(CExpertSignal *signal)
      {
         if(m_signal!=NULL)
            delete m_signal;
         //---
         if(signal==NULL)
           {
            if((m_signal=new CSignalZonedMACD)==NULL)
            {
               printf(__FUNCTION__+": error initializing signal");
               return(false);
            }   
           }
         else
            m_signal=signal;
         //--- initializing signal object
         if(!m_signal.Init(GetPointer(m_symbol),m_period,m_adjusted_point))
            return(false);
         m_signal.EveryTick(m_every_tick);
         m_signal.Magic(m_magic);
         //--- ok
         return(true);
      }
      
      void constructRequest(const double volume,ENUM_ORDER_TYPE order_type,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
      { 
         ZeroMemory(m_request);
         m_trade.Request(m_request);
      //--- setting request
         m_request.action   =TRADE_ACTION_DEAL;
         m_request.symbol   =symbol;
         m_request.magic    =Expert_MagicNumber;
         m_request.volume   =volume;
         m_request.type     =order_type;
         m_request.price    =price;
         m_request.sl       =sl;
         m_request.tp       =tp;
         m_request.deviation=10;
         m_request.type_filling=ORDER_FILLING_FOK;
         m_request.comment=comment;
      }
};
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
//   if((extsignal = new CSignalZonedMACD)==NULL)
//   {
//      printf(__FUNCTION__+": error creating signal");
 //     ExtExpert.Deinit();
//      return(-2);
//   }
//   if(ExtExpert.InitSignal())
//   {
//      printf(__FUNCTION__+": error initializing signal");
 //     ExtExpert.Deinit();
//      return(-2);
//   }
   extsignal = ExtExpert.Signal();
   if(extsignal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-3);
     }
//---
   extsignal.ThresholdOpen(Signal_ThresholdOpen);
   extsignal.ThresholdClose(Signal_ThresholdClose);
   extsignal.PriceLevel(Signal_PriceLevel);
//--- Check signal parameters
   if(!extsignal.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error signal parameters");
      ExtExpert.Deinit();
      return(-4);
     }   
   extsignal.Expiration(Signal_Expiration);
//--- Creating filter CSignalZonedMACD
   CSignalZonedMACD *filter0=new CSignalZonedMACD;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   extsignal.AddFilter(filter0);
//--- Set filter parameters
   filter0.PeriodFast(Signal_MACD_PeriodFast);
   filter0.PeriodSlow(Signal_MACD_PeriodSlow);
   filter0.PeriodSignal(Signal_MACD_PeriodSignal);
   filter0.Applied(Signal_MACD_Applied);
   filter0.Weight(Signal_MACD_Weight);

//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
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
//--- Instantiating symbol object     
   
   extposition = ExtExpert.getPosition();
   
   exttrade = ExtExpert.getTrade();
   
   extsymbol = ExtExpert.getSymbol();
   
   is_MarketUp = false; 
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
   double recovery_range = 0.0005; //50 pips
   MqlTradeResult result;
   if(ExtExpert.getData())
   {
      if(!extposition.Select(_Symbol)) // Then check if we can enter market
      {
         Print("Possibly Entering the Market");
         if(extsignal.CheckMarketCondition())
         {
            Print("Good Market condtions");
            ExtExpert.constructRequest(0.1,ORDER_TYPE_BUY,_Symbol);
            if(exttrade.OrderSend(ExtExpert.m_request,result))
            {
               is_MarketUp = true;
            }
         }
      }
      else
      {
         if(is_MarketUp)
         {
            if(extsymbol.TickValue() < extposition.PriceOpen() - recovery_range)
            {
               ExtExpert.constructRequest(0.1,ORDER_TYPE_SELL,_Symbol);
               exttrade.OrderSend(ExtExpert.m_request,result);
               is_MarketUp = false;
            }
            else if(extsymbol.TickValue() >= extposition.TakeProfit())
            {
               exttrade.PositionClose(_Symbol);
            }
         }
         else if(!is_MarketUp)
         {
            if(extsymbol.TickValue() < extposition.PriceOpen() - recovery_range)
            {
               ExtExpert.constructRequest(0.1,ORDER_TYPE_BUY,_Symbol);
               exttrade.OrderSend(ExtExpert.m_request,result);
               is_MarketUp = true;
            }
            else if(extsymbol.TickValue() >= extposition.TakeProfit())
            {
               exttrade.PositionClose(_Symbol);
            }
         }
         
      }
   }
   else Print("SymbolInfoTick() failed, error = ",GetLastError()); 
  }
//+------------------------------------------------------------------+
