extensions [ web table ]
breed [ badges badge ]
badges-own [ module-id immune? infected? interactions first-infected? ]
globals [ total-num-infected data-stream data-list num-data url prev-length new-room-id new-room-uuid connected-badges link-list all-interactions which-output timestamp prev-chance-spread num-initial prev-chance-immune prev-percent-initial-infected pointer badges-present]

;Legit procedures
to setup
  ca
  setup-output
  clear-turtles
  set connected-badges table:make
  set all-interactions []
  set link-list []
  set badges-present []
  set data-stream []
  if-else online?
  [
    set url "http://gallery.app.vanderbilt.edu/badgerstate"
    check-existing
    create-new-room
    set prev-length length get-participants
    set data-list []
  ]
  [
    fill-room
    ifelse use-percent
    [
      set num-initial floor (percent-initial-infected / 100.0 * count badges)
      ask n-of num-initial badges
      [
        set infected? true
        set first-infected? true
        set color blue
      ]
    ]
    [
      ask n-of num-initial-infected badges
      [
        set infected? true
        set first-infected? true
        set color blue
      ]
    ]
  ]
  reset
end

to go
  ifelse online?
  [
    every 1
    [
      ;Get the list of participants in the new room currently
      let participants-list get-participants
      ;If a new member(s) joined the room since last check
      if (length participants-list != prev-length)
      [
        let current-length length get-participants
        ;Don't just assume one new member in case multiple badges join within the 1-second timespan
        let num-new-participants (current-length - prev-length)
        let index 0
        ;wait 2
        while [index < num-new-participants]
        [
          get-badge-id index
          set index (index + 1)
        ]
        set prev-length current-length
      ]
    ]
    ;Check for new data from participants
    every 2
    [
      let data-str (first web:make-request (word url "/data/" new-room-id "/" new-room-uuid "/" timestamp) "GET" [] [])
      set data-list parse-data-stream data-str
      if (length data-list > 0)
      [
        set num-data num-data + length data-list
        let index 0
        let data-seg ""
        while [index < length data-list]
        [
          set data-seg item index data-list
          set data-stream lput parse-badge-data data-seg data-stream
          set index index + 1
        ]
        set timestamp parse-timestamp (first web:make-request (word url "/n-data/" new-room-id "/" new-room-uuid "/1") "GET" [] [])
        print word (length data-list) " new entries have been made"
        ;Check if the interaction was valid.. if it was, add the interaction to a list for aNAlySis
        set index 0
        set data-seg []
        while [index < length data-list]
        [
          set data-seg parse-badge-data item index data-list
          show data-seg
          carefully [
            do-thing data-seg
            set all-interactions lput data-seg all-interactions
          ]
          []
          set index index + 1
        ]
      ]
    ]
  ]
  [
    create-connections
    fix-data
    update-output
    ;create-links-from-existing
    ;generate-report
  ]
end

to setup-game [ badges-to-add ]
  let index 0
  let codes []
  foreach badges-to-add [
    the-badge ->
    create-badges 1 [
      set shape "circle"
      set size 0.5
      set color blue
      set xcor random 32
      set ycor random 32
      set module-id item index badges-to-add
     ; set code ""
      set label module-id
      set interactions []
    ]
    set index index + 1
  ]

end

to-report parse-timestamp [ data ]
  set timestamp 0
  let startPos position "timestamp" data
  if (startPos != false)
  [
  set timestamp substring data (startPos + 11) (length data - 2)
  ]
  report timestamp
end

to-report parse-signal-data [ data ]
  show data
  let startPos position "|" data
  ifelse (startPos = false)
  [
    report "none"
  ]
  [
    let signal-data substring data (startPos + 2) length data
    report signal-data
  ]
end

to-report parse-badge-data [ data ]
  let startPos 0
  let comPos position "," data
  let result []
  while [comPos != false]
  [
    set result lput substring data startPos comPos result
    set data substring data (comPos + 1) length data
    set comPos position "," data
  ]
  set result lput substring data startPos length data result
  report result
end

to-report parse-data-stream [ data ]
  let ldata []
  let startPos position "value" data
  let endPos position "\",\"" data
  while [startPos != false]
  [
    set ldata lput substring data (startPos + 8) endPos ldata
    set data substring data (endPos + 8) length data
    set startPos position "value" data
    set endPos  position "\",\"" data
  ]
  report ldata
end

to get-badge-id [ index ]
  ;Get badge id @ specified index from the list of participants
  let badge-bucket item index get-participants
  ;Get the module name of the badge
  let badge-mod-name parse-signal-data (first web:make-request (word url "/signal/" new-room-id "/" badge-bucket) "GET" [] [])
  ;Set the signal to 0 so the badge knows NetLogo received its connection
  __ignore web:make-request (word url "/signal/" new-room-id "/" badge-bucket "/0") "POST" [] []
  ;Using the badges module name and bucket, make a new entry in the connect-badges table containing those two value,
  ;with the module name being the key and the bucket being the value
  if table:has-key? connected-badges badge-mod-name
  [
    ask turtles with [module-id = badge-mod-name] [die]
  ]
  let temp []
  set temp lput badge-mod-name temp
  setup-game temp
  table:put connected-badges badge-mod-name badge-bucket
  print (word "Badge " badge-mod-name " connected with bucket " table:get connected-badges badge-mod-name)
end

to-report get-participants
  ;Create an empty list
  let part-list []
  ;Get a string that contains all of the participants in the new room
  let new-room-participants-str (first web:make-request (word url "/participants/" new-room-id) "GET" [] [])
  ;Convert this string into a list of participants
  set part-list (read-from-string (replace-all new-room-participants-str "," " "))
  ;Return that list
  report part-list
end

to check-existing
  let new-room-participants-list []
  ;Get the signal currently hosted in the homeRoom
  let data (first web:make-request (word url "/signal/" homeRoomID "/" homeRoomUUID) "GET" [] [])
  ;Get the ID in the signal
  set new-room-id read-from-string parse-id data
  ;Since we are starting a new simulation, make a new room (the current room should have values from previous simulations)
  set new-room-id (new-room-id + 1)
  ;To see if the new room is empty, get the participants list and convert it to a NetLogo list that we can check the length of
  let new-room-participants-str (first web:make-request (word url "/participants/" new-room-id) "GET" [] [])
  set new-room-participants-list (read-from-string (replace-all new-room-participants-str "," " "))
  ;While the new room isn't empty, keep generating new rooms and checking
  while [ (length new-room-participants-list) != 0]
  [
    set new-room-id (new-room-id + 1)
    set new-room-participants-str (first web:make-request (word url "/participants/" new-room-id) "GET" [] [])
    set new-room-participants-list (read-from-string (replace-all new-room-participants-str "," " "))
  ]
end

to-report replace-all [str target replacement]
  let i (position target str)
  report (ifelse-value (i = false) [ str ] [replace-all (replace-item i str replacement) target replacement])
end

to-report parse-id [ data ]
  let startPos position "|" data
  let endPos position "&" data
  let id substring data (startPos + 2) endPos
  report id
end

to create-new-room
  ;Make a request to join the new room
  let temp-list web:make-request (word url "/join/" new-room-id) "POST" [] []
  ;Get the uuid out of the response to the http request
  set new-room-uuid item 0 temp-list
  ;Open a signal for NetLogo in the new room
  __ignore web:make-request (word url "/signal/" new-room-id "/" new-room-uuid "/0") "POST" [] []
  ;Update the signal in the homeRoom for the badges
  __ignore web:make-request (word url "/signal/" homeRoomID "/" homeRoomUUID "/" new-room-id "&" new-room-uuid) "POST" [] []
end

to do-thing [interaction]
  let badge1 one-of badges with [module-id = item 0 interaction]
  let badge2 one-of badges with [module-id = item 1 interaction]
  let tm item 2 interaction
  ask badge1 [ create-link-with badge2 ]
end

to setup-output
  clear-output
  (ifelse
    which-output = "interaction-list"
    [
      output-print "\t\t\t\t  Interactions\t\t\n\n"
      output-print "Time of Interaction\t\tBadge1\t\tBadge2\t\tDisease Transmitted?"
    ]
    which-output = "number-interactions"
    [
      output-print "\t\t\t\t  Interactions\t\t\n\n"
      output-print "Badge\t\tNumber of Interactions"
    ]
    which-output = "stats"
    [
      output-print "\t\t\t\t Statistics\t\t\n\n"
    ]
    [])
end

to update-output
  setup-output
  (ifelse
    which-output = "interaction-list"
    [
      foreach link-list [
        the-link ->
        output-print (word item 2 the-link "\t\t\t\t" item 0 the-link "\t\t" item 1 the-link "\t\t" item 3 the-link)
      ]
    ]
    which-output = "number-interactions"
    [
      let badges-list []
      ask badges [ set badges-list lput module-id badges-list ]
      let temp-list []
      foreach badges-list [
        nonsense ->
        let the-badge one-of badges with [module-id = nonsense]
        let more-temp-list []
        set more-temp-list lput length [interactions] of the-badge more-temp-list
        set more-temp-list lput nonsense more-temp-list
        set temp-list lput more-temp-list temp-list
      ]
      set temp-list sort-by [ [a b] -> first a > first b ] temp-list
      foreach temp-list [
        the-item ->
        output-print (word item 1 the-item "\t\t" item 0 the-item)
      ]
    ]
    which-output = "stats"
    [
      output-print word "Total Infected Persons:\t\t\t" total-num-infected
      output-print word "Total Interactions:\t\t\t" length link-list
      output-print word "Total Number of Immune Persons:\t\t" count badges with [immune? = true]
    ]
    [])
end

to save-interaction-set
  file-close-all
  let name ""
  set name user-input "Enter file name: "
  set name word name ".txt"
  carefully [file-delete name] [print "file doesn't exist yet"]
  file-open name
  file-write all-interactions
  ;file-print badges-present
  file-close-all
  print "File saved successfully"
end

to load-interaction-set
  ca
  file-close-all
  user-message "Choose Dataset"
  let f user-file
  if f != false
  [
    file-open f
  ]
  ;carefully [
    set all-interactions run-result file-read-line
    ;set line file-read-line
    ;set badges-present run-result line
    ifelse not file-at-end? [ user-message "there was more than one line in the file" ] [ print "File loaded successfully" ];fix-data print
  ;]
  ;[
  ;  user-message ( word "There was an error in parsing the datafile:\n" error-message )
  ;]
  file-close-all
  find-turtles
  fix-data
end

;Takes a list of interactions from a file and creates badge objects for each turtle involved in some type of interaction
to find-turtles
  let all-badges []
  foreach all-interactions [
    the-inter ->
    let badge1 item 0 the-inter
    let badge2 item 1 the-inter
    set all-badges lput badge1 all-badges
    set all-badges lput badge2 all-badges
  ]
  set all-badges remove-duplicates all-badges
  foreach all-badges [
    the-badge ->
    create-badges 1 [
      set interactions []
      setxy random 28 + 2 random 28 + 2
      set module-id the-badge
      set color red
      ifelse random 100 < chance-immune
      [
        set immune? true
        set color green
      ]
      [
        set immune? false
      ]
      set infected? false
      set first-infected? false
      if show-label
      [
        set label module-id
      ]
      ;set badges-present lput module-id badges-present
    ]
  ]
  ifelse use-percent
    [
      set num-initial floor (percent-initial-infected / 100.0 * count badges)
      ask n-of num-initial badges
      [
        set infected? true
        set first-infected? true
        set color blue
      ]
    ]
    [
      ask n-of num-initial-infected badges
      [
        set infected? true
        set first-infected? true
        set color blue
      ]
    ]
end

to update
  set link-list []
  ask badges [
    set infected? false
    set immune? false
    set first-infected? false
    ifelse random 100 < chance-immune
      [
        set immune? true
        set color green
      ]
      [
        set immune? false
      ]
  ]
  ifelse use-percent
  [
    set num-initial floor (percent-initial-infected / 100.0 * count badges)
    ask n-of num-initial badges
    [
      set infected? true
      set first-infected? true
      set color blue
    ]
  ]
  [
    ask n-of num-initial-infected badges
    [
      set infected? true
      set first-infected? true
      set color blue
    ]
  ]
  fix-data
  update-output
  check
end

to play
  if pointer >= length link-list or item 2 item pointer link-list >= item 2 item (length link-list - 1) link-list
  [
    stop
  ]
  every .05 * (1 / time-multiplier)
  [
    ifelse rewind?
    [
      set time time - 1
    ]
    [
      set time time + 1
      plot count turtles with [infected? = true]

    ]
    check
  ]
end

to check
  if pointer >= length link-list or item 2 item pointer link-list >= item 2 item (length link-list - 1) link-list
  [
    stop
  ]
  ifelse regard-time?
  [
    let next-interaction-time item 2 item (pointer + 1) link-list
    carefully
    [
      if runresult next-interaction-time < time
      [
        set pointer pointer + 1
      ]
    ]
    [
      if next-interaction-time < time
      [
        set pointer pointer + 1
      ]
    ]
  ]
  [
    set pointer pointer + 1
  ]
  let the-link item pointer link-list
  ;set time time + 1
  let badge1 one-of badges with [ module-id = item 0 the-link ]
  let badge2 one-of badges with [ module-id = item 1 the-link ]
  layout-spring badges links .1 .5 3
  ifelse item 3 the-link = true
  [
    ask badge1 [ create-link-with badge2 [ set color red set thickness .1 ] set color blue set infected? true]
    ask badge2 [ set color blue set infected? true]
  ]
  [
    ask badge1 [ create-link-with badge2 ]
  ]
end

to pause

end

to reset
  clear-plot
  ;set total-num-infected count badges with [ first-infected? = true ]
  setup-plots
  set pointer 0
  set time 0
  clear-links
  ask badges
  [
    setxy random 28 + 2 random 28 + 2
    set color red
    ifelse first-infected? = true
    [
      set color blue
    ]
    [
      set infected? false
    ]
    if immune? = true
    [
      set color green
    ]
  ]
end



;Test procedures
to fill-room
  let i 0
  while [ i < num-participants ]
  [
    create-badges 1 [
      set interactions []
      setxy random 28 + 2 random 28 + 2
      set module-id create-random-id
      set color red
      ifelse random 100 < chance-immune
      [
        set immune? true
        set color green
      ]
      [
        set immune? false
      ]
      set infected? false
      set first-infected? false
      if show-label
      [
        set label module-id
      ]
      set badges-present lput module-id badges-present
    ]
    set i i + 1
  ]
end

to end-live-sim
  ct
  clear-links
  set badges-present table:keys connected-badges
  fix-data
  find-turtles
end

to create-connections
 ; ask badges [ set color red ]
  clear-links
  ;set link-list []
  repeat random 5 + 5  ;  [5,10)
  [
    ask n-of random ((count badges / 2) + 1) badges
    [
      let temp-list []
      set temp-list lput module-id temp-list
      let this-id module-id
      let other-turtle one-of other badges
      set temp-list lput [module-id] of other-turtle temp-list
      set interactions lput [module-id] of other-turtle interactions
      ask other-turtle [ set interactions lput this-id interactions ]
      set temp-list lput random 1001 temp-list
      set all-interactions lput temp-list all-interactions
    ]
  ]
end

to fix-data
  set total-num-infected count badges with [first-infected? = true]
  set link-list []
  let index 0
  let link-num 0
  set all-interactions sort-by [ [a b] -> item 2 a < item 2 b ] all-interactions
  let max-time 0
  ifelse online?
  [
    set max-time runresult item 2 last all-interactions
  ]
  [
    set max-time item 2 last all-interactions
  ]
  foreach all-interactions [
    the-link ->
    let pair []
    let infect-state []
    set pair lput item 0 the-link pair
    set pair lput item 1 the-link pair
    show pair
    set index 0
    while [index < length pair]
    [
      ask badges with [ module-id = item index pair ]
      [
        set infect-state lput infected? infect-state
      ]
      set index index + 1
    ]
    show infect-state
    let t-list []
    set t-list lput item 0 the-link t-list
    set t-list lput item 1 the-link t-list
    let unmod-time 0
    ifelse online?
    [
      set unmod-time runresult item 2 the-link
    ]
    [
      set unmod-time item 2 the-link
    ]
    set t-list lput floor (unmod-time / max-time * 1000) t-list
    ifelse (item 0 infect-state = true and item 1 infect-state = false) or (item 0 infect-state = false and item 1 infect-state = true)
    [
      let badge1 one-of badges with [ module-id = item 0 pair ]
      let badge2 one-of badges with [ module-id = item 1 pair ]
      ifelse [infected?] of badge1 = false
      [
        ; Check for immunity
        ifelse [immune?] of badge1 = true
        [
          set t-list lput false t-list
        ]
        [
          ifelse random 100 + 1 <= chance-spread
          [
            set t-list lput true t-list
            ask badge1 [ set infected? true ]
            set total-num-infected total-num-infected + 1
          ]
          [
            set t-list lput false t-list
          ]
        ]
      ]
      [
        ifelse [immune?] of badge2 = true
        [
          set t-list lput false t-list
        ]
        [
          ifelse random 100 + 1 <= chance-spread
          [
            set t-list lput true t-list
            ask badge2 [ set infected? true ]
            set total-num-infected total-num-infected + 1
          ]
          [
            set t-list lput false t-list
          ]
        ]
      ]
      set link-list lput t-list link-list
    ]
    [
      if show-all-interactions
      [
        set t-list lput false t-list
        set link-list lput t-list link-list
      ]
    ]
    set link-num link-num + 1
  ]
  set link-list sort-by [ [a b] -> item 2 a < item 2 b ] link-list
  ;Set badge variables back to original state so that they update as the interactions are played back...
  ;makes it easier to count infected badges over time, since the turtles' variables reflect their CURRENT state
  ;and not their END state
  ask badges
  [
    if first-infected? != true
    [
      set infected? false
    ]
  ]
  reset
end

to-report create-random-id
  let letters ["a" "b" "c" "d" "e" "f"]
  let numbers ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"]
  let name ""
  ifelse random 10 < 5
  [
    set name "442"
  ]
  [
    set name "2d5"
  ]
  repeat 3
  [
    ifelse random 10 < 5
    [
      set name word name one-of letters
    ]
    [
      set name word name one-of numbers
    ]
  ]
  report name
end

to create-links-from-existing
  foreach link-list [
    the-link ->
    if item 3 the-link = true
    [
      let badge1 one-of badges with [ module-id = item 1 the-link ]
      let badge2 one-of badges with [ module-id = item 2 the-link ]
      ask badge1
      [
        create-link-to badge2
      ]
      layout-spring badges links .1 .4 5
    ]
  ]
end

to generate-report
  print "All of the active badge's current states:"
  ask badges [
    print word "Name: " module-id
    print word "Is immune? " immune?
    print word "Is infected? " infected?
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
16
10
484
479
-1
-1
13.94
1
10
1
1
1
0
0
0
1
0
32
0
32
0
0
1
ticks
60.0

BUTTON
542
267
605
300
NIL
go\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
543
303
698
363
num-participants
50.0
1
0
Number

TEXTBOX
1240
22
1390
92
These are variables that will affect the outcome of the simulation. Will affect the results that appear in the view.
11
0.0
1

INPUTBOX
1232
112
1387
172
chance-spread
100.0
1
0
Number

INPUTBOX
1232
174
1387
234
chance-immune
0.0
1
0
Number

INPUTBOX
1234
318
1389
378
num-initial-infected
1.0
1
0
Number

TEXTBOX
1392
112
1542
168
The % chance that an interactions spreads the disease from one badge to another\n
11
0.0
1

TEXTBOX
1394
184
1544
226
The % chance that any one badge is immune to the disease
11
0.0
1

SWITCH
1248
256
1371
289
use-percent
use-percent
1
1
-1000

TEXTBOX
1382
250
1640
334
This applies to the initial number of infected badges. Set to \"on\" to set the % of all badges that start off infected or set to \"off\" to set a literal number
11
0.0
1

INPUTBOX
1234
382
1389
442
percent-initial-infected
10.0
1
0
Number

TEXTBOX
1402
350
1552
392
Need to set one value or the other, according to the above switch
11
0.0
1

BUTTON
511
31
574
64
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
119
505
203
523
Playback Feature
11
0.0
1

SLIDER
71
526
243
559
time
time
0
1000
1001.0
1
1
NIL
HORIZONTAL

BUTTON
71
563
156
596
NIL
play\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
160
563
243
596
NIL
reset\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
541
118
684
151
NIL
save-interaction-set
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
541
154
685
187
NIL
load-interaction-set\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
506
463
1124
784
11

SWITCH
1717
778
1887
811
show-all-interactions
show-all-interactions
0
1
-1000

BUTTON
559
425
707
458
SHOW interaction list
set which-output \"interaction-list\"\nupdate-output\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
713
425
888
458
SHOW number of interactions
set which-output \"number-interactions\"\nupdate-output
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1230
481
1301
514
NIL
update\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1316
466
1466
536
NOTE pressing update will change the outcome of the simulation, regardless of whether or not any values were changed\n
11
0.0
1

BUTTON
894
425
1013
458
SHOW statistics
set which-output \"stats\"\nupdate-output\n\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1158
673
1328
706
regard-time?
regard-time?
0
1
-1000

SWITCH
1158
605
1328
638
online?
online?
1
1
-1000

INPUTBOX
2063
24
2304
84
homeroomID
999999999
1
0
String

INPUTBOX
2063
84
2304
144
homeroomUUID
11285a06-c692-4b9f-9c1e-284c5c1003aa
1
0
String

BUTTON
577
31
640
64
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
246
526
328
596
time-multiplier
2.0
1
0
Number

SWITCH
1158
639
1328
672
show-label
show-label
1
1
-1000

PLOT
759
34
1190
369
Infected Turtles
Time (ms)
Number of Turtles
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 total-num-infected + num-initial + 4\nset-plot-x-range 0 item 2 last link-list" ""
PENS
"default" 1.0 0 -2674135 true "" ""

BUTTON
643
31
706
64
finish
end-live-sim\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1717
743
1820
776
rewind?
rewind?
1
1
-1000

TEXTBOX
1706
726
1856
744
DOESNT DO ANYTHING YET
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

When used in conjunction with the Parallax BadgeWX, this program can be used as a tool for helping a participatory simulation.

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
