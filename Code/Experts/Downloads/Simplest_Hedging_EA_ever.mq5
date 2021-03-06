//+------------------------------------------------------------------+
//|            Simplest Hedging EA ever(barabashkakvn's edition).mq5 |
//| Works best in 5M timeframe                                       |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010 - Monu Ogbe"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper

#define MAGIC  1234
#define IDENT  "mo_bidir"

input double  m_lots         = 1;    // lots
input double  stop_loss      = 76;   // 8 pips (5-digit broker)
input double  take_profit    = 750;  // 75 pips ((5-digit broker)

int            last_bar=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(m_account.MarginMode()!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Print("Hedging only!");
      return(INIT_FAILED);
     }
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   m_trade.SetExpertMagicNumber(MAGIC);      // sets magic number

   if(!RefreshRates())
     {
      Print("Error RefreshRates.",
            " Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime prev_time=0;
   if(prev_time==iTime(0))
      return;
   prev_time=iTime(0);
   if(PositionsTotal()==0)
     {
      if(!RefreshRates())
         return;
      m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
                  m_symbol.Ask()-stop_loss*Point(),m_symbol.Bid()+take_profit*Point(),IDENT);
      m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
                   m_symbol.Bid()+take_profit*Point(),m_symbol.Ask()-take_profit*Point(),IDENT);
     }
   return;
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=0)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[];
   datetime time=0;
   ArraySetAsSeries(Time,true);
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
