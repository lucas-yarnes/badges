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

long getLightSensorReading();
long getFakeSensorReading();

int length;

int accelAX = 1;
int size;
int index = 0;

long val=1;


const char request1[] =   
"POST /badgerstate/join/123456789";

const char request3[] =
"POST /badgerstate/data/123456789/";

const char request2[] = 
" HTTP/1.1\r\n"\
"Host: rendupo.com\r\n"\
"Connection: keep-alive\r\n"\
"Content-Length: 0\r\n"\
"Accept: *" "/" "*\r\n\r\n";

int main()
{
    wifi_start(31, 30, 115200, WX_ALL_COM);  
    wifi_setBuffer(str, sizeof(str));
  
    
    
    badge_setup();
  
  while (1)
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
  
    memcpy( uuid, &str[138], 36 );
    uuid[36] = '\0';
 
  
    char event[4];
    int id = 0; 
    clear();
    index = 0;
    val = 1;
    oledprint("<-Start");
    while (((button(5)) == 0)) {
      pause(10);
    }
    clear();
    oledprint("Reading:");
    while (index++ < 31) 
    {
      
      //long light = getFakeSensorReading();
      long light = getLightSensorReading();

      memset(str, 0, sizeof(str));
      memset(tosend4, 0, sizeof(tosend4));
      memset(tosend5, 0, sizeof(tosend5));
  
      sprint(tosend4, "%s%s/%d", request3, uuid, light);
      sprint(tosend5, "%s%s", tosend4, request2);
      
      //http://rendupo.com:8000/badgerstate/data/123456789/460b6776-9f92-4fd6-a8bb-4882c35e1d11/42
  
      wifi_print(TCP, tcpHandle, "%s", tosend5);
      //pause(150);
      pause(150);
      //wifi_scan(TCP, tcpHandle, "%s", str); 
    }
    wifi_disconnect(tcpHandle);
    pause(1000);
  }  
  
}


long getFakeSensorReading() {
  cursor(0,1);
  oledprint("  %d", val++);
  pause(100);
  return val;
}  

long getLightSensorReading() {
    
    // Set pin high and charge for a few milliseconds
    high(0);
    pause(1);
       
        
    // Use RCTime to grab light-resistor value, by counting time needed for pin to discharge
    // Learn Reference: http://learn.parallax.com/tutorials/language/blocklyprop/circuit-practice-blocklyprop/potentimeter-position
    LDR = (rc_time(0, 1));
    
    // Display results on Badge OLED display
    cursor(0,1);
    oledprint("        "); // Quick clear of row; probably better way to do this with % param, although the display blink is handy to see things are working!
    cursor(0,1);
    oledprint("%d", LDR);
    
    // Wait a second- give us humans time to read the display!
    pause(100);
    return LDR;
  
}  


