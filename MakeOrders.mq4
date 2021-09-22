//+------------------------------------------------------------------+
//|                                                   MakeOrders.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql4.com |
//+------------------------------------------------------------------+
#property strict

struct SGeoPoint{
   double latitude;
   double longitude;
   string refer;
   string adress;
   string client;
   SGeoPoint(){}
   SGeoPoint(string &data[]){
      latitude=StringToDouble(data[4]);
      longitude=StringToDouble(data[5]);
      refer=data[0];
      adress=data[3];
      client=data[6];
   }
   bool operator !() {return latitude<=0.0||longitude<=0.0||client=="<Пустая строка>";}
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
   SGeoPoint point[];
   if (!MakePoints(depotsInfo,point)) return;
}
//------------------------------------------------------------------------
bool MakePoints(string &depotsInfo[],SGeoPoint &point[]){
   if (ArrayResize(point,ArraySize(depotsInfo))!=ArraySize(depotsInfo)){
      Alert("Alloc error");
      return false;
   }
   int ii=0;
   for (int i=0;i<ArraySize(depotsInfo);++i){
      string data[];
      if (StringSplit(depotsInfo[i],';',data)!=7){
         Alert("Error data in depots.csv");
         return false;
      }
      SGeoPoint it(data);
      if (!it) continue;
      point[ii++]=it;
   }
   ArrayResize(point,ii);
   return true;
}