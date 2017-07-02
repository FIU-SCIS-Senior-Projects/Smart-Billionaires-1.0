//+------------------------------------------------------------------+
//|                                                       iRenko.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| includes                                                       |
//+------------------------------------------------------------------+
#include <Indicators\Indicator.mqh>
//+------------------------------------------------------------------+
class CiRenko : public CIndicator
{
   protected:
      int               m_ma_period;
      
   public:
                        CiRenko(void);
                        ~CiRenko(void);
      //--- methods of access to protected data
      int               MaPeriod(void)        const { return(m_ma_period); }
         
      bool              Create(const string symbol,const ENUM_TIMEFRAMES period);
      
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiRenko::CiRenko(void) : m_ma_period(-1)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiRenko::~CiRenko(void)
{
}

bool CiRenko::Create(const string symbol,const ENUM_TIMEFRAMES period)
{
   //--- check history
   if(!SetSymbolPeriod(symbol,period))
      return(false);
   //--- create
   m_handle=iCustom(NULL,period,"Downloads\\Renko");
   //--- check result
   if(m_handle==INVALID_HANDLE)
      return(false); 
   //--- ok
   return(true);   
}  
