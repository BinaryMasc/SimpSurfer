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

void CloseAllPositions()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
       ulong ticket=PositionGetTicket(i);
       trade.PositionClose(ticket);   
   }  
}


datetime Old_Time;
datetime New_Time;

bool isNewBar()
{
    New_Time = iTime(Symbol(), PERIOD_CURRENT, 0);

    if (New_Time != Old_Time)
    {
        Old_Time = New_Time;
        return true;
    }
    else return false;
}
