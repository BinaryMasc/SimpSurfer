//+------------------------------------------------------------------+
//|                                                   BinaryTest.mqh |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"



enum MODE_OPERATION {
    PRICE_LEVEL = 0,
    TIME = 1
};

enum TYPE_POSITION {
    BUY = 0,
    SELL = 1
};

struct PositionsInfo
{
   int CountPositions;
   int ProfitPositions;
};

struct NotOperateHour{
   bool enabled;
   int HourFrom;
   int HourTo;
};








class Testing
{
public:
   bool TestingMode;
   bool openedPosition;
   TYPE_POSITION OpenedPositionType;
   double Capital;
   
   
   
   
   double openPrice;
   double SL_Level;  //    If MODE_OPERATION = PRICE_LEVEL, configure (not mandatary)
   double TP_Level;  //    If MODE_OPERATION = PRICE_LEVEL, configure (not mandatary)
   int TimeElapsed; //    On current period bars 
   int TimeLimit;   //    If MODE_OPERATION = TIME, configure
   
   PositionsInfo shortPositions;
   PositionsInfo longPositions;

   MODE_OPERATION mode;
   
   // Constructor
   void Testing(void);
   
   void SendOrder(double price, TYPE_POSITION Type, int Time = 0, double TP = 0, double SL = 0, MODE_OPERATION mode = PRICE_LEVEL);
   void ValidatePositions(double actualPrice);
   void ClosePosition(double actualPrice);
   void PrintAllTestInfo();
};




void Testing::Testing(){

   openPrice = 0;
   openedPosition = false;
   Capital = 10000;
   
   PositionsInfo p1;
   p1.CountPositions = 0;
   p1.ProfitPositions = 0;
   
   PositionsInfo p2;
   p2.CountPositions = 0;
   p2.ProfitPositions = 0;
   
   longPositions = p1;
   shortPositions = p2;
}

void Testing::SendOrder(double price, TYPE_POSITION Type, int Time = 0, double TP = 0, double SL = 0, MODE_OPERATION pmode = PRICE_LEVEL) {
    if (!TestingMode) return;

    openedPosition = true;
    openPrice = price;
    mode = pmode;
    TimeElapsed = 0;
    TimeLimit = Time;
    
    if(Type == BUY){
      longPositions.CountPositions++;
      OpenedPositionType = BUY;
    }
    
    else{
      shortPositions.CountPositions++;
      OpenedPositionType = SELL;
    }
    
    
    //Print("Opened " + (OpenedPositionType == BUY ? "buy" : "sell") + " TEST position #" + IntegerToString(longPositions.CountPositions + shortPositions.CountPositions) + " at " + DoubleToString(price, 2) + " with mode " + pmode);
   
}

void Testing::ClosePosition(double actualPrice){
   
   bool winner = OpenedPositionType == BUY ? openPrice < actualPrice : (openPrice > actualPrice);
   
   if(winner){
   
      if(OpenedPositionType == BUY)
         longPositions.ProfitPositions++;
      
      else shortPositions.ProfitPositions++;
   
   }
   
   openedPosition = false;

   double result = (MathAbs(actualPrice - openPrice) * (winner ? 1 : -1));
   
   Capital += result;
   
   Print("Closed test \t" + 
        (OpenedPositionType == BUY ? "buy" : "sell") + "\t position  as \t" + (winner ? "winner" : "loser") + "\t: " + 
        DoubleToString(openPrice,2) + " -> " + DoubleToString(actualPrice,2) + " ;" + DoubleToString(result) + ";" + DoubleToString(Capital + result, 2));
}



void Testing::ValidatePositions(double actualPrice){
   if(!openedPosition) return;
      
   //Print("Mode: " + mode + ". elapsed: " + IntegerToString(TimeElapsed) + ". Limit: " + IntegerToString(TimeLimit));
      
   if(mode == TIME){
   
      if(TimeElapsed >= TimeLimit)
         ClosePosition(actualPrice);
         
      else return;
   }
   
   else {
      if((OpenedPositionType == BUY && (actualPrice >= TP_Level || actualPrice <= SL_Level)) ||
         (OpenedPositionType == SELL && (actualPrice <= TP_Level || actualPrice >= SL_Level)))
            ClosePosition(actualPrice);
         
   }
}


void Testing::PrintAllTestInfo(){
   Print("----Test report----");
   Print("Final balance: " + DoubleToString(Capital, 2));
   Print("Total positions: " + IntegerToString(longPositions.CountPositions + shortPositions.CountPositions));
   Print("Total Profit positions: " + IntegerToString(longPositions.ProfitPositions + shortPositions.ProfitPositions) + " => " + DoubleToString(((longPositions.ProfitPositions + shortPositions.ProfitPositions) / (longPositions.CountPositions + shortPositions.CountPositions) * 100), 2) + " %");
   
   Print("-- Long positions Info --");
   Print("Total long positions: " + IntegerToString(longPositions.CountPositions));
   Print("Total Profit long positions: " + IntegerToString(longPositions.ProfitPositions) + " => " + DoubleToString(((longPositions.ProfitPositions) / (longPositions.CountPositions)) * 100, 2) + " %");
   
   Print("-- Short positions Info --");
   Print("Total short positions: " + IntegerToString(shortPositions.CountPositions));
   Print("Total Profit short positions: " + IntegerToString(shortPositions.ProfitPositions) + " => " + DoubleToString(((shortPositions.ProfitPositions) / (shortPositions.CountPositions)) * 100, 2) + " %");
}

/*
enum MODE_OPERATION {
    PRICE_LEVEL = 0,
    TIME = 1
};

struct PositionsInfo
{
   int CountPositions;
   int ProfitPositions;
};


struct Testing 
{
   bool TestingMode;
   bool openedPosition;
   
   double openPrice;
   double SL_Level;  //    If MODE_OPERATION = PRICE_LEVEL, configure (not mandatary)
   double TP_Level;  //    If MODE_OPERATION = PRICE_LEVEL, configure (not mandatary)
   int TimeElapsed; //    On current period bars 
   int TimeLimit;   //    If MODE_OPERATION = TIME, configure
   
   PositionsInfo shortPositions;
   PositionsInfo longPositions;

   MODE_OPERATION mode;
};


void SendBuyTestOrder(double price, int Time = 0, double TP = 0, double SL = 0, MODE_OPERATION mode = PRICE_LEVEL) {
    if (!iTest.TestingMode) return;

    test.openedPosition = true;
    test.openPrice = price;
    test.longPositions.CountPositions++;
}

void SendSellTestOrder(double price, double TP = 0, double SL = 0) {
    if (!test.TestingMode) return;
   
   // TODO: Pending!
}



void InitializeTestStructure(){
   test.openPrice = 0;
   test.openedPosition = false;
   
   PositionsInfo p1;
   p1.CountPositions = 0;
   p1.ProfitPositions = 0;
   
   PositionsInfo p2;
   p2.CountPositions = 0;
   p2.ProfitPositions = 0;
   
   test.longPositions = p1;
   test.shortPositions = p2;
   
   
}*/



