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
   
   int ConsecutiveProfits;
   int ConsecutiveLoss;
   
   bool lastPostitionWinner;
   bool lastPostitionLosser;
   
   int MaxConsecutiveProfits;
   int MaxConsecutiveLoss;
   
   double AvgProfit;
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



// Constructor
void Testing::Testing(){

   
   
   openPrice = 0;
   openedPosition = false;
   Capital = 10000;
   
   PositionsInfo p1;
   p1.CountPositions = 0;
   p1.ProfitPositions = 0;
   p1.ConsecutiveProfits = 0;
   p1.ConsecutiveLoss = 0;
   
   PositionsInfo p2;
   p2.CountPositions = 0;
   p2.ProfitPositions = 0;
   p2.ConsecutiveProfits = 0;
   p2.ConsecutiveLoss = 0;
   
   
   p1.lastPostitionWinner = false;
   p1.lastPostitionLosser = false;
   p1.ConsecutiveLoss = 0;
   p1.ConsecutiveProfits = 0;
   p1.MaxConsecutiveLoss = 0;
   p1.MaxConsecutiveProfits = 0;
   p1.AvgProfit = 0;
   
   p2.lastPostitionWinner = false;
   p1.lastPostitionLosser = false;
   p2.ConsecutiveLoss = 0;
   p2.ConsecutiveProfits = 0;
   p2.MaxConsecutiveLoss = 0;
   p2.MaxConsecutiveProfits = 0;
   p2.AvgProfit = 0;
      
   
   longPositions = p1;
   shortPositions = p2;
}

void Testing::SendOrder(double price, TYPE_POSITION Type, int Time = 0, double TP = 0, double SL = 0, MODE_OPERATION pmode = PRICE_LEVEL) {
    if (!TestingMode || openedPosition) return;

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
   
   if(!openedPosition) return;
   
   bool winner = OpenedPositionType == BUY ? openPrice < actualPrice : (openPrice > actualPrice);
   
   if(winner){
   
      if(OpenedPositionType == BUY)
      {
         longPositions.ProfitPositions++;
         
         if (longPositions.lastPostitionWinner)
         {
            longPositions.ConsecutiveProfits++;
            
            if(longPositions.MaxConsecutiveProfits < longPositions.ConsecutiveProfits)
               longPositions.MaxConsecutiveProfits = longPositions.ConsecutiveProfits;
         }
         
         else longPositions.ConsecutiveProfits = 1;
         
         
         longPositions.lastPostitionWinner = true;
         longPositions.lastPostitionLosser = false;
      }
      
      else 
      {
         shortPositions.ProfitPositions++;
         
         if (shortPositions.lastPostitionWinner)
         {
            shortPositions.ConsecutiveProfits++;
            
            if(shortPositions.MaxConsecutiveProfits < shortPositions.ConsecutiveProfits)
               shortPositions.MaxConsecutiveProfits = shortPositions.ConsecutiveProfits;
         }
         
         else shortPositions.ConsecutiveProfits = 1;
         
         
         shortPositions.lastPostitionWinner = true;
         shortPositions.lastPostitionLosser = false;
      }
   }
   
   else 
   {
      if(OpenedPositionType == BUY)
      {
      
         if (longPositions.lastPostitionLosser)
         {
            longPositions.ConsecutiveLoss++;
            
            if(longPositions.MaxConsecutiveLoss < longPositions.ConsecutiveLoss)
               longPositions.MaxConsecutiveLoss = longPositions.ConsecutiveLoss;
         }
         
         else longPositions.ConsecutiveLoss = 1;
         
         
         longPositions.lastPostitionLosser = true;
         longPositions.lastPostitionWinner = false;
      }
      
      else
      {
      
         if (shortPositions.lastPostitionLosser)
         {
            shortPositions.ConsecutiveLoss++;
            
            if(shortPositions.MaxConsecutiveLoss < shortPositions.ConsecutiveLoss)
               shortPositions.MaxConsecutiveLoss = shortPositions.ConsecutiveLoss;
         }
         
         else shortPositions.ConsecutiveLoss = 1;
         
         
         shortPositions.lastPostitionLosser = true;
         shortPositions.lastPostitionWinner = false;
      }
   }
   
   
   
   openedPosition = false;

   double result = (MathAbs(actualPrice - openPrice) * (winner ? 1 : -1));
   
   if(OpenedPositionType == BUY)
      longPositions.AvgProfit = (longPositions.AvgProfit + result) / (longPositions.CountPositions == 1 ? 1 : 2);
      
   else
      shortPositions.AvgProfit = (shortPositions.AvgProfit + result) / (shortPositions.CountPositions == 1 ? 1 : 2);
   
   Capital += result;
   
   Print("Closed test \t" + 
        (OpenedPositionType == BUY ? "buy" : "sell") + "\t position  as \t" + (winner ? "winner" : "loser") + "\t: " + 
        DoubleToString(openPrice, 2) + " -> " + DoubleToString(actualPrice,2) + " ;" + DoubleToString(result) + ";" + DoubleToString(Capital + result, 2));
}



void Testing::ValidatePositions(double actualPrice){
   if(!openedPosition) return;
      
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
   
   if ((longPositions.CountPositions + shortPositions.CountPositions) > 0)
      Print("Total Profit positions: " + IntegerToString(longPositions.ProfitPositions + shortPositions.ProfitPositions) + " => " + DoubleToString(((longPositions.ProfitPositions + shortPositions.ProfitPositions) / (longPositions.CountPositions + shortPositions.CountPositions) * 100), 2) + " %");
   
   Print("Average profit: " + DoubleToString(longPositions.AvgProfit + shortPositions.AvgProfit, 2));
   
   
   Print("--");
   Print("-- Long positions Info --");
   Print("Total long positions: " + IntegerToString(longPositions.CountPositions));
   if (longPositions.CountPositions > 0) 
      Print("Total Profit long positions: " + IntegerToString(longPositions.ProfitPositions) + " => " + DoubleToString(((longPositions.ProfitPositions) / (longPositions.CountPositions)) * 100.0, 2) + " %");
   Print("Max consecutive wins: " + IntegerToString(longPositions.MaxConsecutiveProfits));
   Print("Max consecutive loss: " + IntegerToString(longPositions.MaxConsecutiveLoss));
   Print("Average profit: " + DoubleToString(longPositions.AvgProfit, 2));
   
   Print("--");
   Print("-- Short positions Info --");
   Print("Total short positions: " + IntegerToString(shortPositions.CountPositions));
   if (shortPositions.CountPositions > 0)
      Print("Total Profit short positions: " + IntegerToString(shortPositions.ProfitPositions) + " => " + DoubleToString((shortPositions.ProfitPositions / shortPositions.CountPositions) * 100.0, 2) + " %");
   Print("Max consecutive wins: " + IntegerToString(shortPositions.MaxConsecutiveProfits));
   Print("Max consecutive loss: " + IntegerToString(shortPositions.MaxConsecutiveLoss));
   Print("Average profit: " + DoubleToString(shortPositions.AvgProfit, 2));

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



