//+------------------------------------------------------------------+
//|                                             NonPsychological.mq5 |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"

#include <Trade\Trade.mqh>

//input 
double   FactorLoss = 0.5; // Factor Loss:  Loss/Profit. 
input 
double   Lots = 1;
input bool     CalculateInNewBar = true;
input int      riskRespectVolatility = 60;


// MA handles
int EMA_M1_Fast_Handle;
int EMA_M1_Slow_Handle;

int EMA_M5_Fast_Handle;
int EMA_M5_Slow_Handle;

int EMA_M15_Fast_Handle;
int EMA_M15_Slow_Handle;

int EMA_CURR_Fast_Handle;
int EMA_CURR_Slow_Handle;




CTrade trade;

double prev_Price;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //positionOpen = false;
   prev_Price = 0;
   
   // Initialize indicators   
   EMA_M1_Fast_Handle  = iMA(Symbol(),PERIOD_M1, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_M1_Slow_Handle  = iMA(Symbol(),PERIOD_M1, 21,0,MODE_EMA,PRICE_CLOSE);
   
   EMA_M5_Fast_Handle  = iMA(Symbol(),PERIOD_M5, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_M5_Slow_Handle  = iMA(Symbol(),PERIOD_M5, 21,0,MODE_EMA,PRICE_CLOSE);
   
   EMA_M15_Fast_Handle  = iMA(Symbol(),PERIOD_M15, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_M15_Slow_Handle  = iMA(Symbol(),PERIOD_M15, 21,0,MODE_EMA,PRICE_CLOSE);
   
   
   
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
void OnTick()
  {
//---
   
   
   // Verify is new bar OnTick
   bool newbar = isNewBar();
   if(!newbar && CalculateInNewBar) return;
   
   
   
   
   bool ErrorIndicator = false;
   
   // 0.- Load Buffers 
   double _EMA_M1_Fast[],
          _EMA_M1_Slow[],
          
          _EMA_M5_Fast[],
          _EMA_M5_Slow[],
          
          _EMA_M15_Fast[],
          _EMA_M15_Slow[],
          
          _EMA_CURR_Fast[],
          _EMA_CURR_Slow[],
          
          _HighsBuffer[],
          _LowsBuffer[],
          _OpensBuffer[],
          
          _M15HighsBuffer[],
          _M15LowsBuffer[],
          _M15ClosesBuffer[],
          _M15OpensBuffer[],
          
          _M5HighsBuffer[],
          _M5LowsBuffer[],
          _M5ClosesBuffer[],
          _M5OpensBuffer[],
          
          _ClosesBuffer[];
          
          
          
   ArraySetAsSeries(_ClosesBuffer, true);
   CopyClose(Symbol(),PERIOD_CURRENT,0,50, _ClosesBuffer);
   
   ArraySetAsSeries(_EMA_M1_Fast, true);
   ArraySetAsSeries(_EMA_M1_Slow, true);
   
   ArraySetAsSeries(_EMA_M5_Fast, true);
   ArraySetAsSeries(_EMA_M5_Slow, true);
   
   ArraySetAsSeries(_EMA_M15_Fast, true);
   ArraySetAsSeries(_EMA_M15_Slow, true);
   
   ArraySetAsSeries(_EMA_CURR_Fast, true);
   ArraySetAsSeries(_EMA_CURR_Slow, true);
   
   //    Current
   ArraySetAsSeries(_HighsBuffer, true);
   ArraySetAsSeries(_LowsBuffer, true);
   ArraySetAsSeries(_OpensBuffer, true);
   
   //    M15
   ArraySetAsSeries(_M15HighsBuffer, true);
   ArraySetAsSeries(_M15LowsBuffer, true);
   ArraySetAsSeries(_M15ClosesBuffer, true);
   ArraySetAsSeries(_M15OpensBuffer, true);
   
   //    M5
   ArraySetAsSeries(_M5HighsBuffer, true);
   ArraySetAsSeries(_M5LowsBuffer, true);
   ArraySetAsSeries(_M5ClosesBuffer, true);
   ArraySetAsSeries(_M5OpensBuffer, true);
   
   
   
   if (CopyBuffer(EMA_M1_Fast_Handle,0,0,100,_EMA_M1_Fast) < 0)  {Print("CopyBuffer _EMA_M1_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_M1_Slow_Handle,0,0,100,_EMA_M1_Slow) < 0)  {Print("CopyBuffer _EMA_M1_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   if (CopyBuffer(EMA_M5_Fast_Handle,0,0,100,_EMA_M5_Fast) < 0)  {Print("CopyBuffer _EMA_M5_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_M5_Slow_Handle,0,0,100,_EMA_M5_Slow) < 0)  {Print("CopyBuffer _EMA_M5_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   if (CopyBuffer(EMA_M15_Fast_Handle,0,0,100,_EMA_M15_Fast) < 0)  {Print("CopyBuffer _EMA_M15_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_M15_Slow_Handle,0,0,100,_EMA_M15_Slow) < 0)  {Print("CopyBuffer _EMA_M15_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   if (CopyBuffer(EMA_CURR_Fast_Handle,0,0,100,_EMA_CURR_Fast) < 0)  {Print("CopyBuffer _EMA_Curr_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_CURR_Slow_Handle,0,0,100,_EMA_CURR_Slow) < 0)  {Print("CopyBuffer _EMA_Curr_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   
   // Candlesticks
   if (CopyHigh(Symbol(),PERIOD_CURRENT, 1,100, _HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyLow(Symbol(), PERIOD_CURRENT, 1,100, _LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyClose(Symbol(),PERIOD_CURRENT,0,100, _ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyOpen(Symbol(),PERIOD_CURRENT,0, 100, _OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   
   if (CopyHigh(Symbol(),PERIOD_M15, 1,100, _M15HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyLow(Symbol(), PERIOD_M15, 1,100, _M15LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyClose(Symbol(),PERIOD_M15,0,100, _M15ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyOpen(Symbol(),PERIOD_M15,0, 100, _M15OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   
   if (CopyHigh(Symbol(),PERIOD_M5, 1,50, _M5HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyLow(Symbol(), PERIOD_M5, 1,50, _M5LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyClose(Symbol(),PERIOD_M5,0,50, _M5ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyOpen(Symbol(),PERIOD_M5,0, 50, _M5OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   
   if(ErrorIndicator){ Print("Error Indicator: ", GetLastError()); return;}
   
   
   //Comment("test");
   
   
   
   // 1.- Evaluate trends
   
   double actualPrice = _ClosesBuffer[0];
   
   
   //    TRENDFLAGS  
   //       0: Not confirmed
   //       1: uptrend
   //       2: downtrend
   int trendM1, trendM5, trendM15;
   
   
   trendM1 = Uptrend(_EMA_M1_Fast, _EMA_M1_Slow, actualPrice) ? 1 : (Downtrend(_EMA_M1_Fast, _EMA_M1_Slow, actualPrice) ? 2 : 0);
   trendM5 = Uptrend(_EMA_M5_Fast, _EMA_M5_Slow, actualPrice) ? 1 : (Downtrend(_EMA_M5_Fast, _EMA_M5_Slow, actualPrice) ? 2 : 0);
   trendM15 = Uptrend(_EMA_M15_Fast, _EMA_M15_Slow, actualPrice) ? 1 : (Downtrend(_EMA_M15_Fast, _EMA_M15_Slow, actualPrice) ? 2 : 0);
   
   bool uptrend = trendM1 == trendM5 == trendM15 == 1;
             
   bool downtrend = trendM1 == trendM5 == trendM15 == 2;
   
   
   
   
   
   
   // 2.- Calculate volatility & important fibonacci levels
   
   double min1, max1, volatility1;
   double min5, max5, volatility5;
   double min15, max15, volatility15;
   
   volatility1 = CalculateVolatility(_HighsBuffer, _LowsBuffer, min1, max1);
   volatility5 = CalculateVolatility(_M5HighsBuffer, _M5LowsBuffer, min5, max5);
   volatility15 = CalculateVolatility(_M15HighsBuffer, _M15HighsBuffer, min15, max15);
   
   double fiboLevelsM1[5], // Indexes => 0=23.6   1=38.2   2=50.0   3=61.8   4=78.6
          fiboLevelsM5[5],
          fiboLevelsM15[5];
   
   
   
   
  }
//+------------------------------------------------------------------+



bool Uptrend(double &_EMA_Fast[],
             double &_EMA_Slow[],
             double price){
   
   return (_EMA_Fast[1] > _EMA_Slow[1] && price > _EMA_Slow[1]) && _EMA_Fast[1] > _EMA_Fast[2] && _EMA_Slow[1] > _EMA_Slow[2];
   
}

bool Downtrend(double &_EMA_Fast[],
             double &_EMA_Slow[],
             double price){
   
   return (_EMA_Fast[1] < _EMA_Slow[1] && price < _EMA_Slow[1]) && _EMA_Fast[1] < _EMA_Fast[2] && _EMA_Slow[1] < _EMA_Slow[2];
   
}


// Calculate volatility in $
double CalculateVolatility(double &_Hights[], 
                           double &_Lows[], 
                           double &min,   // output by reference
                           double &max,   // output by reference
                           int count = 50){
   
   
   
   int iMax = -1;
   int iMin = -1;
   bool firstIteration = true;;
   
   while((iMax == -1 || iMax == count -1) ||
         (iMin == -1 || iMin == count -1))
   {
      if(!firstIteration) count++;
   
      iMax = ArrayMaximum(_Hights, 0, count);
      iMin = ArrayMinimum(_Lows, 0, count);
      
      firstIteration = false;
   }
   
   min = _Lows[iMin];
   max = _Hights[iMax];
   
   return max - min;
   
}

double Fibo_CalculatePullback(double volatility,
                              double max,
                              double percent // examples: 23.6, 38.2, 50.0, 61.8, 78.6
){
   
   return max - (volatility * percent * 0.01);
   
}











datetime Old_Time;
datetime New_Time;

bool isNewBar()
{
   New_Time = iTime(Symbol(),PERIOD_CURRENT, 0);
   
   if(New_Time != Old_Time) 
   {
      Old_Time = New_Time;
      return true; 
   }
   else return false;
}