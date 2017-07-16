//+------------------------------------------------------------------+
//|                                             SignalHeikenAshi.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert\ExpertSignal.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalHeikenAshi : public CExpertSignal
  {
private:

public:
                     CSignalHeikenAshi();
                    ~CSignalHeikenAshi();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalHeikenAshi::CSignalHeikenAshi()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalHeikenAshi::~CSignalHeikenAshi()
  {
  }
  
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalHeikenAshi::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer is performed in the method of the parent class
//---
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize MACD oscilator
   if(!InitMACD(indicators))
      return(false);
//--- ok
   return(true);
  }  
//+------------------------------------------------------------------+
