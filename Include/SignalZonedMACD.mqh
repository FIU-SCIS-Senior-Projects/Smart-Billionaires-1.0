//+------------------------------------------------------------------+
//|                                              SignalZonedMACD.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
#include <Expert\Signal\SignalMACD.mqh>

class CSignalZonedMACD : public CSignalMACD
{

public:
               CSignalZonedMACD() : CSignalMACD(){}
                    ~CSignalZonedMACD(void);
   bool              CheckMarketCondition(void);                    
};
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalZonedMACD::~CSignalZonedMACD(void)
  {
  }
//+------------------------------------------------------------------+
//| Check Market Conditions                                          |
//+------------------------------------------------------------------+
bool CSignalZonedMACD::CheckMarketCondition(void)
{
   int result = CSignalMACD::LongCondition();
   return result == CSignalMACD::m_pattern_0;
}