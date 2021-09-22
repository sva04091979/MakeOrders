//+------------------------------------------------------------------+
//|                                                   MakeOrders.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql4.com |
//+------------------------------------------------------------------+
#property strict

struct SGeoPoint{
   double latitude;
   double longitude;
   string name;
   bool operator !() {return latitude<=0.0||longitude<=0.0;}
};

void OnStart()
  {
   int tripsFile=FileOpen("ILS/trips.csv",FILE_READ|FILE_TXT);
   int depotsFile=FileOpen("ILS/depots.csv",FILE_READ|FILE_TXT);
   if (tripsFile==INVALID_HANDLE){
      Alert("trips.csv open error");
      return;
   }
   if (depotsFile==INVALID_HANDLE){
      Alert("depots.csv open error");
      return;
   }
   string trips[];
   if (!ReadFile(tripsFile,trips)) return;
   string depots[];
   if (!ReadFile(depotsFile,depots)) return;
   FileClose(tripsFile);
   FileClose(depotsFile);
   MakeFiles(trips,depots);
  }
//+------------------------------------------------------------------+
bool ReadFile(int hndl,string &data[]){
   uint size=0;
   uint i=0;
   FileReadString(hndl);
   while(!FileIsEnding(hndl)){
      ++size;
      if (ArrayResize(data,size)!=size){
         Alert("Alloc error");
         return false;
      }
      data[i++]=FileReadString(hndl);
   }
   return true;
}
//--------------------------------------------------------------------
void MakeFiles(string &trips[],string &depotsInfo[]){
   int carsFile=FileOpen("ILS/Result/vehicle.csv",FILE_WRITE|FILE_TXT);
   int depotsFile=FileOpen("ILS/Result/depot.csv",FILE_WRITE|FILE_TXT);
   int ordersFile=FileOpen("ILS/Result/order.csv",FILE_WRITE|FILE_TXT);
   if (carsFile==INVALID_HANDLE){
      Alert("vehicle.csv create error");
      return;
   }
   if (depotsFile==INVALID_HANDLE){
      Alert("depot.csv create error");
      return;
   }
   if (ordersFile==INVALID_HANDLE){
      Alert("order.csv create error");
      return;
   }
   SGeoPoint rawPoint[];
   if (!MakeRawPoints(depotsInfo,rawPoint)) return;
}
//------------------------------------------------------------------------
bool MakeRawPoints(string &depotsInfo[],SGeoPoint &rawPoint[]){
   if (ArrayResize(rawPoint,ArraySize(depotsInfo))!=ArraySize(depotsInfo)){
      Alert("Alloc error");
      return false;
   }
   for (int i=0;i<ArraySize(depotsInfo);++i){
      string data[];
      if (StringSplit(depotsInfo[i],';',data)!=5){
         Alert("Error data in depots.csv");
         return false;
      }
      rawPoint
   }
   return true;
}