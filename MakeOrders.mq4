//+------------------------------------------------------------------+
//|                                                   MakeOrders.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql4.com |
//+------------------------------------------------------------------+
#property strict

#define PI 3.141592653589
#define EARTH_RADIUS 6371.009
#define _DAY_ (60*60*24)
#define SPEED 80

struct SGeoPoint{
   double latitude;
   double longitude;
   string refer;
   string adress;
   string client;
   SGeoPoint():latitude(0.0){}
   SGeoPoint(string &data[]){
      StringReplace(data[4],",",".");
      StringReplace(data[5],",",".");
      latitude=StringToDouble(data[4]);
      longitude=StringToDouble(data[5]);
      refer=data[0];
      adress=data[3];
      client=data[6];
   }
   bool operator !() {return latitude<=0.0||longitude<=0.0;}
};

struct SOrder{
   int source;
   int target;
   datetime begin;
   datetime end;
   double volume;
   double price;
   string client;
   double loadStart;
   double loadEnd;
   double unloadStart;
   double unloadEnd;
   SOrder():source(-1){}
};

struct SCar{
   string car;
   SOrder first;
   SOrder last;
   SGeoPoint home;
   int homeDepot;
   double minVal;
   double maxVal;
   double speed;
   double startDate;
   double maxDurationRoute;
   int orders[];
   datetime timeStart;
   datetime timeEnd;
   SCar():minVal(EMPTY_VALUE),maxVal(0.0),speed(SPEED){}
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
      if (!Resize(data,++size)) return false;
      data[i++]=FileReadString(hndl);
   }
   return true;
}
//--------------------------------------------------------------------
void MakeFiles(string &trips[],string &depotsInfo[]){
   SGeoPoint point[];
   if (!MakePoints(depotsInfo,point)) return;
   SCar car[];
   SOrder order[];
   if (!MakeData(trips,point,car,order)) return;
   ComputeParam(car,order,point);
   int carsFile=FileOpen("ILS/Result/Vehicle.txt",FILE_WRITE|FILE_TXT);
   int depotsFile=FileOpen("ILS/Result/Depot.txt",FILE_WRITE|FILE_TXT);
   int ordersFile=FileOpen("ILS/Result/Order.txt",FILE_WRITE|FILE_TXT);
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
   string line="ID\tName\tLatitude\tLongitude\n";
   char arr[];
   for (int i=0;i<ArraySize(point);++i){
      line+=StringFormat("%i\t"      //ID
                        "%s\t"      //Name
                        "%.6f\t"    //Latitude
                        "%.6f\n",   //Longitude
         i,
         point[i].adress,
         point[i].latitude,
         point[i].longitude);
   }
   FileWriteString(depotsFile,line);
   line="ID\tSourceID\tTargetID\tMass\tLoadDate\tUnloadDate\tLoadStart\tLoadEnd\tUnloadStart\tUnloadEnd\tDeliveryDayLimit\n";
   for (int i=0;i<ArraySize(order);++i){
      string timeBegin=TimeToString(order[i].begin,TIME_DATE);
      string timeEnd=TimeToString(order[i].end,TIME_DATE);
      StringReplace(timeBegin,".","-");
      StringReplace(timeEnd,".","-");
      line+=StringFormat("%i\t"      //ID
                        "%i\t"      //SourceID
                        "%i\t"      //TargetID
                        "%.2f\t"    //Mass
                        "%s\t"      //LoadDate
                        "%s\t"      //UnloadDate
                        "%.6f\t"    //LoadStart
                        "%.6f\t"    //LoadEnd
                        "%.6f\t"    //UnloadStart
                        "%.6f\t"    //UnloadEnd
                        "%i\n",     //DeliveryDayLimit
         i,
         order[i].source,
         order[i].target,
         order[i].volume,
         timeBegin,
         timeEnd,
         order[i].loadStart,
         order[i].loadEnd,
         order[i].unloadStart,
         order[i].unloadEnd,
         (int)1
      );
   }
   FileWriteString(ordersFile,line);
   line="ID\tName\tStartDepotID\tMaxMass\tStartDate\tMaxDurationRoute\tAverageSpeed\n";
   for (int i=0;i<ArraySize(car);++i){
      string timeBegin=TimeToString(car[i].timeStart,TIME_DATE);
      StringReplace(timeBegin,".","-");
      line+=StringFormat("%i\t"      //ID
                        "%s\t"      //Name
                        "%i\t"      //StartDepotID
                        "%.2f\t"    //MaxMass
                        "%s\t"      //StartDate
                        "%.6f\t"    //MaxDurationRoute
                        "%.2f\n\0",   //AverageSpeed
         i,
         car[i].car,
         car[i].homeDepot,
         car[i].maxVal,
         timeBegin,
         car[i].maxDurationRoute,
         car[i].speed
      );
   }
   FileWriteString(carsFile,line);
   FileClose(carsFile);
   FileClose(depotsFile);
   FileClose(ordersFile);
}
//------------------------------------------------------------------------
bool MakePoints(string &depotsInfo[],SGeoPoint &point[]){
   if (!Resize(point,ArraySize(depotsInfo))) return false;
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
//--------------------------------------------------------------------------
bool MakeData(string &trips[],SGeoPoint &point[],SCar &car[],SOrder &order[]){
   int iCar=0;
   int iOrder=ArraySize(order);
   for (int j=0;j<ArraySize(trips);++j){
      string data[];
      if (StringSplit(trips[j],';',data)!=10){
         Alert("Error data in trips.csv");
         continue;
      }
      string client=data[1];
      int pnt[];
      if (!GetPoints(data[9],client,point,pnt))
         continue;
      SOrder ord[];
      if (!MakeOrders(data,pnt,ord)) continue;
      if (!Resize(order,ArraySize(order)+ArraySize(ord))) return false;
      int carID=CarFind(data[7],car);
      if (carID==-1){
         carID=ArraySize(car);
         if (!Resize(car,carID+1)) return false;
         car[carID].car=data[7];
         car[carID].first=ord[0];
      }
      car[carID].last=ord[ArraySize(ord)-1];
      for (int jj=0;jj<ArraySize(ord);++jj){
         order[iOrder++]=ord[jj];
         car[carID].minVal=MathMin(ord[jj].volume,car[carID].minVal);
         car[carID].maxVal=MathMax(ord[jj].volume,car[carID].maxVal);
      }
   }
   return true;
}
//------------------------------------------------------------------------------
template<typename Type>
bool Resize(Type &arr[],int size){
   if (ArrayResize(arr,size)!=size){
      Alert("Alloc error");
      return false;
   }
   else return true;
}
//------------------------------------------------------------------------------
int CarFind(string car,SCar &cars[]){
   for (int i=0;i<ArraySize(cars);++i){
      if (car==cars[i].car) return i;
   }
   return -1;
}
//-----------------------------------------------------------------------------------
bool GetPoints(string points,string client, const SGeoPoint &gPoints[],int &pointID[]){
   int i=-1;
   int id=0;
   string pnt=NULL;
   while (-1!=(i=StringFind(points," - "))){
      pnt=StringSubstr(points,0,i);
      points=StringSubstr(points,i+3);
      int j=PointFind(pnt,client,gPoints);
      if (j==-1) return false;
      if(!Resize(pointID,id+1)) return false;
      pointID[id++]=j;
   }
   if (!id) return false;
   int j=PointFind(points,client,gPoints);
   if (j==-1) return false;
   if(!Resize(pointID,id+1)) return false;
   pointID[id]=j;
   return true;
}
//----------------------------------------------------------------------------------
int PointFind(string point,string client,const SGeoPoint& gp[]){
   int res=-1;
   for (int i=0;i<ArraySize(gp);++i){
      if (point!=gp[i].refer) continue;
      if (client==gp[i].client) return i;
      else if (res==-1) res=i;
   }
   return res;
}
//------------------------------------------------------------------------------------
bool MakeOrders(const string &data[],const int &pnt[],SOrder &ord[]){
   if (!Resize(ord,ArraySize(pnt)-1)) return false;
   string time[];
   if (StringSplit(data[3],'-',time)!=2)
      return false;
   for (int i=0;i<ArraySize(ord);++i){
      ord[i].source=pnt[i];
      ord[i].target=pnt[i+1];
      ord[i].client=data[1];
      ord[i].volume=StringToDouble(data[8]);
      ord[i].price=StringToDouble(data[4]);
      ord[i].begin=StringToTime(time[0]);
      ord[i].end=StringToTime(time[1]);
   }
   return true;
}
//---------------------------------------------------------------------------------------
void ComputeParam(SCar& car[],SOrder& order[],const SGeoPoint& gp[]){
   int gpNumber=ArraySize(gp);
   for (int i=0;i<ArraySize(car);++i){
      car[i].homeDepot=MathRand()%gpNumber;
      car[i].home=gp[car[i].homeDepot];
      double firstDistance=Distance(car[i].home,gp[car[i].first.source]);
      double lastDistance=Distance(car[i].home,gp[car[i].last.target]);
      car[i].timeStart=(car[i].first.begin-int(firstDistance/car[i].speed*3600))/_DAY_*_DAY_;
      car[i].timeEnd=(car[i].last.end+int(lastDistance/car[i].speed*3600))/_DAY_*_DAY_+_DAY_;
   }
   for (int i=0;i<ArraySize(order);++i){
      order[i].loadStart=0.0;
      order[i].loadEnd=0.99;
      order[i].unloadStart=0.0;
      order[i].unloadEnd=0.99;
   }
   for (int i=0;i<ArraySize(car);++i){
      car[i].maxDurationRoute=double(car[i].timeEnd+_DAY_-car[i].timeStart)/_DAY_;
   }
}
//-----------------------------------------------------------------------------------------
double Distance(const SGeoPoint& l,const SGeoPoint& r){
   double lat1 = radians(l.latitude);
    double lat2 = radians(r.latitude);
    double lat_degree = radians(r.latitude - l.latitude);
    double lon_degree = radians(r.longitude - l.longitude);
    double a = sin(lat_degree/2.0) * sin(lat_degree/2.0) + cos(lat1) * cos(lat2) * sin(lon_degree /2.0) * sin(lon_degree /2.0);
    double c = 2.0 * atan(sqrt(a)/sqrt(1.0-a));
    
    return EARTH_RADIUS * c;
}
//-------------------------------------------------------------------------------------------
double radians(double d) {
    return d * PI / 180;
}