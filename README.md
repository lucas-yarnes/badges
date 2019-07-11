# badges
The folder with all of the files I am using while working on the badge project

The NetLogo file named Simplified_Model is the most up-to-date version of that project.
The folder named Badge Stuff is old and outdated

To run a simulation:
-On the host computer, first ensure that the latest version of NetLogo has been installed (found here: https://ccl.northwestern.edu/netlogo/download.shtml)
-Then, download the Simplified_Model.nlogo program and run it. Look at the info tab for further instructions on how to start a simulation within NetLogo

--------------------------------------------------------------------------------------
-For the badges, you can install the C program in one of two ways. 

Method 1: Upload the C program via SimpleIDE (http://learn.parallax.com/tutorials/language/propeller-c/propeller-c-set-simpleide)

  -Once in SimpleIDE, open up the .c program in the respository and upload it to the badge via wifi (to do this, you will also need to install BlocklyProp (http://blockly.parallax.com/blockly/public/clientdownload), open it, ensure the badge and computer are connected to the same wifi network, start the socket, then find the badge in the port selection menu in SimpleIDE)
  
Method 2: Upload the save.rom program to the badge via an SD card inserted into the badge on startup. 

  -First, save the save.rom file to an empty SD card
  -Then, insert the SD card into the badge while the badge is OFF
  -Once inserted, turn the badge ON and wait for the "SAVING TO EEPROM" message to appear on the badge's OLED display
  
