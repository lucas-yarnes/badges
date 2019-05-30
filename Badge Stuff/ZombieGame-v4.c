// ------ Libraries and Definitions ------
#include "simpletools.h"
#include "badgewxtools.h"
#include "ws2812.h"
#include "wifi.h"
#define RGB_COUNT 4

// ------ Global Variables and Objects ------
ws2812 *ws2812b;
int RGBleds[4];

int interactions[10];
char isInfected_[64];
int timeSinceStart;
int firstInfected_;
char command[128];
int len;
int page;
int received;
int len2;
int interacted_;
int index;
int num;
char stringFromNum[64];
int length;
int password;

//vars for wifi connection
char groupid[] = "2019";
char str[1024];
char xacc[64];
char tosend[64];
char tosend2[64];
char tosend3[128];
char tosend4[128];
char tosend5[128];
char uuid[36];
int tcpHandle;
unsigned int stack[40+25];

const char request1[] =
"POST /badgerstate/join/005292019";

const char request2[] = 
" HTTP/1.1\r\n"\
"Host: rendupo.com\r\n"\
"Connection: keep-alive\r\n"\
"Content-Length: 0\r\n"\
"Accept: *" "/" "*\r\n\r\n";

const char request3[] =
"POST /badgerstate/data/005292019";

// ------ Function Declarations ------
void civilian();
void timer();
void zombie();
void MASTER();
void endScreen();
void createTemplate();
void communicate();

// ------ Main Program ------
int main() {
  
  //Start wifi connection to web server
  wifi_start(31, 30, 115200, WX_ALL_COM);
  wifi_setBuffer(str, sizeof(str));
  badge_setup();
  pause(1500);
  high(17);
  text_size(SMALL);
  //cogstart(communicate, NULL, stack, sizeof(stack));
  int tcpHandle = wifi_connect("rendupo.com", 8000);
  oledprint("%d", tcpHandle);
  pause(5000);
  
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
  
  clear();
  cursor(0, 0);
  oledprint("WiFi setup");
  cursor(0, 2);
  oledprint("UUID:");
  cursor(0, 3);
  oledprint(uuid);
  pause(3000);
  
  //Actual game stuff
  ws2812b = ws2812b_open();
  // Allow the Badge WX to be programmed over WiFi
  timeSinceStart = 0;
  for (int __ldx = 1; __ldx <= 2; __ldx++) {
    RGBleds[constrainInt(__ldx, 1, RGB_COUNT) - 1] = 0x003300;
  }
  ws2812_set(ws2812b, RGB_PIN, RGBleds, RGB_COUNT);
  touch_sensitivity_set(13);
  page = 1;
  num = 0;
  received = 0;
  strcpy(isInfected_, "No"); // Save string into variable isInfected_.
  clear();
  cursor(0, 0);
  oledprint("Welcome to the   zombie game");
  cursor(0, 4);
  oledprint("Awaiting command");
  while (1) {
    length = receive(command);
    if ((strcmp(command, ("safe")) == 0)) {
      cog_run(timer, 128);
      civilian();
    }

    if ((strcmp(command, ("infected")) == 0)) {
      cog_run(timer, 128);
      zombie();
    }

    if ((button(6)) == 1) {
      password++;
    }

    if ((button(2)) == 1 && password == 1) {
      password++;
    }

    if ((button(3)) == 1 && password == 2) {
      password++;
    }

    if ((button(4)) == 1 && password == 3) {
      password++;
    }

    if (password == 4) {
      MASTER();
    }

    pause(100);
  }

}

// ------ Functions ------
void civilian() {
  createTemplate();
  while (1) {
    len = receive(command);
    sscanAfterStr(command, ("time"), "%d", &received);
    if ((strcmp(command, ("Infected")) == 0)) {
      strcpy(isInfected_, "Yes"); // Save string into variable isInfected_.
      interacted_ = 1;
      irclear();
      send("hit");
    }

    if (received >= 500) {
      cursor(0, 5);
      oledprint("Time Received:");
      cursor(0, 6);
      oledprint("%d", received);
      for (int __ldx = 1; __ldx <= 4; __ldx++) {
        RGBleds[constrainInt(__ldx, 1, RGB_COUNT) - 1] = 0x990099;
      }
      ws2812_set(ws2812b, RGB_PIN, RGBleds, RGB_COUNT);
      timeSinceStart = received;
      pause(5000);
      zombie();
    }

    if ((button(5)) == 1 && (button(2)) == 1) {
      endScreen();
    }

  }
}

void timer() {
  while (1) {
    timeSinceStart = (timeSinceStart + 10);
    pause(10);
  }
}

void zombie() {
  strcpy(isInfected_, "Yes"); // Save string into variable isInfected_.
  firstInfected_ = 1;
  createTemplate();
  while (1) {
    send("Infected");
    len2 = receive(command);
    if ((strcmp(command, ("hit")) == 0)) {
      for (int __ldx = 1; __ldx <= 4; __ldx++) {
        RGBleds[constrainInt(__ldx, 1, RGB_COUNT) - 1] = 0x990000;
      }
      ws2812_set(ws2812b, RGB_PIN, RGBleds, RGB_COUNT);
      interactions[constrainInt(num, 0, 9)] = timeSinceStart;
      num++;
      sprint(stringFromNum, "%s%d", "time", timeSinceStart);
      communicate(stringFromNum);
      pause(50);
      send(stringFromNum);
    }

    pause(200);
    for (int __ldx = 1; __ldx <= 4; __ldx++) {
      RGBleds[constrainInt(__ldx, 1, RGB_COUNT) - 1] = 0x3F3F3F;
    }
    ws2812_set(ws2812b, RGB_PIN, RGBleds, RGB_COUNT);
    if ((button(5)) == 1 && (button(2)) == 1) {
      endScreen();
    }

  }
}

void MASTER() {
  clear();
  text_size(LARGE);
  oledprint(" MASTER");
  while (1) {
    if ((button(0)) == 1) {
      send("safe");
    }

    if ((button(7)) == 1) {
      send("infected");
    }

  }
}

void endScreen() {
  while (1) {
    if ((button(1)) == 1) {
      page = 2;
    }

    if ((button(3)) == 1) {
      page = 1;
    }

    if (page == 1) {
      clear();
      text_size(SMALL);
      cursor(0, 0);
      oledprint("Final state:");
      cursor(0, 1);
      if ((strcmp(isInfected_, ("Yes")) == 0)) {
        oledprint("Infected");
      }
      else
      {
        oledprint("Not infected");
      }

      cursor(0, 3);
      oledprint("Number of peopleinfected?");
      cursor(0, 5);
      oledprint("%d", num);
      cursor(14, 7);
      oledprint("<>");
      page = 0;
    }

    if (page == 2) {
      clear();
      for (index = 0; index < num; index++) {
        cursor(0, 0);
        oledprint("Times Infected:");
        cursor(0, index + 1);
        oledprint("%d", interactions[index]);
        cursor(14, 7);
        oledprint("<>");

      }
      page = 0;
    }

    cursor(0, 7);
    oledprint("%d", timeSinceStart);
    pause(156);
  }
}

void createTemplate() {
  clear();
  cursor(0, 0);
  oledprint("Walk around and chat with your classmates.");
}

void communicate(time) {   
    
    memset(str, 0, sizeof(str));
    memset(tosend4, 0, sizeof(tosend4));
    memset(tosend5, 0, sizeof(tosend5));
    sprint(tosend4, "%s/%s/%d", request3, uuid, time);
    sprint(tosend5, "%s%s", tosend4, request2);
    
    wifi_print(TCP, tcpHandle, "%s", tosend5);
    pause(150);
    
  }    
