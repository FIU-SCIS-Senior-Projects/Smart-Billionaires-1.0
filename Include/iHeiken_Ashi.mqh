//+------------------------------------------------------------------+
//|                                                 iHeiken_Ashi.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| includes                                                        |
//+------------------------------------------------------------------+
#include <Indicators\Indicator.mqh>
//+------------------------------------------------------------------+
class CiHeiken_Ashi : public CIndicator
{
   protected:
      int               m_ma_period;
      
   public:
                        CiHeiken_Ashi(void);
                        ~CiHeiken_Ashi(void);
      //--- methods of access to protected data
      int               MaPeriod(void)        const { return(m_ma_period); }
         
      bool              Create(const string symbol,const ENUM_TIMEFRAMES period);
      
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiHeiken_Ashi::CiHeiken_Ashi(void) : m_ma_period(-1)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiHeiken_Ashi::~CiHeiken_Ashi(void)
{
}

bool CiHeiken_Ashi::Create(const string symbol,const ENUM_TIMEFRAMES period)
{
   //--- check history
   if(!SetSymbolPeriod(symbol,period))
      return(false);
   //--- create
   m_handle=iCustom(NULL,period,"Examples\\Heiken_Ashi");
   //--- check result
   if(m_handle==INVALID_HANDLE)
      return(false); 
   //--- ok
   return(true);     
}