//+------------------------------------------------------------------+
//|                                                   SimpSurfer.mq5 |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"
#property version   "1.00"

#include "include\\BinaryTest.mqh"
#include "include\\BinaryExtensions.mqh"

#define SIZE_BUFFERS 100
#define EMA_BARS_COUNT_TREND 5
#define BARS_COUNT_TREND 8

#define EMA_PERIOD_FAST 9
#define EMA_PERIOD_SLOW 21


input
double Lots = 1;

input bool enableSell = true; // Enable short transactions
input bool enableBuy = true;  // Enable long transactions

input 
bool CalculateInNewBar = false;

input bool enablePeriod1 = true; // Enable Period 1 (current) | Recomended let true
input bool enablePeriod2 = true; // Enable Period 2
input bool enablePeriod3 = true; // Enable Period 3

input ENUM_TIMEFRAMES Period1 = PERIOD_M30; // Period 1 Timeframe (current)
input ENUM_TIMEFRAMES Period2 = PERIOD_H1;  // Period 2 Timeframe
input ENUM_TIMEFRAMES Period3 = PERIOD_H4;  // Period 3 Timeframe

input bool checkP1AboveEMA = false; // Check if Period 1 closes price is above EMAs
input bool checkP2AboveEMA = true;  // Check if Period 2 closes price is above EMAs
input bool checkP3AboveEMA = true;  // Check if Period 3 closes price is above EMAs

input bool checkP1IfNotTouchEMASlow = false;	//	Check if isn't Touch EMA Slow P1
input bool checkP2IfNotTouchEMASlow = true;	//	Check if isn't Touch EMA Slow P2
input bool checkP3IfNotTouchEMASlow = true;	//	Check if isn't Touch EMA Slow P3

input bool openPositionInBound_P1 = true;  // Open position in bound (EMA slow) P1
input bool openPositionInBound_P2 = true;  // Open position in bound (EMA slow) P2
input bool openPositionInBound_P3 = false;  // Open position in bound (EMA slow) P3

input bool openEvenPeriodIsntDefined = false;   // Open position even period of trend isn't defined

input bool enableNOPScheduler = false;      // Not operation Scheduler mode
input int NOPSchedulerFrom;                 // Not operation Scheduler: From
input int NOPSchedulerTo;                   // Not operation Scheduler: To

input int ClosePositionWhenLossMoreThan = 0;    // Close position when loss more than
input bool ClosePositionWhenPriceBreakEMASlow = false;  // Close position when price break EMA slow [close price|new bar event]

// Test Configure
input bool testingMode = true;   // Testing Mode

input MODE_OPERATION ModeOperation = TIME;  // Mode Operation
input int countBarsTimeTest = 5;                   // Number of bars for time test


enum PERIOD {
   NONE,
   PERIOD_1,
   PERIOD_2,
   PERIOD_3
};



// Internal vars

double prev_Price;
double curr_Price;
int TimeElapsed;
MqlDateTime dt_struct;
Testing test;
NotOperateHour NotOperationScheduler;
PERIOD currPeriodForPosition;

//---


// Indicators
// MA handles
int EMA_P1_Fast_Handle;
int EMA_P1_Slow_Handle;

int EMA_P2_Fast_Handle;
int EMA_P2_Slow_Handle;

int EMA_P3_Fast_Handle;
int EMA_P3_Slow_Handle;


// Indicator buffers
double  _EMA_P1_Fast[],
        _EMA_P1_Slow[],

        _EMA_P2_Fast[],
        _EMA_P2_Slow[],

        _EMA_P3_Fast[],
        _EMA_P3_Slow[],


        _HighsBuffer_P1[],
        _LowsBuffer_P1[],
        _OpensBuffer_P1[],
        _ClosesBuffer_P1[],
        
        _HighsBuffer_P2[],
        _LowsBuffer_P2[],
        _OpensBuffer_P2[],
        _ClosesBuffer_P2[],
        
        _HighsBuffer_P3[],
        _LowsBuffer_P3[],
        _OpensBuffer_P3[],
        _ClosesBuffer_P3[];
        



int OnInit()
{
  
    test = new Testing();
    test.TestingMode = testingMode;
    test.TimeLimit = countBarsTimeTest;
    InitializeIndicatorHandles();
    
    
    NotOperationScheduler.enabled = enableNOPScheduler;
    NotOperationScheduler.HourFrom = NOPSchedulerFrom;
    NotOperationScheduler.HourTo = NOPSchedulerTo;
    
    prev_Price = 0;
    curr_Price = 0;
    TimeElapsed = 0;
    
    currPeriodForPosition = NONE;
  
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{
//---
   if(test.TestingMode)
      test.PrintAllTestInfo();
}


void OnTick()
  {
//---


   RefreshIndicators();
   curr_Price = _ClosesBuffer_P1[0];
   if(prev_Price == 0) prev_Price = curr_Price;
   
   bool newbar = isNewBar();
   
   int positionsTotal = PositionsTotal();
   
   if (newbar)
   {
      if(ModeOperation == TIME)
      {
         // TimeElapsed = TimeElapsed + 1
         if(test.openedPosition) test.TimeElapsed++;
         if(positionsTotal > 0) TimeElapsed++;
         
         
         if(positionsTotal > 0 && TimeElapsed >= countBarsTimeTest)
         {
            CloseAllPositions(positionsTotal);
            TimeElapsed = 0;
         }
      }
   }
     
   
   if(test.openedPosition) test.ValidatePositions(curr_Price);
   
   
   if(positionsTotal > 0 && ClosePositionWhenLossMoreThan > 0)
      CloseOperationIfLossMoreThan(ClosePositionWhenLossMoreThan);
      
      
   // Check conditions for open new position
   if(positionsTotal < 1)
   {
      // verify scheduler of Not operation
      datetime dtSer=TimeCurrent(dt_struct);
      int cHour = dt_struct.hour;
      
      bool shedulerAllow = ((NotOperationScheduler.enabled && !(cHour >= NotOperationScheduler.HourFrom && cHour <= NotOperationScheduler.HourTo)) || !NotOperationScheduler.enabled);
      
      
      if(shedulerAllow)
      {
         if(enableBuy && CheckBuyConditions(currPeriodForPosition)) 
         {
            if(testingMode) 
               test.SendOrder(curr_Price, BUY, countBarsTimeTest, 0, 0, ModeOperation);
               
            else SendBuyMarket(curr_Price, Lots);   
            
            
         }
         
         if(enableSell && CheckSellConditions(currPeriodForPosition)) 
         {            
            if(testingMode) 
               test.SendOrder(curr_Price, SELL, countBarsTimeTest, 0, 0, ModeOperation);
               
            else SendSellMarket(curr_Price, Lots);      
         }
      }
   }
   
   
   
   prev_Price = curr_Price; 
}
//+------------------------------------------------------------------+

bool CheckBuyConditions(PERIOD &period)
{
   
   bool trend = true;
   period = NONE;
   
   for(int i = 1; i < EMA_BARS_COUNT_TREND && trend; i++)
      trend = (!enablePeriod1 || _EMA_P1_Fast[i] > _EMA_P1_Slow[i]) && 
              (!enablePeriod2 || _EMA_P2_Fast[i] > _EMA_P2_Slow[i]) &&
              (!enablePeriod3 || _EMA_P3_Fast[i] > _EMA_P3_Slow[i]);
   
              
   
   // Discart              
   if(!trend) return false;
   
   
   
   for(int i = 1; i < BARS_COUNT_TREND && trend; i++)
      trend = (!enablePeriod1 || !checkP1AboveEMA || _ClosesBuffer_P1[i] > _EMA_P1_Fast[i]) && 
              (!enablePeriod2 || !checkP2AboveEMA || _ClosesBuffer_P2[i] > _EMA_P2_Fast[i]) &&
              (!enablePeriod3 || !checkP3AboveEMA || _ClosesBuffer_P3[i] > _EMA_P3_Fast[i]);
   
   
   // Discart              
   if(!trend) return false;
   
   // Lows not touch EMA slow
   for(int i = 1; i < BARS_COUNT_TREND && trend; i++)
      trend = (!enablePeriod1 || !checkP1IfNotTouchEMASlow || _LowsBuffer_P1[i] > _EMA_P1_Slow[i]) && 
              (!enablePeriod2 || !checkP2IfNotTouchEMASlow || _LowsBuffer_P2[i] > _EMA_P2_Slow[i]) &&
              (!enablePeriod3 || !checkP3IfNotTouchEMASlow || _LowsBuffer_P3[i] > _EMA_P3_Slow[i]);
   
   
   // Discart              
   if(!trend) return false;
   
   
   
   if(openPositionInBound_P1 && enablePeriod1 && prev_Price > _EMA_P1_Slow[0] && curr_Price < _EMA_P1_Slow[0])
      { period = PERIOD_1; return true; }
   if(openPositionInBound_P2 && enablePeriod2 && prev_Price > _EMA_P2_Slow[0] && curr_Price < _EMA_P2_Slow[0])
      { period = PERIOD_2; return true; }
   if(openPositionInBound_P3 && enablePeriod3 && prev_Price > _EMA_P3_Slow[0] && curr_Price < _EMA_P3_Slow[0])
      { period = PERIOD_3; return true; }
      
   if((!openPositionInBound_P1 || !enablePeriod1) &&
      (!openPositionInBound_P2 || !enablePeriod2) &&
      (!openPositionInBound_P3 || !enablePeriod3)) 
         trend = true;  
   
   else trend = false;
   
   if (openEvenPeriodIsntDefined) return trend;
   
   else if (trend && period != NONE) return true;
   
   else return false;
      
}




//-----------------------
bool CheckSellConditions(PERIOD &period)
{
   bool trend = true;
   period = NONE;
   
   for(int i = 1; i < EMA_BARS_COUNT_TREND && trend; i++)
      trend = (!enablePeriod1 || _EMA_P1_Fast[i] < _EMA_P1_Slow[i]) && 
              (!enablePeriod2 || _EMA_P2_Fast[i] < _EMA_P2_Slow[i]) &&
              (!enablePeriod3 || _EMA_P3_Fast[i] < _EMA_P3_Slow[i]);
   
              
   
   // Discart              
   if(!trend) return false;
   
   
   
   for(int i = 1; i < BARS_COUNT_TREND && trend; i++)
      trend = (!enablePeriod1 || !checkP1AboveEMA || _ClosesBuffer_P1[i] < _EMA_P1_Fast[i]) && 
              (!enablePeriod2 || !checkP2AboveEMA || _ClosesBuffer_P2[i] < _EMA_P2_Fast[i]) &&
              (!enablePeriod3 || !checkP3AboveEMA || _ClosesBuffer_P3[i] < _EMA_P3_Fast[i]);
   
   
   // Discart              
   if(!trend) return false;
   
   // Lows not touch EMA slow
   for(int i = 1; i < BARS_COUNT_TREND && trend; i++)
      trend = (!enablePeriod1 || !checkP1IfNotTouchEMASlow || _HighsBuffer_P1[i] < _EMA_P1_Slow[i]) && 
              (!enablePeriod2 || !checkP2IfNotTouchEMASlow || _HighsBuffer_P2[i] < _EMA_P2_Slow[i]) &&
              (!enablePeriod3 || !checkP3IfNotTouchEMASlow || _HighsBuffer_P3[i] < _EMA_P3_Slow[i]);
   
   
   // Discart              
   if(!trend) return false;
   
   
   
   if(openPositionInBound_P1 && enablePeriod1 && prev_Price < _EMA_P1_Slow[0] && curr_Price > _EMA_P1_Slow[0])
      { period = PERIOD_1; return true; }
   if(openPositionInBound_P2 && enablePeriod2 && prev_Price < _EMA_P2_Slow[0] && curr_Price > _EMA_P2_Slow[0])
      { period = PERIOD_2; return true; }
   if(openPositionInBound_P3 && enablePeriod3 && prev_Price < _EMA_P3_Slow[0] && curr_Price > _EMA_P3_Slow[0])
      { period = PERIOD_3; return true; }
      
   if((!openPositionInBound_P1 || !enablePeriod1) &&
      (!openPositionInBound_P2 || !enablePeriod2) &&
      (!openPositionInBound_P3 || !enablePeriod3)) 
         trend = true;  
   
   else trend = false;
   
   if (openEvenPeriodIsntDefined) return trend;
   
   else if (trend && period != NONE) return true;
   
   else return false;
   
                         
}

/*
bool CheckCloseConditions(bool newbar = false)
{
   
   if(ClosePositionWhenPriceBreakEMASlow && newbar)
   {
      if(_cl)
   }
}*/





// Initialize indicators   
void InitializeIndicatorHandles(){
   
    if(enablePeriod1)
    {
      EMA_P1_Fast_Handle = iMA(Symbol(), Period1, EMA_PERIOD_FAST, 0, MODE_EMA, PRICE_CLOSE);
      EMA_P1_Slow_Handle = iMA(Symbol(), Period1, EMA_PERIOD_SLOW, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    if(enablePeriod2)
    {
      EMA_P2_Fast_Handle = iMA(Symbol(), Period2, EMA_PERIOD_FAST, 0, MODE_EMA, PRICE_CLOSE);
      EMA_P2_Slow_Handle = iMA(Symbol(), Period2, EMA_PERIOD_SLOW, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    if(enablePeriod3)
    {
      EMA_P3_Fast_Handle = iMA(Symbol(), Period3, EMA_PERIOD_FAST, 0, MODE_EMA, PRICE_CLOSE);
      EMA_P3_Slow_Handle = iMA(Symbol(), Period3, EMA_PERIOD_SLOW, 0, MODE_EMA, PRICE_CLOSE);
    }

    

}

// Return false if error
bool RefreshIndicators()
{
   bool ErrorIndicator = false;
   
   
   ArraySetAsSeries(_EMA_P1_Fast, true);
   ArraySetAsSeries(_EMA_P1_Slow, true);
   
   ArraySetAsSeries(_EMA_P2_Fast, true);
   ArraySetAsSeries(_EMA_P2_Slow, true);
   
   ArraySetAsSeries(_EMA_P3_Fast, true);
   ArraySetAsSeries(_EMA_P3_Slow, true);
   
   ArraySetAsSeries(_HighsBuffer_P1, true);
   ArraySetAsSeries(_LowsBuffer_P1, true);
   ArraySetAsSeries(_ClosesBuffer_P1, true);
   ArraySetAsSeries(_OpensBuffer_P1, true);
   
   ArraySetAsSeries(_HighsBuffer_P2, true);
   ArraySetAsSeries(_LowsBuffer_P2, true);
   ArraySetAsSeries(_ClosesBuffer_P2, true);
   ArraySetAsSeries(_OpensBuffer_P2, true);
   
   ArraySetAsSeries(_HighsBuffer_P3, true);
   ArraySetAsSeries(_LowsBuffer_P3, true);
   ArraySetAsSeries(_ClosesBuffer_P3, true);
   ArraySetAsSeries(_OpensBuffer_P3, true);
   
   
   
   
   
   
   // Candlesticks
   // PERIOD 1
   if(enablePeriod1)
   {
      if (CopyBuffer(EMA_P1_Fast_Handle, 0, 0, SIZE_BUFFERS, _EMA_P1_Fast) < 0) { Print("CopyBuffer EMA_P1_Fast_Handle Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyBuffer(EMA_P1_Slow_Handle, 0, 0, SIZE_BUFFERS, _EMA_P1_Slow) < 0) { Print("CopyBuffer EMA_P1_Slow_Handle error = ", GetLastError()); ErrorIndicator = true; }

   
      if (CopyHigh(Symbol(), Period1, 0, SIZE_BUFFERS, _HighsBuffer_P1) < 0) { Print("CopyHigh Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyLow(Symbol(), Period1, 0, SIZE_BUFFERS, _LowsBuffer_P1) < 0) { Print("CopyLow Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyClose(Symbol(), Period1, 0, SIZE_BUFFERS, _ClosesBuffer_P1) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyOpen(Symbol(), Period1, 0, SIZE_BUFFERS, _OpensBuffer_P1) < 0) { Print("CopyOpen Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
   }
   // PERIOD 2
   if(enablePeriod2)
   {
      if (CopyBuffer(EMA_P2_Fast_Handle, 0, 0, SIZE_BUFFERS, _EMA_P2_Fast) < 0) { Print("CopyBuffer EMA_P2_Fast_Handle Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyBuffer(EMA_P2_Slow_Handle, 0, 0, SIZE_BUFFERS, _EMA_P2_Slow) < 0) { Print("CopyBuffer EMA_P2_Slow_Handle error = ", GetLastError()); ErrorIndicator = true; }

      
      if (CopyHigh(Symbol(), Period2, 0, SIZE_BUFFERS, _HighsBuffer_P2) < 0) { Print("CopyHigh Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyLow(Symbol(), Period2, 0, SIZE_BUFFERS, _LowsBuffer_P2) < 0) { Print("CopyLow Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyClose(Symbol(), Period2, 0, SIZE_BUFFERS, _ClosesBuffer_P2) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyOpen(Symbol(), Period2, 0, SIZE_BUFFERS, _OpensBuffer_P2) < 0) { Print("CopyOpen Historical Data Error = ", GetLastError()); ErrorIndicator = true; }

   }
   // PERIOD 3
   if(enablePeriod3)
   {
      if (CopyBuffer(EMA_P3_Fast_Handle, 0, 0, SIZE_BUFFERS, _EMA_P3_Fast) < 0) { Print("CopyBuffer EMA_P3_Fast_Handle Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyBuffer(EMA_P3_Slow_Handle, 0, 0, SIZE_BUFFERS, _EMA_P3_Slow) < 0) { Print("CopyBuffer EMA_P3_Slow_Handle error = ", GetLastError()); ErrorIndicator = true; }
   
      
      if (CopyHigh(Symbol(), Period3, 0, SIZE_BUFFERS, _HighsBuffer_P3) < 0) { Print("CopyHigh Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyLow(Symbol(), Period3, 0, SIZE_BUFFERS, _LowsBuffer_P3) < 0) { Print("CopyLow Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyClose(Symbol(), Period3, 0, SIZE_BUFFERS, _ClosesBuffer_P3) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
      if (CopyOpen(Symbol(), Period3, 0, SIZE_BUFFERS, _OpensBuffer_P3) < 0) { Print("CopyOpen Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
   }
      
   if (ErrorIndicator) { Print("Error Indicator: ", GetLastError()); return false; }
    
   else return true;
}


