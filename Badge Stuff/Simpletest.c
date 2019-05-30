// ------ Libraries and Definitions ------
#include "simpletools.h"
#include "badgewxtools.h"
#include "wifi.h"

// ------ Global Variables and Objects ------

int event, id, handle;
char str[1024];
char wifi_event;
char xacc[64];
char tosend[64];
char tosend2[64];
char tosend3[128];

char tosend4[128];
char tosend5[128];
char uuid[36];

  long LDR;
  
static volatile int terminator = 0;

long getLightSensorReading();
long getFakeSensorReading();

int buttonPressed();

int length;

unsigned int stack[40 + 25];

int accelAX = 1;
int size;
int index = 0;

long val=1;

const char request1[] = 
"POST /badgerstate/join/654321987";

const char request3[] = 
"POST /badgerstate/data/654321987";

const char request2[] = 
" HTTP/1.1\r\n"\
"Host: rendupo.com\r\n"\
"Connection: keep-alive\r\n"\
"Content-Length: 0\r\n"\
"Accept: *" "/" "*\r\n\r\n";

int main()                                    // Main function
{
  high(17);
  wifi_start(31, 30, 115200, WX_ALL_COM);
  wifi_setBuffer(str, sizeof(str));
  
  badge_setup();
 
  while(1)
  {
    clear();
    oledprint("Comms...");
    pause(1500);
    
    int tcpHandle = wifi_connect("rendupo.com", 8000);
    pause(100);
    
    memset(xacc, 0, sizeof(xacc));
    memset(tosend, 0, sizeof(tosend));
    memset(tosend2, 0, sizeof(tosend2));
    memset(tosend3, 0, sizeof(tosend3));
    memset(uuid, 0, sizeof(uuid));
    
    sprint(tosend3, "%s%s", request1, request2);
    wifi_print(TCP, tcpHandle, "%s", tosend3);
    pause(1000);
    wifi_scan(TCP, tcpHandle, "%s", str);
    pause(300);
    
    memcpy(uuid, &str[138], 36);
    uuid[36] = '\0';
    
    cogstart(buttonPressed, NULL, stack, sizeof(stack));
    
    while (terminator != 1) {
      char event[4];
      int id = 0;
      clear();
      index = 0;
      val = 1;
      text_size(SMALL);
      oledprint("<-Start");
      cursor(0, 4);
      oledprint(uuid);
      while (((button(5)) == 0)) {
        pause(10);
      }
      clear();
      oledprint("Reading");
   
      memset(str, 0, sizeof(str));
      memset(tosend4, 0, sizeof(tosend4));
      memset(tosend5, 0, sizeof(tosend5));
      sprint(tosend4, "%s/%s/%d", request3, uuid, val++);
      sprint(tosend5, "%s%s", tosend4, request2);
      
      wifi_print(TCP, tcpHandle, "%s", tosend5);
      //clear();
      //oledprint(tosend5);
      pause(150);
    }      
      
      
    wifi_disconnect(tcpHandle);
    pause(1000);     
    
  }  
}

long getFakeSensorReading() {
  cursor(0,1);
  oledprint("  %d", val++);
  pause(500);
  return val;
}

int buttonPressed() {
  if (button(2) == 1) {
    terminator = 1;
  }
  pause(50);    
}
  
