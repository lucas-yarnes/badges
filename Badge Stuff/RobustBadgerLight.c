// ------ Libraries and Definitions ------
#include "simpletools.h"
#include "badgewxtools.h"
#include "wifi.h"

// ------ Global Variables and Objects ------

int event, id, handle;
char str[1024];
char wifi_event;

char tosend[128];
char tosend2[128];
char tosend3[256];

char tosend4[256];
char tosend5[512];
char uuid[36];

long LDR;

long getLightSensorReading();
long getFakeSensorReading();

int length;
int size;

long val=17;


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
  print("wait 10 s...");
  pause(10000);
  print("done!\r\r");
  wifi_start(31, 30, 115200, WX_ALL_COM);
  //wifi_start(9, 8, 115200, USB_PGM_TERM);
  wifi_setBuffer(str, sizeof(str));
  
  pause(1000);
  badge_setup();
  oledprint("Reading!");
  int tcpHandle = 0;
  while(tcpHandle != 5)
  {  
    tcpHandle = wifi_connect("rendupo.com", 8000);
    print("\rtcpHandle = %d\r", tcpHandle);
    print("\r\r=== connect str ===\r");
    putStrWithNpcVals(str);
    if(tcpHandle < 5)
    {
      pause(5000);
      continue;
    }
    if(tcpHandle > 5)
    {
      wifi_disconnect(tcpHandle);
      wifi_disconnect(5);
      print("\r\rerror!\r\r");
      pause(5000);
      print("\r\r=== discon str ===\r");
      putStrWithNpcVals(str);
      print("\r\rerror!\r\r");
      continue;
    }
  }
  pause(100);
  // print("tcpHandle = %d\r\r", tcpHandle);
  
  memset(tosend, 0, sizeof(tosend));
  memset(tosend2, 0, sizeof(tosend2));
  memset(tosend3, 0, sizeof(tosend3));
  memset(uuid, 0, sizeof(uuid));
  sprint(tosend3, "%s%s", request1, request2);
  
  print("\r\r=== TCP str ===\r");
  putStrWithNpcVals(request3);
  
  wifi_print(TCP, tcpHandle, "%s", tosend3);
  
  print("\r\r=== print str ===\r");
  putStrWithNpcVals(str);
  
  pause(500);
  wifi_scan(TCP, tcpHandle, "%s", str);
  
  print("\r\r=== scan str ===\r");
  print("length = %d\r", strlen(str));
  putStrWithNpcVals(str);
  pause(500);
  
  memcpy( uuid, &str[138], 36 );
  uuid[36] = '\0';
  print("\r\rID Value from Badger: %s\r\r", uuid);
  
  wifi_disconnect(tcpHandle);
  print("\r\r=== discon str ===\r");
  putStrWithNpcVals(str);
  
  pause  (3000);
    
  while (1)
  {
    tcpHandle = 0;
    
    tcpHandle = wifi_connect("rendupo.com", 8000);
    print("\rtcpHandle = %d\r", tcpHandle);
    if(tcpHandle < 5  )
    {
      pause(2000);
      continue;
    }
    if(tcpHandle >   5)
    {
      wifi_disconnect(tcpHandle);
      wifi_disconnect(5);
      print("\r\rerror!\r\r");
      pause(2000);
      print("\r\r=== discon str ===\r");
      putStrWithNpcVals(str);
      print("\r\rerror!\r\r");
      continue;
    }
    print("\r\r=== connect str ===\r");
    putStrWithNpcVals(str);
    
    long light = getLightSensorReading();
    //long light = getFakeSensorReading();
    memset(tosend4, 0, sizeof(tosend4));
    memset(tosend5, 0, sizeof(tosend5));
    sprint(tosend4, "%s%s/%d", request3, uuid, light);
    sprint(tosend5, "%s%s", tosend4, request2);
    //http://rendupo.com:8000/badgerstate/data/123456789/460b6776-9f92-4fd6-a8bb-4882c35e1d11/42
    
    print("\r\r=== tcp str ===\r");
    print("length = %d\r", strlen(tosend5));
    putStrWithNpcVals(tosend5);
    
    wifi_print(TCP, tcpHandle, "%s", tosend5);
    
    int eventP = 0; int idP = 0; int handleP = 0;
    for(int n = 0; n < 500; n++  )
    {
      wifi_poll(&eventP, &idP, &handleP);
      print("event: %c, id: %d, handle: %d\r",
      eventP, idP, handleP);
      pause(10);
      if(eventP == 'D') break;
    }
    
    print("\r\r=== print str ===\r");
    putStrWithNpcVals(str);
    wifi_scan(TCP, tcpHandle, "%s", str);
    
    
    print("\r\r=== scan str ===\r");
    print("length = %d\r", strlen(str));
    putStrWithNpcVals(str);
    char myStr[40];
    memset(myStr, 0, 40);
    char c;
    int n;
    sscanAfterStr(str, "\r\n\r\n", "%d%c%c%36s", &n, &c, &c, myStr);
    wifi_disconnect(tcpHandle);
    print("\r\r=== discon str ===\r");
    putStrWithNpcVals(str);
    
    
    print("\r\r\rmyStr = %s\r\r", myStr);
    //putStrWithNpcVals(myStr);
  }
}

//myStr = 1532404573215


long getFakeSensorReading() {
  cursor(0,1);
  oledprint(" %d", val++);
  //pause(1000);
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
  oledprint("       "); // Quick clear of row; probably better way to do this with % param, although the display blink is handy to see things are working!
  cursor(0,1);
  oledprint("%d", LDR);
  // Wait a second- give us humans time to read the display!
  pause(100);
  return LDR;
}
