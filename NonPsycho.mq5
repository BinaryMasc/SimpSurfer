//+------------------------------------------------------------------+
//|                                                    NonPsycho.mq5 |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"

#include "include\\BinaryTest.mqh"
#include "include\\BinaryExtensions.mqh"



#define SIZE_BUFFERS 100

//input 
//double FactorLoss = 0.5; // Factor Loss: Loss/Profit. 

input
double FactorProfit = 2;

input
double Lots = 1;

input 
bool CalculateInNewBar = false;

input 
int riskRespectVolatility = 60;

input bool enableLongPositions = true;
input bool enableShortPositions = true;

input bool enable_M1 = true;
input bool enable_M5 = true;
input bool enable_M15 = true;


input bool NOPScheduler = false; // Not operation Scheduler mode
input int NOPSchedulerFrom; // Not operation Scheduler: From
input int NOPSchedulerTo; // Not operation Scheduler: To


bool testingMode = true;


input MODE_OPERATION ModeOperation = PRICE_LEVEL;

input
int countBarsTimeTest = 5;


// Indicators
// MA handles
int EMA_M1_Fast_Handle;
int EMA_M1_Slow_Handle;

int EMA_M5_Fast_Handle;
int EMA_M5_Slow_Handle;

int EMA_M15_Fast_Handle;
int EMA_M15_Slow_Handle;

// internal MAs Handles for volatility measure
int MA_M1_Volatility_Handle;
int MA_M5_Volatility_Handle;
int MA_M15_Volatility_Handle;

// internal MAs Handles for track secuence
// TODO: Not implemented
int MA_M1_MinSecuence_Handle;
int MA_M5_MinSecuence_Handle;
int MA_M15_MinSecuence_Handle;


// Indicator buffers
double _EMA_M1_Fast[],
        _EMA_M1_Slow[],

        _EMA_M5_Fast[],
        _EMA_M5_Slow[],

        _EMA_M15_Fast[],
        _EMA_M15_Slow[],


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

        _ClosesBuffer[],

        _MA_M1_Volat[],
        _MA_M5_Volat[],
        _MA_M15_Volat[],
        
        _MA_M1_MinSecuence[],
        _MA_M5_MinSecuence[],
        _MA_M15_MinSecuence[];







MqlDateTime dt_struct;
Testing test;
NotOperateHour NotOperationScheduler;



double prev_Price;




int OnInit()
{
    //---
    test = new Testing();
    test.TestingMode = testingMode;
    test.TimeLimit = countBarsTimeTest;
    InitializeIndicatorHandles();
    
    
    NotOperationScheduler.enabled = NOPScheduler;
    NotOperationScheduler.HourFrom = NOPSchedulerFrom;
    NotOperationScheduler.HourTo = NOPSchedulerTo;
    
    prev_Price = 0;
    

    //---
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   if(test.TestingMode)
      test.PrintAllTestInfo();
}


void OnTick()
{
    //---
    

    // Verify is new bar OnTick
    bool newbar = isNewBar();
        
    if (newbar && test.TestingMode)  test.TimeElapsed++;
    
    
    
    if (!newbar && CalculateInNewBar) return;


   
    // 0.- Load Buffers 
    
    RefreshIndicators();
    
    //---

   MqlTick Latest_Price; // Structure to get the latest prices      
   SymbolInfoTick(Symbol() ,Latest_Price); // Assign current prices to structure 


   double actualPrice = _ClosesBuffer[0];
   test.ValidatePositions(actualPrice);



   string displayData = "";

    
    

    // 1.- Evaluate trends


    // TRENDFLAGS  
    // 0: Not confirmed
    // 1: uptrend
    // 2: downtrend
    int trendM1, trendM5, trendM15;


    trendM1 = Uptrend(_EMA_M1_Fast, _EMA_M1_Slow, actualPrice) ? 1 : (Downtrend(_EMA_M1_Fast, _EMA_M1_Slow, actualPrice) ? 2 : 0);
    trendM5 = Uptrend(_EMA_M5_Fast, _EMA_M5_Slow, actualPrice) ? 1 : (Downtrend(_EMA_M5_Fast, _EMA_M5_Slow, actualPrice) ? 2 : 0);
    trendM15 = Uptrend(_EMA_M15_Fast, _EMA_M15_Slow, actualPrice) ? 1 : (Downtrend(_EMA_M15_Fast, _EMA_M15_Slow, actualPrice) ? 2 : 0);

    bool uptrend = trendM1 == trendM5 && trendM5 == trendM15 && trendM15 == 1;

    bool downtrend = trendM1 == trendM5 && trendM5 == trendM15 && trendM15 == 2;
   
    displayData += "General Trend: " + (uptrend ? "Uptrend." : downtrend ? "Downtrend." : "Not confirmed.");
   
    displayData += "\nTrendP1: " + (trendM1 == 0 ? "Not confirmed." : (trendM1 == 1 ? "Uptrend." : "Downtrend."))  + " | " + (enable_M1 ? "Enabled" : "Disabled");
    displayData += "\nTrendP2: " + (trendM5 == 0 ? "Not confirmed." : (trendM5 == 1 ? "Uptrend." : "Downtrend."))  + " | " + (enable_M5 ? "Enabled" : "Disabled");
    displayData += "\nTrendP3: " + (trendM15 == 0 ? "Not confirmed." : (trendM15 == 1 ? "Uptrend." : "Downtrend."))+ " | " + (enable_M15 ? "Enabled" : "Disabled");




    // 2.- Calculate volatility for each period

    double min1, max1, volatility1;
    double min5, max5, volatility5;
    double min15, max15, volatility15;

   bool relativeVolatity = false;

    // If trend, calculate relative volatility
    if (uptrend || downtrend) {
        volatility1 = CalculateRelativeVolatility(_HighsBuffer, _LowsBuffer, _MA_M1_Volat, min1, max1, uptrend);
        volatility5 = CalculateRelativeVolatility(_M5HighsBuffer, _M5LowsBuffer, _MA_M5_Volat, min5, max5, uptrend);
        volatility15 = CalculateRelativeVolatility(_M15HighsBuffer, _M15LowsBuffer, _MA_M15_Volat, min15, max15, uptrend);
        
        relativeVolatity = true;
    }

    // Just for information 
    else {

        volatility1 = CalculateVolatility(_HighsBuffer, _LowsBuffer, min1, max1);
        volatility5 = CalculateVolatility(_M5HighsBuffer, _M5LowsBuffer, min5, max5);
        volatility15 = CalculateVolatility(_M15HighsBuffer, _M15LowsBuffer, min15, max15);
    }

    displayData += "\nVolatility:\n\t-P1: " + DoubleToString(volatility1, 2)  + "\n\t-P2: " + DoubleToString(volatility5, 2) + "\n\t-P3: " + DoubleToString(volatility15, 2) + "\nRelative Volatity: " + (relativeVolatity ? "Yes." : "No.");

    // 3.- Find important fibonacci levels

    double fiboLevelsM1[5], // Indexes => 0=23.6 1=38.2 2=50.0 3=61.8 4=78.6
        fiboLevelsM5[5],
        fiboLevelsM15[5];


    // Initialize arrays
    for (int i = 1; i < 5; i++) {
        fiboLevelsM1[i] = 0;
        fiboLevelsM5[i] = 0;
        fiboLevelsM15[i] = 0;
    }

    // Calculate fibo levels
    for (int i = 1; i < 5; i++) {   //  Initialize with 38.2%
        double perc = i == 0 ? 23.6 : (i == 1 ? 38.2 : (i == 2 ? 50.0 : (i == 3 ? 61.8 : 78.6)));

        fiboLevelsM1[i] = Fibo_CalculatePullback(volatility1, max1, perc);

        fiboLevelsM5[i] = Fibo_CalculatePullback(volatility5, max5, perc);

        fiboLevelsM15[i] = Fibo_CalculatePullback(volatility15, max15, perc);

        displayData += "\nFibo levels (" + DoubleToString(perc, 2) + "%):\n\t-P1: " + DoubleToString(fiboLevelsM1[i], 2) + "\n\t-P2: " + DoubleToString(fiboLevelsM5[i], 2) + "\n\t-P3: " + DoubleToString(fiboLevelsM15[i], 2);
    }


    // 4.-  If is trend, evaluate fibonacci levels and send order
    if ((uptrend || downtrend) && (PositionsTotal() == 0 && !test.openedPosition)) {

        //  Conditions on:
        bool onM1 = false, onM5 = false, onM15 = false;
        int i; // Index represents the fibo level

        if (uptrend) {
            
            
            
            // 4.1.- Evaluate levels for period
            
            do {

                for (i = 0; i < 5 && enable_M15; i++) {
                    if (prev_Price > fiboLevelsM15[i] && actualPrice < fiboLevelsM15[i])
                        onM15 = true;
                }
                if (i < 5 && enable_M15) break;

                for (i = 0; i < 5 && enable_M5; i++) {
                    if (prev_Price > fiboLevelsM5[i] && actualPrice < fiboLevelsM5[i])
                        onM5 = true;
                }
                if (i < 5 && enable_M5) break;

                for (i = 0; i < 5 && enable_M1; i++) {
                    if (prev_Price > fiboLevelsM1[i] && actualPrice < fiboLevelsM1[i])
                        onM1 = true;
                }
                if (i < 5 && enable_M1) break;

                

                

            } while (false);    //  for just one execution



            // 4.2.- verify is the zone wasn't tested respect by period
            
            bool pullbackExtended = false;
            
            
            if(onM1){
               int j = 2;
               while(!pullbackExtended &&  _MA_M1_MinSecuence[j - 1] < _MA_M1_MinSecuence[j]) 
                  j++;
               
               double localMin = _LowsBuffer[ArrayMinimum(_LowsBuffer, 1, j - 1)];
               
               pullbackExtended = localMin > actualPrice;
               
            }
            
            else if(onM5){
               int j = 2;
               while(!pullbackExtended &&  _MA_M5_MinSecuence[j - 1] < _MA_M5_MinSecuence[j]) 
                  j++;
               
               double localMin = _M5LowsBuffer[ArrayMinimum(_M5LowsBuffer, 1, j - 1)];
               
               pullbackExtended = localMin < actualPrice;
               
            }
            
            else if(onM15){
               int j = 2;
               while(!pullbackExtended &&  _MA_M15_MinSecuence[j - 1] < _MA_M15_MinSecuence[j]) 
                  j++;
               
               double localMin = _M15LowsBuffer[ArrayMinimum(_M15LowsBuffer, 1, j - 1)];
               
               pullbackExtended = localMin < actualPrice;
               
            }

            
            // 4.3.- now determine SL and TP Levels
            
            double lSL = 0;   // Local Stop loss
            double lTP = 0;   // Local Take Profit
            if(!pullbackExtended && ModeOperation == PRICE_LEVEL){
            
               //  This because in this case 4 is 78% of pullback and is a posible reversion
               if(i < 4 && i > 0) {
                  if(onM1)
                     lSL = fiboLevelsM1[i - 1] - (volatility1 * 0.1);
                  
                  
                  else if(onM5)
                     lSL = fiboLevelsM5[i - 1] - (volatility5 * 0.1);
                     
                  
                  else if(onM15)
                     lSL = fiboLevelsM5[i - 1] - (volatility15 * 0.1);
                  
                  
                  if(onM1 || onM15 || onM5) lTP = actualPrice + (MathAbs(actualPrice - lSL) * FactorProfit);
                  
                  lSL = NormalizeDouble(lSL, Point());
                  lTP = NormalizeDouble(lTP, Point());
                  
               }
            }
            
            
            
            // Also verify scheduler of Not operation
            datetime dtSer=TimeCurrent(dt_struct);
            
            int cHour = dt_struct.hour;
            
            
            // 4.4.- Open positions (Also verify scheduler of Not operation and is enabled this position type)
            if(!pullbackExtended && enableLongPositions && ((NotOperationScheduler.enabled && !(cHour >= NotOperationScheduler.HourFrom && cHour <= NotOperationScheduler.HourTo)) || !NotOperationScheduler.enabled))
            {
               if (ModeOperation == TIME || (MathAbs(lTP) > 1 && MathAbs(lSL) > 1)){
                  
                  if(test.TestingMode)
                     test.SendOrder(actualPrice, BUY, ModeOperation == TIME ? countBarsTimeTest : 0, lTP, lSL, ModeOperation);
                     
                  else
                     SendBuyMarket(Latest_Price.ask, Lots, lTP, lSL);   
                  
               
               }
               
            }

        }
        
        
        else
        {
            
            // 4.1.- Evaluate levels for period
            
            do {

                for (i = 0; i < 5 && enable_M15; i++) {
                    if (prev_Price < fiboLevelsM15[i] && actualPrice > fiboLevelsM15[i])
                        onM15 = true;
                }
                if (i < 5 && enable_M15) break;

                for (i = 0; i < 5 && enable_M5; i++) {
                    if (prev_Price < fiboLevelsM5[i] && actualPrice > fiboLevelsM5[i])
                        onM5 = true;
                }
                if (i < 5 && enable_M5) break;

                for (i = 0; i < 5 && enable_M1; i++) {
                    if (prev_Price < fiboLevelsM1[i] && actualPrice > fiboLevelsM1[i])
                        onM1 = true;
                }
                if (i < 5 && enable_M1) break;

                

                

            } while (false);    //  for just one execution



            // 4.2.- verify is the zone wasn't tested respect by period
            
            bool pullbackExtended = false;
            
            
            if(onM1){
               int j = 2;
               while(!pullbackExtended &&  _MA_M1_MinSecuence[j - 1] > _MA_M1_MinSecuence[j]) 
                  j++;
               
               double localMax = _HighsBuffer[ArrayMaximum(_HighsBuffer, 1, j - 1)];
               
               pullbackExtended = localMax > actualPrice;
               
            }
            
            else if(onM5){
               int j = 2;
               while(!pullbackExtended &&  _MA_M5_MinSecuence[j - 1] > _MA_M5_MinSecuence[j]) 
                  j++;
               
               double localMax = _M5HighsBuffer[ArrayMaximum(_M5HighsBuffer, 1, j - 1)];
               
               pullbackExtended = localMax > actualPrice;
               
            }
            
            else if(onM15){
               int j = 2;
               while(!pullbackExtended &&  _MA_M15_MinSecuence[j - 1] > _MA_M15_MinSecuence[j]) 
                  j++;
               
               double localMax = _M15HighsBuffer[ArrayMaximum(_M15HighsBuffer, 1, j - 1)];
               
               pullbackExtended = localMax > actualPrice;
               
            }

            
            // 4.3.- now determine SL and TP Levels
            
            double lSL = 0;   // Local Stop loss
            double lTP = 0;   // Local Take Profit
            if(!pullbackExtended && ModeOperation == PRICE_LEVEL){
            
               //  This because in this case 4 is 78% of pullback and is a posible reversion
               if(i < 4 && i > 0) {
                  if(onM1)
                     lSL = fiboLevelsM1[i + 1] + (volatility1 * 0.1);
                  
                  
                  else if(onM5)
                     lSL = fiboLevelsM5[i + 1] + (volatility5 * 0.1);
                     
                  
                  else if(onM15)
                     lSL = fiboLevelsM5[i + 1] + (volatility15 * 0.1);
                  
                  
                  if(onM1 || onM15 || onM5) lTP = actualPrice - (MathAbs(actualPrice - lSL) * FactorProfit);
                  
                  lSL = NormalizeDouble(lSL, Point());
                  lTP = NormalizeDouble(lTP, Point());
                  
               }
            }
            
            
            
            // Also verify scheduler of Not operation
            datetime dtSer=TimeCurrent(dt_struct);
            
            int cHour = dt_struct.hour;
            
            
            // 4.4.- Open positions (Also verify scheduler of Not operation and is enabled this position type)
            if(!pullbackExtended && enableShortPositions && ((NotOperationScheduler.enabled && !(cHour >= NotOperationScheduler.HourFrom && cHour <= NotOperationScheduler.HourTo)) || !NotOperationScheduler.enabled))
            {
               if(ModeOperation == TIME || (MathAbs(lTP) > 1 && MathAbs(lSL) > 1)){
                  if(test.TestingMode)
                     test.SendOrder(actualPrice, SELL, ModeOperation == TIME ? countBarsTimeTest : 0, lTP, lSL, ModeOperation);
                  
                  else
                     SendSellMarket(Latest_Price.ask, Lots, lTP, lSL);   
               }
            }

         
        }
         
        

    }


    Comment(displayData);
    prev_Price = actualPrice;

}






// Initialize indicators   
void InitializeIndicatorHandles(){
   
    EMA_M1_Fast_Handle = iMA(Symbol(), PERIOD_M1, 10, 0, MODE_EMA, PRICE_CLOSE);
    EMA_M1_Slow_Handle = iMA(Symbol(), PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE);

    EMA_M5_Fast_Handle = iMA(Symbol(), PERIOD_M5, 10, 0, MODE_EMA, PRICE_CLOSE);
    EMA_M5_Slow_Handle = iMA(Symbol(), PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);

    EMA_M15_Fast_Handle = iMA(Symbol(), PERIOD_M15, 10, 0, MODE_EMA, PRICE_CLOSE);
    EMA_M15_Slow_Handle = iMA(Symbol(), PERIOD_M15, 21, 0, MODE_EMA, PRICE_CLOSE);


    MA_M1_Volatility_Handle = iMA(Symbol(), PERIOD_M1, 7, 0, MODE_SMA, PRICE_CLOSE);
    MA_M5_Volatility_Handle = iMA(Symbol(), PERIOD_M5, 7, 0, MODE_SMA, PRICE_CLOSE);
    MA_M15_Volatility_Handle = iMA(Symbol(), PERIOD_M15, 7, 0, MODE_SMA, PRICE_CLOSE);
    
    MA_M1_MinSecuence_Handle = iMA(Symbol(), PERIOD_M1, 5, 0, MODE_SMA, PRICE_CLOSE);
    MA_M5_MinSecuence_Handle = iMA(Symbol(), PERIOD_M5, 5, 0, MODE_SMA, PRICE_CLOSE);
    MA_M15_MinSecuence_Handle = iMA(Symbol(), PERIOD_M15, 5, 0, MODE_SMA, PRICE_CLOSE);
}

// Return false if error
bool RefreshIndicators(){
   
    bool ErrorIndicator = false;



    ArraySetAsSeries(_ClosesBuffer, true);
    CopyClose(Symbol(), PERIOD_CURRENT, 0, 50, _ClosesBuffer);

    ArraySetAsSeries(_EMA_M1_Fast, true);
    ArraySetAsSeries(_EMA_M1_Slow, true);

    ArraySetAsSeries(_EMA_M5_Fast, true);
    ArraySetAsSeries(_EMA_M5_Slow, true);

    ArraySetAsSeries(_EMA_M15_Fast, true);
    ArraySetAsSeries(_EMA_M15_Slow, true);


    // Current
    ArraySetAsSeries(_HighsBuffer, true);
    ArraySetAsSeries(_LowsBuffer, true);
    ArraySetAsSeries(_OpensBuffer, true);

    // M15
    ArraySetAsSeries(_M15HighsBuffer, true);
    ArraySetAsSeries(_M15LowsBuffer, true);
    ArraySetAsSeries(_M15ClosesBuffer, true);
    ArraySetAsSeries(_M15OpensBuffer, true);

    // M5
    ArraySetAsSeries(_M5HighsBuffer, true);
    ArraySetAsSeries(_M5LowsBuffer, true);
    ArraySetAsSeries(_M5ClosesBuffer, true);
    ArraySetAsSeries(_M5OpensBuffer, true);


    // MAs for measure volatility
    ArraySetAsSeries(_MA_M1_Volat, true);
    ArraySetAsSeries(_MA_M5_Volat, true);
    ArraySetAsSeries(_MA_M15_Volat, true);
    
    // MAs for measure secuence
    ArraySetAsSeries(_MA_M1_MinSecuence, true);
    ArraySetAsSeries(_MA_M5_MinSecuence, true);
    ArraySetAsSeries(_MA_M15_MinSecuence, true);


    if (CopyBuffer(EMA_M1_Fast_Handle, 0, 0, SIZE_BUFFERS, _EMA_M1_Fast) < 0) { Print("CopyBuffer _EMA_M1_Fast_Handle Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(EMA_M1_Slow_Handle, 0, 0, SIZE_BUFFERS, _EMA_M1_Slow) < 0) { Print("CopyBuffer _EMA_M1_Slow_Handle error = ", GetLastError()); ErrorIndicator = true; }

    if (CopyBuffer(EMA_M5_Fast_Handle, 0, 0, SIZE_BUFFERS, _EMA_M5_Fast) < 0) { Print("CopyBuffer _EMA_M5_Fast_Handle Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(EMA_M5_Slow_Handle, 0, 0, SIZE_BUFFERS, _EMA_M5_Slow) < 0) { Print("CopyBuffer _EMA_M5_Slow_Handle error = ", GetLastError()); ErrorIndicator = true; }

    if (CopyBuffer(EMA_M15_Fast_Handle, 0, 0, SIZE_BUFFERS, _EMA_M15_Fast) < 0) { Print("CopyBuffer _EMA_M15_Fast_Handle Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(EMA_M15_Slow_Handle, 0, 0, SIZE_BUFFERS, _EMA_M15_Slow) < 0) { Print("CopyBuffer _EMA_M15_Slow_Handle error = ", GetLastError()); ErrorIndicator = true; }


    if (CopyBuffer(MA_M1_Volatility_Handle, 0, 0, SIZE_BUFFERS, _MA_M1_Volat) < 0) { Print("CopyBuffer MA_M1_Volatility_Handle Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(MA_M5_Volatility_Handle, 0, 0, SIZE_BUFFERS, _MA_M5_Volat) < 0) { Print("CopyBuffer MA_M5_Volatility_Handle error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(MA_M15_Volatility_Handle, 0, 0, SIZE_BUFFERS, _MA_M15_Volat) < 0) { Print("CopyBuffer MA_M15_Volatility_Handle Error = ", GetLastError()); ErrorIndicator = true; }
    
    if (CopyBuffer(MA_M1_MinSecuence_Handle, 0, 0, SIZE_BUFFERS, _MA_M1_MinSecuence) < 0) { Print("CopyBuffer MA_M1_MinSecuence_Handle Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(MA_M5_MinSecuence_Handle, 0, 0, SIZE_BUFFERS, _MA_M5_MinSecuence) < 0) { Print("CopyBuffer MA_M5_MinSecuence_Handle error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyBuffer(MA_M15_MinSecuence_Handle, 0, 0, SIZE_BUFFERS, _MA_M15_MinSecuence) < 0) { Print("CopyBuffer MA_M15_MinSecuence_Handle Error = ", GetLastError()); ErrorIndicator = true; }


    // Candlesticks
    if (CopyHigh(Symbol(), PERIOD_CURRENT, 1, SIZE_BUFFERS, _HighsBuffer) < 0) { Print("CopyHigh Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyLow(Symbol(), PERIOD_CURRENT, 1, SIZE_BUFFERS, _LowsBuffer) < 0) { Print("CopyLow Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyClose(Symbol(), PERIOD_CURRENT, 0, SIZE_BUFFERS, _ClosesBuffer) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyOpen(Symbol(), PERIOD_CURRENT, 0, SIZE_BUFFERS, _OpensBuffer) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }

    if (CopyHigh(Symbol(), PERIOD_M15, 1, SIZE_BUFFERS, _M15HighsBuffer) < 0) { Print("CopyHigh Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyLow(Symbol(), PERIOD_M15, 1, SIZE_BUFFERS, _M15LowsBuffer) < 0) { Print("CopyLow Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyClose(Symbol(), PERIOD_M15, 0, SIZE_BUFFERS, _M15ClosesBuffer) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyOpen(Symbol(), PERIOD_M15, 0, SIZE_BUFFERS, _M15OpensBuffer) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }

    if (CopyHigh(Symbol(), PERIOD_M5, 1, SIZE_BUFFERS, _M5HighsBuffer) < 0) { Print("CopyHigh Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyLow(Symbol(), PERIOD_M5, 1, SIZE_BUFFERS, _M5LowsBuffer) < 0) { Print("CopyLow Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyClose(Symbol(), PERIOD_M5, 0, SIZE_BUFFERS, _M5ClosesBuffer) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }
    if (CopyOpen(Symbol(), PERIOD_M5, 0, SIZE_BUFFERS, _M5OpensBuffer) < 0) { Print("CopyClose Historical Data Error = ", GetLastError()); ErrorIndicator = true; }

    if (ErrorIndicator) { Print("Error Indicator: ", GetLastError()); return false; }
    
    else return true;

}


//+------------------------------------------------------------------+



bool Uptrend(double& _EMA_Fast[],
    double& _EMA_Slow[],
    double price) {

    return (_EMA_Fast[1] > _EMA_Slow[1] && price > _EMA_Slow[1]) && _EMA_Fast[1] > _EMA_Fast[2] && _EMA_Slow[1] > _EMA_Slow[2];

}

bool Downtrend(double& _EMA_Fast[],
    double& _EMA_Slow[],
    double price) {

    return (_EMA_Fast[1] < _EMA_Slow[1] && price < _EMA_Slow[1]) && _EMA_Fast[1] < _EMA_Fast[2] && _EMA_Slow[1] < _EMA_Slow[2];

}


// Calculate volatility in $ based on a count of candlesticks
double CalculateVolatility(double& _Hights[],
    double& _Lows[],
    double& min, // output by reference
    double& max, // output by reference
    int count = 50) {



    int iMax = -1;
    int iMin = -1;
    bool firstIteration = true;;

    while ((iMax == -1 || iMax == count - 1) ||
        (iMin == -1 || iMin == count - 1))
    {
        if (!firstIteration) count++;

        iMax = ArrayMaximum(_Hights, 0, count);
        iMin = ArrayMinimum(_Lows, 0, count);

        firstIteration = false;
    }

    min = _Lows[iMin];
    max = _Hights[iMax];

    return max - min;

}


// Calculate volatility in $ using a SMA for identify max and min relevant 
double CalculateRelativeVolatility(double& _Hights[],
    double& _Lows[],
    double& _SMA[],
    double& min, // output by reference
    double& max, // output by reference

    // true = evaluate in context of a uptrend
    // false = evaluate in context of a downtrend
    bool trendType
) {

    int i = 1; // Count of candlesticks

    // Omite pullbacks
    while ((trendType && _SMA[i - 1] > _SMA[i]) || (!trendType && _SMA[i - 1] < _SMA[i]))
        i++;

    for (; i < SIZE_BUFFERS; i++)
    {
        if (trendType && _SMA[i - 1] > _SMA[i]) break;
        if (!trendType && _SMA[i - 1] < _SMA[i]) break;
    }

    i++;

    max = _Hights[ArrayMaximum(_Hights, 1, i)];
    min = _Lows[ArrayMinimum(_Lows, 1, i)];
    
    //Print("Max: " + DoubleToString(max,2) + ".  Min: " + DoubleToString(min,2) + ".    count: " + i);

    return max - min;

}


double Fibo_CalculatePullback(double volatility,
    double max,
    double percent // examples: 23.6, 38.2, 50.0, 61.8, 78.6
) {

    return max - (volatility * percent * 0.01);

}







