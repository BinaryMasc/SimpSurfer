//+------------------------------------------------------------------+
//|                                             BinaryExtensions.mqh |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"

#include <Trade\Trade.mqh>

CTrade trade;

void SendBuyMarket(double price, double lots, double TP = 0, double SL = 0) {
    //Print("Buy order send...");
    
    //trade.Buy(lots, Symbol(), price, price -10, price +10, "Executed by BinaryExtensions.");
    trade.Buy(lots, Symbol(), price, SL, TP, "Executed by BinaryExtensions.");
}


void SendSellMarket(double price, double lots, double TP = 0, double SL = 0) {
    trade.Sell(lots, Symbol(), price, SL, TP, "Executed by BinaryExtensions.");
}

void CloseAllPositions(int positionsTotal)
{
   for(int i=positionsTotal-1; i>=0; i--)
   {
       ulong ticket=PositionGetTicket(i);
       trade.PositionClose(ticket);   
   }  
}


datetime Old_Time;
datetime New_Time;

bool isNewBar(ENUM_TIMEFRAMES pPeriod)
{
    New_Time = iTime(Symbol(), pPeriod, 0);

    if (New_Time != Old_Time)
    {
        Old_Time = New_Time;
        return true;
    }
    else return false;
}

void CloseOperationIfLossMoreThan(int maxLoss)
{
   
   int positionsCount = PositionsTotal();
   
   for(int i = 0; i < positionsCount; i++)
   {
      double profit = 0;
      
      ulong ticket=PositionGetTicket(i);
      
      PositionSelectByTicket(ticket);
       
      PositionGetDouble(POSITION_PROFIT, profit);
      
      if(profit < (maxLoss*-1)) trade.PositionClose(ticket);
   }
}



enum BinExt_ENUM_OperationType
{
   OperationType_NONE,
   OperationType_Buy,
   OperationType_Sell
};

class PlayAlertSignal
{
   public:
      void PlayAlert(BinExt_ENUM_OperationType pOPType = OperationType_NONE);
      bool PrintLogRegistry;
};

void PlayAlertSignal::PlayAlert(BinExt_ENUM_OperationType pOPType = OperationType_NONE)
{
   if(pOPType == OperationType_NONE) return;
   
   PlaySound("alert.wav");
   
   if(PrintLogRegistry) 
      Print("Alert to " + (pOPType == OperationType_Buy  ? "Buy" : "Sell") + " signal.");
}