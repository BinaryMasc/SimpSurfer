//+------------------------------------------------------------------+
//|                                                  PowerSignal.mq5 |
//|                                                        BinaryDog |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "BinaryDog"
#property link      ""
#property version   "1.00"

input double Multiplier = 1; //  Factor multiplier

ulong positions[50];


int PositionsTotalLastTick;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   PositionsTotalLastTick = PositionsTotal();

   // Initialize array
   for(int i = 0; i < 50; i++) 
      positions[i] = 0;
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
   
   if(PositionsTotal() == PositionsTotalLastTick) return;
   
   else
   {
      for(int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket=PositionGetTicket(i);
         
         PositionSelectByTicket(ticket);
         
         
         if(StringFind(PositionGetString(POSITION_COMMENT), "Executed by PowerSignal") < 0)
         {
            
            // Find ticket in array of operations
            int positionFind = -1;
            
            for(int j = 0; j < 50 && positionFind < 0; j++)
            {
               if(ticket == positions[j]) positionFind = i;
            }
            
            if(positionFind > 0)
            {
               for(int j = 0; j < 50; j++)
               {
                  if(positions[j] < 1) 
                  {
                     positions[j] = ticket;
                     break;
                  }
               }
               
               //Open equivalent position
            }
            
         }
        
      }
   }
   
   PositionsTotalLastTick = PositionsTotal();
   
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   if(trans.deal_type = )
   
  }
//+------------------------------------------------------------------+
