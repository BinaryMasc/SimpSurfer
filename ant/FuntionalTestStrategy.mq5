//+------------------------------------------------------------------+
//|                                        FuntionalTestStrategy.mq5 |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>


//--- input parameters

//input 
double   FactorLoss = 0.5; // Factor Loss:  Loss/Profit. 
input 
double   Lots = 1;
//input int      offset = 10;
input bool     CalculateInNewBar = true;
input int      riskRespectVolatility = 60;

//int offset = 15;



// MA handles
int EMA_M1_Fast_Handle;
int EMA_M1_Slow_Handle;

int EMA_M5_Fast_Handle;
int EMA_M5_Slow_Handle;

int EMA_M15_Fast_Handle;
int EMA_M15_Slow_Handle;

int EMA_CURR_Fast_Handle;
int EMA_CURR_Slow_Handle;




int eventsCountBull;
int favorableEventsCountBull;

int eventsCountBear;
int favorableEventsCountBear;

int totalPositions;
int winnerPositions;

bool positionOpen;
bool positionType; //   true: buy. false: sell   
double positionPrice;
double positionVolatility;

double ibalance;


CTrade trade;


// Expert initialization function                                   
int OnInit()
{
   positionOpen = false;
   totalPositions = 0;
   winnerPositions = 0;
   

   eventsCountBull = 0;
   favorableEventsCountBull = 0;
   
   eventsCountBear = 0;
   favorableEventsCountBear = 0;
   
   ibalance = 10000;

   
   // Initialize indicators   
   EMA_M1_Fast_Handle  = iMA(Symbol(),PERIOD_M1, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_M1_Slow_Handle  = iMA(Symbol(),PERIOD_M1, 21,0,MODE_EMA,PRICE_CLOSE);
   
   EMA_M5_Fast_Handle  = iMA(Symbol(),PERIOD_M5, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_M5_Slow_Handle  = iMA(Symbol(),PERIOD_M5, 21,0,MODE_EMA,PRICE_CLOSE);
   
   EMA_M15_Fast_Handle  = iMA(Symbol(),PERIOD_M15, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_M15_Slow_Handle  = iMA(Symbol(),PERIOD_M15, 21,0,MODE_EMA,PRICE_CLOSE);
   
   EMA_CURR_Fast_Handle  = iMA(Symbol(),PERIOD_CURRENT, 10,0,MODE_EMA,PRICE_CLOSE);
   EMA_CURR_Slow_Handle  = iMA(Symbol(),PERIOD_CURRENT, 21,0,MODE_EMA,PRICE_CLOSE);
  
  
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   
}


// Expert tick function                                             
void OnTick()
{

   double _ClosesBuffer[];
   ArraySetAsSeries(_ClosesBuffer, true);
   CopyClose(Symbol(),PERIOD_CURRENT,0,50, _ClosesBuffer);
   VerifyPositions(_ClosesBuffer[0]);
   
   // Verify is new bar OnTick
   bool newbar = isNewBar();
   if(!newbar && CalculateInNewBar) return;
   
   
   
   
   // else...
   
   
   // Initialize Arrays indicators
   
   // Buffers 
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
          _M5OpensBuffer[];
          
   //

   bool ErrorIndicator = false;

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
   
   
   
   if (CopyBuffer(EMA_M1_Fast_Handle,0,0,50,_EMA_M1_Fast) < 0)  {Print("CopyBuffer _EMA_M1_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_M1_Slow_Handle,0,0,50,_EMA_M1_Slow) < 0)  {Print("CopyBuffer _EMA_M1_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   if (CopyBuffer(EMA_M5_Fast_Handle,0,0,50,_EMA_M5_Fast) < 0)  {Print("CopyBuffer _EMA_M1_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_M5_Slow_Handle,0,0,50,_EMA_M5_Slow) < 0)  {Print("CopyBuffer _EMA_M1_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   if (CopyBuffer(EMA_M15_Fast_Handle,0,0,50,_EMA_M15_Fast) < 0)  {Print("CopyBuffer _EMA_M1_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_M15_Slow_Handle,0,0,50,_EMA_M15_Slow) < 0)  {Print("CopyBuffer _EMA_M1_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   if (CopyBuffer(EMA_CURR_Fast_Handle,0,0,50,_EMA_CURR_Fast) < 0)  {Print("CopyBuffer _EMA_M1_Fast_Handle Error = ",GetLastError()); ErrorIndicator = true;}
   if (CopyBuffer(EMA_CURR_Slow_Handle,0,0,50,_EMA_CURR_Slow) < 0)  {Print("CopyBuffer _EMA_M1_Slow_Handle error = ",GetLastError()); ErrorIndicator = true;}
   
   
   // Candlesticks
   if (CopyHigh(Symbol(),PERIOD_CURRENT, 1,50, _HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyLow(Symbol(), PERIOD_CURRENT, 1,50, _LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyClose(Symbol(),PERIOD_CURRENT,0,50, _ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyOpen(Symbol(),PERIOD_CURRENT,0, 50, _OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   
   if (CopyHigh(Symbol(),PERIOD_M15, 1,50, _M15HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyLow(Symbol(), PERIOD_M15, 1,50, _M15LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyClose(Symbol(),PERIOD_M15,0,50, _M15ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyOpen(Symbol(),PERIOD_M15,0, 50, _M15OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   
   if (CopyHigh(Symbol(),PERIOD_M5, 1,50, _M5HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyLow(Symbol(), PERIOD_M5, 1,50, _M5LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyClose(Symbol(),PERIOD_M5,0,50, _M5ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   if (CopyOpen(Symbol(),PERIOD_M5,0, 50, _M5OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError());ErrorIndicator = true;}
   
   if(ErrorIndicator){ Print("Error Indicator: ", GetLastError()); return;}
   
   //---
   
   //int offset = 10;
   
   
   
   if(Uptrend(_EMA_CURR_Fast, _EMA_CURR_Slow, _ClosesBuffer[0], 0) && 
      Uptrend(_EMA_M15_Fast, _EMA_M15_Slow, _M15ClosesBuffer[0], 0) && 
      Uptrend(_EMA_M5_Fast, _EMA_M5_Slow, _M5ClosesBuffer[0], 0) &&
      false
      ){
      
      
      double volatility = CalculateVolatility(_HighsBuffer,_LowsBuffer) * riskRespectVolatility;
      
      if(!positionOpen)
         OpenPosition(_ClosesBuffer[0], true, volatility);
      
      //SendTrade(Symbol(), 0,volatility,volatility);
      
      /*
      eventsCountBull++;
      
      if(_ClosesBuffer[offset] < _ClosesBuffer[0]) favorableEventsCountBull++;
      
      printf("Bull: " + favorableEventsCountBull + "/" + eventsCountBull + "=" + ((float)favorableEventsCountBull/eventsCountBull));
      printf("Total: " + (((float)favorableEventsCountBear + favorableEventsCountBull)/ ((float)eventsCountBear + eventsCountBull)) );
      
      */
   }
   
   else if(Downtrend(_EMA_CURR_Fast, _EMA_CURR_Slow, _ClosesBuffer[0], 0) && 
           Downtrend(_EMA_M15_Fast, _EMA_M15_Slow, _M15ClosesBuffer[0], 0) &&
           Downtrend(_EMA_M5_Fast, _EMA_M5_Slow, _M5ClosesBuffer[0], 0) ){
           
           
      double volatility = CalculateVolatility(_HighsBuffer,_LowsBuffer) * riskRespectVolatility;
      
      if(!positionOpen)
         OpenPosition(_ClosesBuffer[0], false, volatility);
      
      //SendTrade(Symbol(), 1, volatility,volatility);
      
      //printf("SL: " + (_ClosesBuffer[0] - volatility));
           
           
      /*
      eventsCountBear++;
      
      if(_ClosesBuffer[offset] > _ClosesBuffer[0]) favorableEventsCountBear++;
      
      printf("Bear: " + favorableEventsCountBear + "/" + eventsCountBear + "=" + ((float)favorableEventsCountBear/(float)eventsCountBear));
      printf("Total: " + (((float)favorableEventsCountBear + (float)favorableEventsCountBull)/ ((float)eventsCountBear + (float)eventsCountBull)) );
      */
   
   }
   
}



// ChartEvent function                                              
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   
}



// Verify positions to close
void VerifyPositions(double price){
   if(positionOpen){
   
      double variation = (price - positionPrice) * 100;
      bool winner = false;
      
      
      if(positionType){
         if(variation > positionVolatility){
            winnerPositions++;
            winner = true;
            positionOpen = false;
         }
         else if(variation < -positionVolatility*FactorLoss) positionOpen = false;
      }
      
      else{
         
         variation = (positionPrice - price)* 100;
         
         if(variation > positionVolatility){
            winnerPositions++;
            winner = true;
            positionOpen = false;
         }
         else if(variation < -positionVolatility*FactorLoss) positionOpen = false;
      }
      
      /*
      if(variation >=  positionVolatility) {
         winnerPositions++;
         winner = true;
         positionOpen = false;
      }
      
      if(variation <=  positionVolatility) 
         positionOpen = false;
        */ 
         
         
      if(!positionOpen) {
         
         double target = 2;// Percent
      
         ibalance += (winner ? (10) : (10*-FactorLoss));//((winner ? (ibalance) : (-ibalance*FactorLoss))*target*0.01);
         //printf("Closed Position #" + totalPositions + " as " + (winner ? "winner": "loser"));
         //printf(winnerPositions + "/" + totalPositions + "\tbalance: " + ibalance);
         printf(ibalance);
         
      }
   }
}

void OpenPosition(double OpenPrice, bool type, double Volatility){

   positionOpen = true;
   positionVolatility = Volatility;
   positionPrice = OpenPrice;
   positionType = type;
   
   totalPositions++;
   
   //printf("Opened " + (type ? "buy" : "sell") + " position in " + OpenPrice + ".  Volatility: " + Volatility);
}


//+------------------------------------------------------------------+

bool Uptrend(double &_EMA_Fast[],
             double &_EMA_Slow[],
             double price,
             int offset = 10){
   
   
   
   bool trend = _EMA_Fast[offset] > _EMA_Slow[offset] && price > _EMA_Slow[offset];
   
   for(int i = offset; i < 5 + offset && trend; i++) 
   {
      if(i == 0 || _EMA_Fast[i] <= _EMA_Fast[i-1]) continue;
      
      else trend = false;
   }
   
   for(int i = offset; i < 5 + offset && trend; i++) 
   {
      if(i == 0 || _EMA_Slow[i] <= _EMA_Slow[i-1]) continue;
      
      else trend = false;
   }
   
   return trend;
   
}

bool Downtrend(double &_EMA_Fast[],
               double &_EMA_Slow[],
               double price,
               int offset = 10){
   
   bool trend = _EMA_Fast[offset] < _EMA_Slow[offset] && price < _EMA_Slow[offset];
   
   for(int i = 1; i < 5 && trend; i++) 
   {
      if(i == 0 || _EMA_Fast[i] >= _EMA_Fast[i-1]) continue;
      
      else trend = false;
   }
   
   for(int i = offset; i < 5 + offset && trend; i++) 
   {
      if(i == 0 || _EMA_Slow[i] >= _EMA_Slow[i-1]) continue;
      
      else trend = false;
   }
   
   return trend;
   
}












double CalculateVolatility(double &_Hights[], double &_Lows[], int count = 50){
   
   double max = 0, min = 999999999;
   
   for(int i = 0; i < count; i++) {
      if(max < _Hights[i]) max = _Hights[i];
      if(min > _Lows[i]) min = _Lows[i];
   }
   
   return max - min;
   
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


