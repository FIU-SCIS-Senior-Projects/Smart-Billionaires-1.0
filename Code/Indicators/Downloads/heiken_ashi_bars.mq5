//+------------------------------------------------------------------+ 
//|                                             Heiken_Ashi_BARS.mq5 | 
//|                               Copyright © 2013, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers 3
#property indicator_buffers 3 
//--- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//--- drawing indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM2
//--- colors of the five-color histogram are as follows
#property indicator_color1 clrOrange,clrPurple,clrGray,clrMediumBlue,clrDeepSkyBlue
//--- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1 2
//--- displaying the indicator label
#property indicator_label1 "Heiken_Ashi_BARS"
//+-----------------------------------+
//| Declaration of constants          |
//+-----------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpIndBuffer[],DnIndBuffer[],ColorIndBuffer[];
//--- declaration of the integer variables for the start of data calculation
int min_rates_total,CompBars;
//--- declaration of global variables
int Count[];
double haOpen[],haClose[];
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Return the current value of the price series by reference
                          int Size)
  {
//---
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//---
  }
//+------------------------------------------------------------------+    
//| Heiken_Ashi_BARS indicator initialization function               | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of data calculation start
   CompBars=2;
   min_rates_total=int(CompBars);
//---- memory distribution for variables' arrays  
   ArrayResize(Count,CompBars);
   ArrayResize(haOpen,CompBars);
   ArrayResize(haClose,CompBars);
//--- zero out the contents of arrays   
   ArrayInitialize(Count,0);
   ArrayInitialize(haOpen,0.0);
   ArrayInitialize(haClose,0.0);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,UpIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpIndBuffer,true);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(1,DnIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnIndBuffer,true);
//--- setting a dynamic array as a color index buffer   
   SetIndexBuffer(2,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"Heiken_Ashi_BARS");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Heiken_Ashi_BARS iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(RESET);
//--- declarations of local variables
   int limit,bar;
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Close,true);
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars 
      int barc=limit+int(CompBars-1);
      haOpen[Count[0]]=Open[barc];
      haClose[Count[0]]=(Open[barc]+High[barc]+Low[barc]+Close[barc])/4.0;
      Recount_ArrayZeroPos(Count,CompBars);

      for(int index=int(CompBars-1)-1; index>=0 && !IsStopped(); index--)
        {
         int barl=limit+index;
         haOpen[Count[0]]=(haOpen[Count[1]]+haClose[Count[1]])/2.0;
         haClose[Count[0]]=(Open[barl]+High[barl]+Low[barl]+Close[barl])/4.0;
         Recount_ArrayZeroPos(Count,CompBars);
        }
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      UpIndBuffer[bar]=High[bar];
      DnIndBuffer[bar]=Low[bar];
     }
//--- main cycle of the indicator coloring
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      haOpen[Count[0]]=(haOpen[Count[1]]+haClose[Count[1]])/2.0;
      haClose[Count[0]]=(Open[bar]+High[bar]+Low[bar]+Close[bar])/4.0;
      //---
      int clr=2;
      if(haClose[Count[0]]>haOpen[Count[0]])
        {
         if(Open[bar]<=Close[bar]) clr=4;
         if(Open[bar]>Close[bar]) clr=3;
        }

      if(haClose[Count[0]]<haOpen[Count[0]])
        {
         if(Open[bar]>Close[bar]) clr=0;
         if(Open[bar]<=Close[bar]) clr=1;
        }

      ColorIndBuffer[bar]=clr;
      if(bar) Recount_ArrayZeroPos(Count,CompBars);
     }
//---
   return(rates_total);
  }
//+------------------------------------------------------------------+
