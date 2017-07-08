//+------------------------------------------------------------------+
//|                                           Heiken_Ashi_Expert.mq5 |
//|                                               Copyright VDV Soft |
//|                                                 vdv_2001@mail.ru |
//+------------------------------------------------------------------+
#property copyright "VDV Soft"
#property link      "vdv_2001@mail.ru"
#property version   "1.00"

#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>

//--- the list of global variables
//--- input parameters
input double Lot=0.1;    // Lot size
//--- indicator handles
int      hHeiken_Ashi;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   hHeiken_Ashi=iCustom(NULL,PERIOD_CURRENT,"Examples\\Heiken_Ashi");
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- trading should be allowed and number of bars calculated>100
   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      if(BarsCalculated(hHeiken_Ashi)>100)
        {
         CheckForOpenClose();
        }
//---
  }
//+------------------------------------------------------------------+
//| Checking of the position opening conditions                      |
//+------------------------------------------------------------------+
void CheckForOpenClose()
  {
//--- process orders only when new bar is formed
   MqlRates rt[1];
   if(CopyRates(_Symbol,_Period,0,1,rt)!=1)
     {
      Print("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   if(rt[0].tick_volume>1) return;

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

   if(CopyBuffer(hHeiken_Ashi,HA_OPEN,0,BAR_COUNT,haOpen)!=BAR_COUNT
      || CopyBuffer(hHeiken_Ashi,HA_HIGH,0,BAR_COUNT,haHigh)!=BAR_COUNT
      || CopyBuffer(hHeiken_Ashi,HA_LOW,0,BAR_COUNT,haLow)!=BAR_COUNT
      || CopyBuffer(hHeiken_Ashi,HA_CLOSE,0,BAR_COUNT,haClose)!=BAR_COUNT)
     {
      Print("CopyBuffer from Heiken_Ashi failed, no data");
      return;
     }
//---- check sell signals
   if(haOpen[BAR_COUNT-2]>haClose[BAR_COUNT-2])// bear candlestick 
     {
      CPositionInfo posinf;
      CTrade trade;
      double lot=Lot;
     //--- check if there is an open position, and if there is, close it
      if(posinf.Select(_Symbol))
        {
         if(posinf.Type()==POSITION_TYPE_BUY)
           {
            //            lot=lot*2;
            trade.PositionClose(_Symbol,3);
           }
        }
      //--- check and set Stop Loss level
      double stop_loss=NormalizeDouble(haHigh[BAR_COUNT-2],_Digits)+_Point*2;
      double stop_level=SymbolInfoDouble(_Symbol,SYMBOL_ASK)+SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
      if(stop_loss<stop_level) stop_loss=stop_level;
      //--- check the combination: the candle with the opposite color has formed
      if(haOpen[BAR_COUNT-3]<haClose[BAR_COUNT-3])
        {
         if(!trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,lot,SymbolInfoDouble(_Symbol,SYMBOL_BID),stop_loss,0))
            Print(trade.ResultRetcodeDescription());
        }
      else
      if(posinf.Select(_Symbol))
        {
         if(!trade.PositionModify(_Symbol,stop_loss,0))
            Print(trade.ResultRetcodeDescription());
        }
     }
//---- check buy signals
   if(haOpen[BAR_COUNT-2]<haClose[BAR_COUNT-2]) // bull candle
     {
      CPositionInfo posinf;
      CTrade trade;
      double lot=Lot;
     //--- check if there is an open position, and if there is, close it
      if(posinf.Select(_Symbol))
        {
         if(posinf.Type()==POSITION_TYPE_SELL)
           {
            //            lot=lot*2;
            trade.PositionClose(_Symbol,3);
           }
        }
      //--- check and set Stop Loss level
      double stop_loss=NormalizeDouble(haLow[BAR_COUNT-2],_Digits)-_Point*2;
      double stop_level=SymbolInfoDouble(_Symbol,SYMBOL_BID)-SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
      if(stop_loss>stop_level) stop_loss=stop_level;
      //--- check the combination: the candle with the opposite color has formed
      if(haOpen[BAR_COUNT-3]>haClose[BAR_COUNT-3])
        {
         if(!trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,lot,SymbolInfoDouble(_Symbol,SYMBOL_ASK),stop_loss,0))
            Print(trade.ResultRetcodeDescription());
        }
      else
      if(posinf.Select(_Symbol))
        {
         if(!trade.PositionModify(_Symbol,stop_loss,0))
            Print(trade.ResultRetcodeDescription());
        }

     }
  }
//+------------------------------------------------------------------+
