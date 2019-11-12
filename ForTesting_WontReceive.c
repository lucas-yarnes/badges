#include "simpletools.h"     
#include "badgewxtools.h"
#include "wifi.h"         
#include "ws2812.h"
#define RGB_COUNT 4        

//For Wifi Coms
char str[1024];
char otherStr[1024];
int lastTimestamp = 0;
char *info;
char *netid;
char *possible;
char *signal;
char netBucket[36];
char data[128];
int newRoomID;
int otherRoomID;
char temp[10];
char myBucket[36];
char received[64];

//For LEDs
ws2812 *ws2812b;
int RGBleds[4];

//Extra
char irBuff[32];
unsigned long timeSinceStart = 0;
char lastNetSignalTime[18];
char currentNetSignalTime[18];
char lastNetSignal[32];

/* Important to change*/
char hostName[] = "gallery.app.vanderbilt.edu";
int hostPort = 80;
char defaultID[] = "999999999";
char defaultBucket[] = "11285a06-c692-4b9f-9c1e-284c5c1003aa";

//For device id
char _moduleName[35];
char *moduleName = _moduleName + 2;
char device[7];

/* Function Declarations */
int getStartInfo();
void joinNewRoom(int room);
void checkIfReceived();
void setSignal(int room, char sig[]);
void sendToNet(int room, char thing[]);
void pollIR();
void readDataStream(int room, int numToCheck);
void getNetSignalTime(int room, char *val);
char getNetSignal(int room);
void timer();
void ledDefault();
void ledInteracted(int color);

int main()                                    
{
  
  //Badge Setup
  badge_setup();
  high(17);
  text_size(SMALL);
  int test = 0;
  ws2812b = ws2812b_open();
  ledDefault();
  
  //Wifi Setup
  wifi_start(31, 30, 115200, WX_ALL_COM);
  wifi_setBuffer(str, sizeof(str));
  
  int serverRoom = getStartInfo(); 
  
  memset(_moduleName, '\0', sizeof(_moduleName));
  wifi_print(CMD, NULL, "%cCHECK:module-name\r", CMD);
  wifi_scan(CMD, NULL, "%34c", &_moduleName);
  strncpy(device, _moduleName + 5, sizeof(_moduleName)); 
  device[6] = '\0';
  int currentState = 0;
  
  joinNewRoom(serverRoom);
  //print("Mybucket is %s", myBucket);
  //print("New roomID is %d", serverRoom);
  cog_run(pollIR, 128);
  cog_run(timer, 128);
  clear();
  oledprint("Name: %s", device);
  
  //getNetSignalTime(serverRoom, lastNetSignalTime);
  //strcpy(currentNetSignalTime, lastNetSignalTime);
  
  
  while(1)
  {     
    if (strlen(irBuff) > 4) {    
      sendToNet(serverRoom, irBuff);
      clear();
      text_size(LARGE);
      oledprint("INTERACTION!");
      ledInteracted(4);
      pause(3000);
      text_size(SMALL);
      clear();
      oledprint("Name: %s", device);
      ledDefault();
      memset(irBuff, 0, sizeof(irBuff));
      irclear();
    }
         
    //checkIfReceived(serverRoom);
    
    if(strcmp(data, "0") == 0) {
      if (test == 0) {
        currentState = 2; //First time, Netlogo did this
        test = 1;
      }        
    }      
    
    if(strcmp(data, "0") != 0 && test != 0 && strlen(data) > 0) {
      currentState = 1; //received something new
    }      
    
    if (currentState != 0) {
      if (currentState == 2) {
        print("\nNETLOGO received connection\r");
        clear();
        oledprint("NetLogo received connection");
        currentState = 0;
      }
      else if (currentState == 1) {
        if (data[0] == 'N') {
          print("\n\n\nI should check my DATA stream...");
          int numToCheck = atoi(data+1);
          print("\n%d new data points to check. They are:", numToCheck);
          clear();
          oledprint("%d points have been sent to DATA stream", numToCheck);
          pause(100);
          readDataStream(serverRoom, numToCheck);
          pause(100);
        }
        else if (strcmp(data, "successful") == 0) {
           ledInteracted(6);
           pause(2000);
           ledDefault();
        }          
        else if (strcmp(data, "failed") == 0) {
          ledInteracted(1);
          pause(2000);
          ledDefault();
        }          
        else if (strcmp(data, "match") == 0) {
          ledInteracted(9);
          pause(2000);
          ledDefault();
        }          
        else {    
          print("\n\nReceived: %s\n", data); 
          clear();
          oledprint("Received %s from NetLogo", data);
        }               
        setSignal(serverRoom, "0");
        currentState = 0;
      }    
    }   
    //NetSignal handling
    //getNetSignalTime(serverRoom, currentNetSignalTime);
    if (strcmp(currentNetSignalTime, lastNetSignalTime) != 0) {
      memset(lastNetSignal, 0, sizeof(lastNetSignal));
      getNetSignal(serverRoom);
      print("\n*gasp* NetLogo changed its signal to %s", lastNetSignal);
      clear();
      oledprint("NetLogo signal changed to %s... interesting...", lastNetSignal);
      if (strcmp(lastNetSignal, "reset") == 0) {
        timeSinceStart = 0;
        clear();
        oledprint("Timer reset - thanks NetLogo!");
      }    
      else if (strcmp(lastNetSignal, "active") == 0) {
        timeSinceStart = 0;
        sendToNet(serverRoom, "ok");
        oledprint("should've sent");
        pause(100);
      }        
      strcpy(lastNetSignalTime, currentNetSignalTime);
    }
    cursor(0, 7);
    oledprint("%d", timeSinceStart); 
  }
}

int getStartInfo() {
  //print("started");
  int tcpHandle = wifi_connect(hostName, hostPort);
  char tosend1[128];
  char request3[] = "GET /badgerstate/signal/";                   
  char request2[64];
  char str2[512];
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "\r\n\r\n\0"); 
  sprint(tosend1, "%s%s%s%s%s", request3, defaultID, "/", defaultBucket, request2);
  wifi_print(TCP, tcpHandle, "%s", tosend1);
  pause(1250);
  wifi_scan(TCP, tcpHandle, "%s", str);
  strcpy(str2, str);
  memset(temp, 0, sizeof(temp));
  info = strtok(str, "|");
  info = strtok(NULL, "&");  
  strncpy(temp, &info[1], strlen(info));
  temp[10] = '\0';
  newRoomID = atoi(temp);
  otherRoomID = newRoomID;
  print("%d", otherRoomID);
  //strcpy(otherRoomID, newRoomID);
  possible = strstr(str2, "&");
  strcpy(netBucket, &possible[1]);
  netBucket[36] = '\0';
  print("\n%s", netBucket);
  wifi_disconnect(tcpHandle);
  return otherRoomID;
}

void joinNewRoom(int room) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "POST /badgerstate/join/";
  char request3[] = "POST /badgerstate/signal/";
  char request2[128];
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend2[180];
  char tosend3[180];
  sprint(tosend2, "%s%d%s%", request1, room, request2);
  wifi_print(TCP, tcpHandle, "%s", tosend2);
  pause(1250);
  wifi_scan(TCP, tcpHandle, "%s", str);
  memcpy(myBucket, &str[160], 36);
  myBucket[36] = '\0';
  //print("\nBucket is -> %s", myBucket);
  sprint(tosend3, "%s%d%s%s%s%s%s", request3, room, "/", myBucket, "/", device, request2);
  clear();
  oledprint("posted signal");
  wifi_print(TCP, tcpHandle, "%s", tosend3);
  wifi_disconnect(tcpHandle);
}  

void checkIfReceived(int room) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "GET /badgerstate/signal/";
  char request2[128];
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend4[180];
  sprint(tosend4, "%s%d%s%s%s", request1, room, "/", myBucket, request2);
  memset(str, 0, sizeof(str));
  memset(otherStr, 0, sizeof(otherStr));
  wifi_print(TCP, tcpHandle, "%s", tosend4);
  pause(1250);
  wifi_recv(tcpHandle, str, 1024);
  signal = 0;
  signal = strstr(str, "|");
  memset(data, 0, sizeof(data));
  strncpy(data, &signal[2], (strlen(signal) - 4));  
  wifi_disconnect(tcpHandle);
} 

void setSignal(int room, char sig[]) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "POST /badgerstate/signal/";
  char request2[128];
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend5[180];
  sprint(tosend5, "%s%d%s%s%s%s%s", request1, room, "/", myBucket, "/", sig, request2);
  memset(str, 0, sizeof(str));
  wifi_print(TCP, tcpHandle, "%s", tosend5);
  wifi_disconnect(tcpHandle);
}  

void sendToNet(int room, char thing[]) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "POST /badgerstate/data/";
  char request2[128];
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend6[180];
  sprint(tosend6, "%s%d%s%s%s%s%s%s%s%d%s", request1, room, "/", netBucket, "/", device, ",", thing, ",", timeSinceStart, request2);
  wifi_print(TCP, tcpHandle, "%s", tosend6);
  wifi_disconnect(tcpHandle);
}  

char getNetSignal(int room) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "GET /badgerstate/signal/";
  char request2[128];
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend9[180];
  char sData[48];
  char *point;
  sprint(tosend9, "%s%d%s%s%s", request1, room, "/", netBucket, request2);
  wifi_print(TCP, tcpHandle, "%s", tosend9);
  pause(1250);
  wifi_scan(TCP, tcpHandle, "%s", str);
  point = strstr(str, "|");
  strcpy(sData, point+2); 
  strncpy(lastNetSignal, sData, (strlen(sData)-2));
  wifi_disconnect(tcpHandle);
}
  
void getNetSignalTime(int room, char *val) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "GET /badgerstate/signal/";
  char request2[128];
  char temp[32];
  char final[32];
  char *point;
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend8[180];
  sprint(tosend8, "%s%d%s%s%s", request1, room, "/", netBucket, request2);
  wifi_print(TCP, tcpHandle, "%s", tosend8);
  pause(1250);
  memset(final, 0, sizeof(final));
  memset(temp, 0, sizeof(temp));
  wifi_scan(TCP, tcpHandle, "%s", str);
  //print(str);
  strcpy(temp, str+160);
  //print("temp -> %s", temp);
  point = strstr(temp, "|");
  //print("point points -> %s", point);
  strncpy(val, temp, (point-temp-1));
  print("\nLast time: %s", val);
  wifi_disconnect(tcpHandle);
}  

void readDataStream(int room, int numToCheck) {
  int tcpHandle = wifi_connect(hostName, hostPort);
  char request1[] = "GET /badgerstate/n-data/";
  char request2[128];
  //char dataStream[1024];
  char inter[1024];
  //char *here;
  sprint(request2, "%s%s%s", " HTTP/1.1\r\nHost: ", hostName, "Connection: keep-alive\r\nContent-Length: 0\r\nAccept: *" "/" "*\r\n\r\n");
  char tosend7[180];
  sprint(tosend7, "%s%d%s%s%s%d%s", request1, room, "/", myBucket, "/", numToCheck, request2);
  wifi_print(TCP, tcpHandle, "%s", tosend7);
  pause(1250);
  wifi_scan(TCP, tcpHandle, "%s", str);
  strncpy(inter, str+165, (strlen(str)-9));
  //print(inter);
  //print("\n\nPointer points -> %s", inter);
  char *point;
  char *here;
  here = strstr(inter, "value");
  here += 8;
  point = strstr(here, "\"");
  while (strlen(inter) > 26 && point != 0 && here != 0) {
    char val[16];
    memset(val, 0, sizeof(val));
    here = strstr(inter, "value");
    here += 8;
    point = strstr(here, "\"");
    strncpy(val, here, (point - here));
    strcpy(inter, here+8+(point-here));
    //print("\nData: %s", val); 
  }    
  wifi_disconnect(tcpHandle);
}  

void pollIR() {
  while(1) {
    ir_receive(irBuff, 8);
    pause(50);
    if (button(2) == 1 && button(5) == 1) {
      ir_send(device, 8);
    }
  }     
} 

void timer() {
  while(1) {
    pause(10); 
    timeSinceStart += 10;
  }     
}         

void ledDefault() {
  
  for (int __ldx = 1; __ldx <= 4; __ldx++) {
    RGBleds[constrainInt(__ldx, 1, RGB_COUNT) - 1] = 0x000000;
  }
  ws2812_set(ws2812b, RGB_PIN, RGBleds, RGB_COUNT);
  
}

void ledInteracted(int color){
  
  int hex = 0;
  
  switch (color) {
    case 1:
      hex = 0xFF0000; //red
      break;
    case 2:
      hex = 0xFF6000; //orange
      break;
    case 3:
      hex = 0x8C00FF; //purple
      break;
    case 4:
      hex = 0x091929; //turquoise
      break;
    case 5:
      hex = 0x0E0600; //brown
      break;
    case 6:
      hex = 0x00FF00; //green
      break;
    case 7:
      hex = 0xFFFF00; //yellow
      break;
    case 8:
      hex = 0x320010; //maroon
      break;
    case 9:
      hex = 0x0000FF; //blue
      break;
  }     
    
  for (int __ldx = 1; __ldx <= 4; __ldx++) {
    RGBleds[constrainInt(__ldx, 1, RGB_COUNT) - 1] = hex;
  }
  ws2812_set(ws2812b, RGB_PIN, RGBleds, RGB_COUNT);
  
}  
