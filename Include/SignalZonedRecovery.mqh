//+------------------------------------------------------------------+
//|                                              SignalZonedMACD.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| include                                                          |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Indicators\Indicators.mqh>
#include <Indicators\Oscilators.mqh>
#include <iHeiken_Ashi.mqh>
#include <iRenko.mqh>
//+------------------------------------------------------------------+

class CSignalZonedRecovery : public CExpertSignal
{
protected:
    CiMACD MACD;
    CiMA m_ma;
    CiHeiken_Ashi heiken;
    CiRenko renko;
    
   //--- adjusted parameters
   int               m_period_fast;    // the "period of fast EMA" parameter of the oscillator
   int               m_period_slow;    // the "period of slow EMA" parameter of the oscillator
   int               m_period_signal;  // the "period of averaging of difference" parameter of the oscillator
   ENUM_APPLIED_PRICE m_applied;       // the "price series" parameter of the oscillator
   int               m_ma_period;      // the "period of averaging" parameter of the indicator
   int               m_ma_shift;       // the "time shift" parameter of the indicator
   ENUM_MA_METHOD    m_ma_method;      // the "method of averaging" parameter of the indicator
   ENUM_APPLIED_PRICE m_ma_applied;    // the "object of averaging" parameter of the indicator
       
public:
                     CSignalZonedRecovery(void);
                    ~CSignalZonedRecovery(void);
   bool              CheckMarketCondition(void); 
   virtual bool      InitIndicators(CIndicators *indicators);
   
protected:
   bool InitHeiken(CIndicators *indicators);
   bool InitRenko(CIndicators *indicators); 
   bool InitMA(CIndicators *indicators);
   bool InitMACD(CIndicators *indicators);
   
   double            Main(int ind)                     { return(MACD.Main(ind));      }
   double            Signal(int ind)                   { return(MACD.Signal(ind));    }
   double            DiffMain(int ind)                 { return(Main(ind)-Main(ind+1)); }
   double            MA(int ind)                         { return(m_ma.Main(ind));     }
   double            DiffCloseMA(int ind)                { return(Close(ind)-MA(ind)); }
                        
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalZonedRecovery::CSignalZonedRecovery(void): m_period_fast(12),
                                                  m_period_slow(24),
                                                  m_period_signal(9),
                                                  m_applied(PRICE_CLOSE),
                                                  m_ma_period(12),
                                                  m_ma_shift(0),
                                                  m_ma_method(MODE_SMA),
                                                  m_ma_applied(PRICE_CLOSE)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalZonedRecovery::~CSignalZonedRecovery(void)
  {
  }
//+------------------------------------------------------------------+
//| Check Market Conditions                                          |
//+------------------------------------------------------------------+
bool CSignalZonedRecovery::CheckMarketCondition(void)
{
   int idx = StartIndex();
   int hHeiken_Ashi = heiken.Handle();
   int hRenko = renko.Handle();
   
   //--- to check the conditions we need the last three bars
#define  BAR_COUNT   3
//--- number of the indicator buffer for storage Open
#define  HA_OPEN     0
//--- number of the indicator buffer for storage High
#define  HA_HIGH     1
//--- number of the indicator buffer for storage Low
#define  HA_LOW      2
//--- number of the indicator buffer for storage Close
#define  HA_CLOSE    3

   double   haOpen[BAR_COUNT],haHigh[BAR_COUNT],haLow[BAR_COUNT],haClose[BAR_COUNT];
      
//--- check Heiken Ashi Chart  
   if(CopyBuffer(hHeiken_Ashi,HA_OPEN,0,BAR_COUNT,haOpen)!=BAR_COUNT
      || CopyBuffer(hHeiken_Ashi,HA_HIGH,0,BAR_COUNT,haHigh)!=BAR_COUNT
      || CopyBuffer(hHeiken_Ashi,HA_LOW,0,BAR_COUNT,haLow)!=BAR_COUNT
      || CopyBuffer(hHeiken_Ashi,HA_CLOSE,0,BAR_COUNT,haClose)!=BAR_COUNT)
     {
      Print("CopyBuffer from Heiken_Ashi failed, no data");
      return(false);
     }
   bool result = haClose[BAR_COUNT-2] > haOpen[BAR_COUNT-2];
   
//--- Check EMA Trend
   result = result && (DiffCloseMA(idx) >= 0.0 && IS_PATTERN_USAGE(0));
   
//-- Check Renko Chart
   if(CopyBuffer(hRenko,HA_OPEN,0,BAR_COUNT,haOpen)!=BAR_COUNT
      || CopyBuffer(hRenko,HA_HIGH,0,BAR_COUNT,haHigh)!=BAR_COUNT
      || CopyBuffer(hRenko,HA_LOW,0,BAR_COUNT,haLow)!=BAR_COUNT
      || CopyBuffer(hRenko,HA_CLOSE,0,BAR_COUNT,haClose)!=BAR_COUNT)
     {
      Print("CopyBuffer from Heiken_Ashi failed, no data");
      return(false);
     }
   result = result && (haClose[BAR_COUNT-2] > haOpen[BAR_COUNT-2]);

//-- Validate with MACD
   result = result && (DiffMain(idx)>0.0 && IS_PATTERN_USAGE(0)); 
   return result;
}
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalZonedRecovery::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer is performed in the method of the parent class
//---
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- initialize MACD signal
   if(!InitMACD(indicators)) 
      return(false);  
//--- initialize EMA signal
   if(!InitMA(indicators)) 
      return(false);  
//--- create and initialize Heiken Ashi oscilator
   if(!InitHeiken(indicators))
      return(false);
//--- create and initialize Renko oscilator
   if(!InitRenko(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize MACD oscillators.                                     |
//+------------------------------------------------------------------+
bool CSignalZonedRecovery::InitMACD(CIndicators *indicators)
  {
//--- add object to collection
   if(!indicators.Add(GetPointer(MACD)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!MACD.Create(m_symbol.Name(),m_period,m_period_fast,m_period_slow,m_period_signal,m_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }  
  
//+------------------------------------------------------------------+
//| Initialize MA indicators.                                        |
//+------------------------------------------------------------------+
bool CSignalZonedRecovery::InitMA(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_ma)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_ma.Create(m_symbol.Name(),m_period,m_ma_period,m_ma_shift,m_ma_method,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }
    
//+------------------------------------------------------------------+
//| Initialize Heiken Ashi Indicator.                                     |
//+------------------------------------------------------------------+
bool CSignalZonedRecovery::InitHeiken(CIndicators *indicators)
  {
//--- add object to collection
   if(!indicators.Add(GetPointer(heiken)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!heiken.Create(m_symbol.Name(),m_period))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Initialize Renko Indicator.                                     |
//+------------------------------------------------------------------+
bool CSignalZonedRecovery::InitRenko(CIndicators *indicators)
  {
//--- add object to collection
   if(!indicators.Add(GetPointer(renko)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!renko.Create(m_symbol.Name(),m_period))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
   }