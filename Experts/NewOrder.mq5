//+------------------------------------------------------------------+
//|                                                     NewOrder.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <trade/trade.mqh>
#include <Trade/AccountInfo.mqh>

ulong imagic = 10;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   runned = 0;
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

int runned = 0;

int icounter = 0;

void OnTick()
  {
//---
   
   icounter++;
   
   if(runned == 0) {
   
   
      double ask=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK),_Digits); 
      double bid=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID),_Digits);      
   
      ulong efc = open_order(ORDER_TYPE_BUY, 0.01, ask, 0, 0 );
   
      Print("open_order() return = ",efc);
   
      runned = 1;
   
   
   }
   
   string all_orders = all_deals(icounter);
   
   Print(all_orders);
   
   CloseAll();
   
  }
//+------------------------------------------------------------------+





input int slippage = 10;  
  
long open_order(ENUM_ORDER_TYPE otype, double lot, double fiyati, double sl, double tp ) {
      
      CTrade MyTrade;
      MyTrade.SetExpertMagicNumber(imagic);
      MyTrade.SetDeviationInPoints(0);
      // MyTrade.SetTypeFilling(emir_acma_turu);
      CAccountInfo myaccount;
      
      string  acc_trading_mode = myaccount.TradeModeDescription();
      long acc_leverage = myaccount.Leverage(); 
      bool t_a = myaccount.TradeAllowed();
      bool e_a = myaccount.TradeExpert();

      /*
      Print("acc_trading_mode = ",acc_trading_mode);
      Print("acc_leverage = ",acc_leverage);
      Print("t_a = ",t_a);
      Print("e_a = ",e_a);
      */

      // Print("new fiyati = ",fiyati);
      
      bool ret = false;
      
      ResetLastError();
    
      
      
      if(otype == ORDER_TYPE_BUY)  {
      
      MyTrade.Buy(lot,NULL,fiyati,sl,tp,"buytrade");
      
      // Print("buy pos open");
      
      } else if(otype == ORDER_TYPE_SELL)  {
      
      MyTrade.Sell(lot,NULL,fiyati,sl,tp,"selltrade");
      
      /*} else if(otype == ORDER_TYPE_BUY || otype == ORDER_TYPE_SELL) {
      ret=MyTrade.PositionOpen(_Symbol,otype,lot,fiyati,sl,tp,"");
         Print("pos open");*/
      } else {
      ret = MyTrade.OrderOpen(_Symbol,otype,lot,fiyati,fiyati,sl,tp,0,0,"");
      }
      
      int gle = GetLastError();
      
      if(MyTrade.ResultRetcode()!= 10009 ){
         Print("Result. Return code=",MyTrade.ResultRetcode(),". Code description: ",MyTrade.ResultRetcodeDescription());             
      }
      
      Print("Result. Return code=",MyTrade.ResultRetcode(),". Code description: ",MyTrade.ResultRetcodeDescription());       
      
      
      // Print("LastErr : ",gle);
      
      /*
      
      if(otype == ORDER_TYPE_BUY || otype == ORDER_TYPE_SELL) {
      ret=MyTrade.PositionOpen(_Symbol,otype,lot,fiyati,sl,tp,"");
      } else if(otype == 5) {
         ret = MyTrade.SellStop(lot,fiyati,_Symbol,sl,tp,ORDER_TIME_GTC,0,"");
      } else if (otype == 4) {
         ret = MyTrade.BuyStop(lot,fiyati,_Symbol,sl,tp,ORDER_TIME_GTC,0,"");
      } else if (otype == 3) {
         ret = MyTrade.SellLimit(lot,fiyati,_Symbol,sl,tp,ORDER_TIME_GTC,0,"");
      } else if (otype == 2) {
         ret = MyTrade.BuyLimit(lot,fiyati,_Symbol,sl,tp,ORDER_TIME_GTC,0,"");
      }
            
      
      
      */
      
      
      long last_ticket = (long) MyTrade.ResultOrder();      
      long last_deal = (long) MyTrade.ResultDeal();      
      Print("last_ticket : ",last_ticket," last_deal = ",last_deal);
      
      
      long wemir_id =  (last_ticket>0 ? last_ticket : last_deal);
      
      Print(TimeToString(TimeCurrent())," wemir_id = ",wemir_id);
      return wemir_id;
}
  
  
  
  
string  all_deals(int counter) {

CTrade atrade;

string inf_s = "";

StringConcatenate(inf_s,inf_s,"---[",counter,"]--------------------------------------------------------------------------------------\n");
StringConcatenate(inf_s,inf_s,"---[",counter,"]--------------------------------------------------------------------------------------\n");
StringConcatenate(inf_s,inf_s,"---[",counter,"]--------------------------------------------------------------------------------------\n");


int all_deals = HistoryDealsTotal();

StringConcatenate(inf_s,inf_s,"---[",counter,"]-----------------------------------  HistoryDealsTotal = ",all_deals," -----------------------------------  \n");

for(int g=all_deals;g>=0;g--) {
   
      ulong deal_ticket=               HistoryDealGetTicket(g); 
      double volume=                    HistoryDealGetDouble(deal_ticket,DEAL_VOLUME); 
      double price=                    HistoryDealGetDouble(deal_ticket,DEAL_PRICE); 
      datetime transaction_time=(datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME); 
      long order_ticket=              HistoryDealGetInteger(deal_ticket,DEAL_ORDER); 
      ENUM_DEAL_TYPE deal_type=               (ENUM_DEAL_TYPE)  HistoryDealGetInteger(deal_ticket,DEAL_TYPE); 
      string symbol=                    HistoryDealGetString(deal_ticket,DEAL_SYMBOL); 
      long position_ID=               HistoryDealGetInteger(deal_ticket,DEAL_POSITION_ID); 

      if(deal_ticket == 0) continue;

      // Print("HistoryDeal[",g,"]   deal ticket:",deal_ticket," order ticket:",order_ticket," price:",price," date:",transaction_time," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID);   
      StringConcatenate(inf_s,inf_s,"HistoryDeal[",g,"]   deal ticket:",deal_ticket," order ticket:",order_ticket," price:",price," date:",transaction_time," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID,"\n");
   
   
   }



   


int all_positions = PositionsTotal();

   // Print("--------------------------------------  PositionsTotal = ",all_deals," -----------------------------------       ");
   StringConcatenate(inf_s,inf_s,"---[",counter,"]-----------------------------------  PositionsTotal = ",all_deals," -----------------------------------\n");


   for(int g=all_positions;g>=0;g--) {
   
      ulong position_ticket=               PositionGetTicket(g); 
      
      PositionSelectByTicket(position_ticket);
      
      double volume=                    PositionGetDouble(POSITION_VOLUME); 
      double price=                    PositionGetDouble(POSITION_PRICE_OPEN); 
      datetime transaction_time=(datetime) PositionGetInteger(POSITION_TIME); 
      long order_ticket=              PositionGetInteger(POSITION_TICKET); 
      ENUM_POSITION_TYPE position_type=               (ENUM_POSITION_TYPE)  PositionGetInteger(POSITION_TYPE); 
      string symbol=                    PositionGetString(POSITION_SYMBOL); 
      long position_ID=               PositionGetInteger(POSITION_IDENTIFIER); 

      if(position_ticket == 0) continue;
      
      
      int filling = 0;
      
      // ENUM_ORDER_TYPE_FILLING filling = (ENUM_ORDER_TYPE_FILLING) 
      // SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);

      // Print("Position[",g,"]   PositionGetTicket:",deal_ticket," position ticket:",order_ticket," price:",price," date:",transaction_time," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID);   
      StringConcatenate(inf_s,inf_s,"Position[",g,"] filling:",filling,"  PositionGetTicket:",position_ticket," position ticket:",order_ticket," price:",price," date:",transaction_time," lot:",volume," symbol:",symbol," deal_type:",EnumToString(position_type)," position_ID:",position_ID,"\n");
      //atrade.SetTypeFilling(filling);
      atrade.PositionClose(position_ticket);
      
   
   }




   


all_deals = OrdersTotal();

   // Print("--------------------------------------  OrdersTotal = ",all_deals," -----------------------------------       ");
   StringConcatenate(inf_s,inf_s,"---[",counter,"]-----------------------------------  OrdersTotal = ",all_deals," -----------------------------------       \n");
   
   for(int g=all_deals;g>=0;g--) {
   
      ulong deal_ticket=               OrderGetTicket(g); 
      
      int gb = OrderSelect(deal_ticket);
      
      double volume=                    OrderGetDouble(ORDER_VOLUME_CURRENT); 
      double price=                    OrderGetDouble(ORDER_PRICE_OPEN); 
      datetime transaction_time=(datetime) OrderGetInteger(ORDER_TIME_SETUP); 
      datetime close_time=(datetime) OrderGetInteger(ORDER_TIME_DONE); 
      long order_ticket=              OrderGetInteger(ORDER_TICKET); 
      ENUM_DEAL_TYPE deal_type=               (ENUM_DEAL_TYPE)  OrderGetInteger(ORDER_TYPE); 
      string symbol=                    OrderGetString(ORDER_SYMBOL); 
      long position_ID=               OrderGetInteger(ORDER_POSITION_ID); 

      if(deal_ticket == 0) continue;

      // Print("Order[",g,"]   OrderGetTicket:",deal_ticket," Order ticket:",order_ticket," price:",price," date:",transaction_time," close_time:",close_time," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID);   
      StringConcatenate(inf_s,inf_s,"Order[",g,"]   OrderGetTicket:",deal_ticket," Order ticket:",order_ticket," price:",price," date:",transaction_time," close_time:",close_time," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID,"\n");
   
   
   }





   


all_deals = HistoryOrdersTotal();

   // Print("--------------------------------------  HistoryOrdersTotal = ",all_deals," -----------------------------------       ");
   StringConcatenate(inf_s,inf_s,"---[",counter,"]-----------------------------------  HistoryOrdersTotal = ",all_deals," ----------------------------------- \n");

   for(int g=all_deals;g>=0;g--) {
   
      ulong deal_ticket=               HistoryOrderGetTicket(g); 
      
      int gb = HistoryOrderSelect(deal_ticket);
      
      double volume= HistoryOrderGetDouble(gb,ORDER_VOLUME_CURRENT); 
      double price=                    HistoryOrderGetDouble(gb,ORDER_PRICE_OPEN); 
      datetime transaction_time=(datetime) HistoryOrderGetInteger(gb,ORDER_TIME_SETUP); 
      datetime close_time=(datetime) HistoryOrderGetInteger(gb,ORDER_TIME_DONE); 
      long order_ticket=              HistoryOrderGetInteger(gb,ORDER_TICKET); 
      ENUM_DEAL_TYPE deal_type=               (ENUM_DEAL_TYPE)  HistoryOrderGetInteger(gb,ORDER_TYPE); 
      string symbol=                    HistoryOrderGetString(gb,ORDER_SYMBOL); 
      long position_ID=               HistoryOrderGetInteger(gb,ORDER_POSITION_ID); 

      if(deal_ticket == 0) continue;

      /*Print("Order[",g,"]   HistoryOrderGetTicket:",deal_ticket," Order ticket:",order_ticket," price:",price," date:",transaction_time," close_time:",close_time
      ," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID);   */
   
      StringConcatenate(inf_s,inf_s,"Order[",g,"]   HistoryOrderGetTicket:",deal_ticket," Order ticket:",order_ticket," price:",price," date:",transaction_time," close_time:",close_time
      ," lot:",volume," symbol:",symbol," deal_type:",EnumToString(deal_type)," position_ID:",position_ID,"\n");
   
   }

   return inf_s;

}


void CloseAll()

{

CTrade trade;

   for (int i=PositionsTotal()-1;i>=0; i--) 

   { 

      {                 

         if(!trade.PositionClose(PositionGetSymbol(i))) 

         {

      //--- failure message

      Print(PositionGetSymbol(i), "PositionClose() method failed. Return code=",trade.ResultRetcode(),

            ". Code description: ",trade.ResultRetcodeDescription());

         }

           

         else

         {

      Print(PositionGetSymbol(i), "PositionClose() method executed successfully. Return code=",trade.ResultRetcode(),

            " (",trade.ResultRetcodeDescription(),")");

         }

      }

   }

     

} 