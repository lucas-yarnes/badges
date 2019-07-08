extensions [ web table ]
globals [ url running? datalist test-list dataliststring strange-exceptions first-server-time new-room-id new-room-uuid prev-length prev-data connected-badges buffer-table data-list num-data failed-inters tolerance timestamp data-stream started? list-to-send legit-interactions mouse-was-down? list-links]
turtles-own [ code mod-name interactions ]
breed [badges badge]

to setup
  ;Set default value of some variables
  reset-variables
  ifelse use-prev-room?
  [
    load-info
  ]
  [
    ;Get the new room ID
    check-existing
    ;Create the new room with that ID
    create-new-room
    set prev-length length get-participants
    save-info
  ]
end

to reset-variables
  set url "http://gallery.app.vanderbilt.edu/badgerstate"
  set connected-badges table:make
  set buffer-table table:make
  set data-stream []
  set prev-data 0
  set data-list []
  set legit-interactions []
  set num-data 0
  set tolerance 2000
  carefully [
    set timestamp parse-timestamp (first web:make-request (word url "/n-data/" new-room-id "/" new-room-uuid "/1") "GET" [] [])
  ]
  [
    user-message "Don't forget to click setup before running simulation"
  ]
  set list-links []
  set failed-inters []
  clear-turtles
  clear-links
end

to fill-with-fakes
  let letters ["a" "b" "c" "d" "e" "f"]
  let numbers ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"]
  let index 0
  while [index < how-many]
  [
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
    table:put connected-badges name "no-uuid"
    set index index + 1
  ]
end

to generate-codes [ badges-list ]
  ifelse (length badges-list mod 2 = 0)
  [
    print "continuing"
  ]
  [
    let name item (length badges-list - 1) badges-list
    print (word "Badge " name " getting dropped, uneven number of players")
    set badges-list remove-item (length badges-list - 1) badges-list
  ]
  let half (length badges-list / 2)
  let codes []
  let index 0
  while [index < half]
  [
    let char1 random 10
    let char2 random 10
    let char3 random 10
    let char4 random 10
    let var (word char1 char2 char3 char4)
    set codes lput var codes
    set index index + 1
  ]
  set index 0
  let pos 0
  while [length badges-list > 0]
  [
    repeat 2 [
    let rand-num random length badges-list
    let temp-label item rand-num badges-list
    ask badges with [mod-name = temp-label]
    [
      set code item index codes
      ;set label code
    ]
    set badges-list remove-item rand-num badges-list

    ]
    set index index + 1
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
      set xcor random 28 + 2
      set ycor random 28 + 2
      set mod-name item index badges-to-add
      set code ""
      set label mod-name
      set interactions []
    ]
    set index index + 1
  ]

end

to run-game
  ask badges [ set color red ]
  clear-links
  set list-links []
  set running? true
  let index 0
  repeat random 5 + 5  ;  [10,20)
  [
    ask n-of random ((count badges / 2) + 1) badges
    [
      let temp-list []
      let rand random 1001
      set temp-list lput rand temp-list
      set temp-list lput mod-name temp-list
      let other-turtle one-of other badges
      set temp-list lput [mod-name] of other-turtle temp-list
      set interactions lput [mod-name] of other-turtle interactions
      ask other-turtle [ set interactions lput mod-name interactions ]
      set temp-list lput "false" temp-list
      set list-links lput temp-list list-links
    ]
  ]
  let link-num 0
  foreach list-links [
    the-link ->
    let pair []
    let code-pair []
    set pair lput item 1 the-link pair
    set pair lput item 2 the-link pair
    set index 0
    while [index < length pair]
    [
      ask turtles with [ mod-name = item index pair ]
      [
        set code-pair lput code code-pair
      ]
      set index index + 1
    ]
    show code-pair
    if item 0 code-pair = item 1 code-pair
    [
      let rand random 139
      ask turtles with [ code = item 0 code-pair ]
      [
        set color rand
      ]

      if item 1 the-link = item 0 pair and item 2 the-link = item 1 pair
      [
        let tem-list []
        set tem-list lput item 0 the-link tem-list
        set tem-list lput item 1 the-link tem-list
        set tem-list lput item 2 the-link tem-list
        set tem-list lput "true" tem-list
        set list-links replace-item link-num list-links tem-list
        ;show the-link
      ]
    ]
    set link-num link-num + 1
  ]

end

to run-sim
  ;if (ticks-elapsed >= 1000)
  ;[
    ;set ticks-elapsed 0
  ;]
  ifelse count badges > 0 [
    let index 0
    while [index < length list-links]
    [
      let temp-num 0
      carefully
      [
        set temp-num read-from-string item 0 item index list-links
      ]
      [
        set temp-num item 0 item index list-links
      ]
      ifelse temp-num <= ticks-elapsed
      [
        ask turtles with [ mod-name = item 1 item index list-links ]
        [
          ifelse (item 3 item index list-links = "true")
          [
            create-link-to one-of turtles with [ mod-name = item 2 item index list-links ] [set color blue set thickness .2]
          ]
          [
            create-link-to one-of turtles with [ mod-name = item 2 item index list-links ]
          ]
        ]
      ]
      ;if item 0 item index list-links > ticks-elapsed
      [
        let turtle1 0
        let turtle2 0
        ask one-of turtles with [ mod-name = item 1 item index list-links ] [ set turtle1 who ]
        ask one-of turtles with [ mod-name = item 2 item index list-links ] [ set turtle2 who ]
        ;show word turtle1 turtle2
        ask links with [ (end1 = turtle turtle2 and end2 = turtle turtle1) or (end1 = turtle turtle1 and end2 = turtle turtle2) ]
        [
          die
        ]
      ]
      set index index + 1
    ]
    layout-spring badges links .2 12 7
    set ticks-elapsed ticks-elapsed + (50 * speed-multiplier)
    wait .02
  ]
  [
    print "No turtles. Nothing to replay."
    stop
  ]
  ;if (ticks-elapsed >= 1000)
  ;[
    ;set ticks-elapsed 1000
    ;stop
  ;]
end

;to sort-list
;  let new-list []
;  let index1 0
;  let index2 0
;  while [length list-links > 0]
;  [
;    let minimum item 0 (item 0 list-links)
;    while [index2 < length list-links - 1]
;    [
;      let num1 item 0 (item index2 list-links)
;      if (num1 < minimum)
;      [
;        set list-links remove-item index2 list-links
;        show list-links
;        set new-list lput item index2 list-links new-list
;        show new-list
;        wait 1
;      ]
;      ;let num2 item 0 (item (index2 + 1) list-links)
;;      print num1
;;      print num2
;;      if (num1 > num2)
;;      [
;;        let temp item index2 list-links
;;        let temp2 item (index2 + 1) list-links
;;        show temp
;;        show temp2
;;        set list-links remove-item index2 list-links
;;        set list-links remove-item (index2 + 1) list-links
;;        show list-links
;;        set list-links insert-item index2 temp2 list-links
;;        show list-links
;;        set list-links insert-item (index2 + 1) temp list-links
;;        show list-links
;;      ]
;      set index2 index2 + 1
;    ]
;    set index2 0
;  ]
;  set list-links new-list
;end

to sort-list
  let new-list []
  let index 0
  let index2 0
  let smallest item 0 item 0 list-links
  let len length list-links
  let index-smallest 0
  let temp []
  while [index2 < len - 1]
  [
    while [index < length list-links]
    [
      let probe item 0 item index list-links
      if (probe < smallest)
      [
        set smallest probe
        set temp item index list-links
        set index-smallest index
      ]
      set index index + 1
    ]
    set index 0
    set index2 index2 + 1
    set new-list lput temp new-list
    set list-links remove-item index-smallest list-links
    set smallest item 0 item 0 list-links
    set temp item 0 list-links
    set index-smallest 0
  ]
  set new-list lput item 0 list-links new-list
  set list-links new-list
end

;let index 0
;  while [index < length legit-interactions]
;  [
;    let b1 item 0 item index legit-interactions
;    let b2 item 1 item index legit-interactions
;    ask turtles with [ label = b1 ] [create-links-to turtles with [label = b2]]
;    set index index + 1
;  ]
;  repeat 30 [ layout-spring badges links .2 5 2 ]

to refresh
  let now-time timestamp
  set buffer-table connected-badges
  set failed-inters []
  ;Clear previous turtles
  clear-turtles
  ;Check which participants are still active
  let temp-list []
  ;Post to MY signal the command to check activeness
  __ignore web:make-request (word url "/signal/" new-room-id "/" new-room-uuid "/active") "POST" [] []
  ;Give badges time to receive/process the command
  wait 10
  ;Check the signal of every previous participant to see if they responded
  let data-str (first web:make-request (word url "/data/" new-room-id "/" new-room-uuid "/" now-time) "GET" [] [])
  set temp-list parse-data-stream data-str
  set num-data num-data + length temp-list
  let ind 0
  while [ind < length temp-list]
  [
    set data-list lput parse-badge-data item ind temp-list data-list
    set ind ind + 1
  ]
  let badge-list table:keys connected-badges
  let index 0
  let active-badges []
  let active-keys []
  while [index < length data-list]
  [
    let index2 0
    while [index2 < length badge-list]
    [
      if (item 0 item index data-list = item index2 badge-list)
      [
        if (item 1 item (index) data-list = "ok")
        [
          set active-badges lput item index2 badge-list active-badges
        ]
      ]
      set index2 index2 + 1
    ]
    set index index + 1
  ]
  set index 0
  while [index < length active-badges]
  [
    let key table:get connected-badges item index active-badges
    set active-keys lput key active-keys
    set index index + 1
  ]
  table:clear connected-badges
  set index 0
  while [index < length active-badges]
  [
    table:put connected-badges item index active-badges item index active-keys
    set index index + 1
  ]
;  set index 0
;  set active-badges []
;  set active-keys []
;  set temp-list table:keys buffer-table
;  while [index < length data-list]
;  [
;    if item 1 item index data-list = "ok"
;    [
;      let index2 0
;      while [index2 < length temp-list]
;      [
;        if item 0 item index data-list = item 0 item index2 temp-list
;        [
;          set active-badges lput item index2 temp-list active-badges
;        ]
;        set index2 index2 + 1
;      ]
;    ]
;    set index index + 1
;  ]
;  set index 0
;  while [index < length active-badges]
;  [
;    let key table:get connected-badges item index active-badges
;    set active-keys lput key active-keys
;    set index index + 1
;  ]
;  set index 0
;  while [index < length active-badges]
;  [
;    table:put connected-badges item index active-badges item index active-keys
;    set index index + 1
;  ]
  set list-links []
  setup-game table:keys connected-badges
end

to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

to mouse-manager
 set mouse-was-down? mouse-down?
  if mouse-clicked?
  [
    show "clicked"
    select-badge
  ]
end

to select-badge
  ask turtles
    [
      if xcor = round mouse-xcor and ycor = round mouse-ycor
      [
        set target-badge mod-name
      ]
    ]
end

to print-data
  clear-output
  output-print "#\tNUM CONNECTIONS"
  foreach sort badges [
    t ->
    ask t [ output-print (word mod-name "\t" length interactions) ]
  ]
end


to go
  let first-received? false
  mouse-manager
  every 5 [
    print-data
  ]
  ;Check for new participants
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
      wait 2
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
      ifelse not button-press-required?
      [
        check-legitimacy ifelse-value (length data-list > 1) [length data-list] [2]
      ]
      [
        set index 0
        set data-seg []
        while [index < length data-list]
        [
          set data-seg parse-badge-data item index data-list
          show data-seg
          if not (item 1 data-seg = "ok")
          [
            carefully [
              do-thing (item 0 data-seg) (item 1 data-seg) (item 2 data-seg)
            ]
            [
              print "ERROR: did badge send everything?"
              set strange-exceptions lput data-seg strange-exceptions
            ]
          ]
          set index index + 1
        ]
      ]
    ]
  ]
end

to export-link-list
  let name ""
  ifelse default?
  [
    set name "listLinks.txt"
  ]
  [
    set name user-input "Enter file name: "
    set name word name ".txt"
  ]
  carefully [file-delete name] [print "file doesn't exist yet"]
  file-open name
  file-write list-links
  file-close-all
end

to setup-sim
  set ticks-elapsed 0
  set datalist []
  let turtles-present []
  let current-turtle ""
  file-close-all
  if-else in-another-file?
  [
    user-message "Choose an Interaction Dataset"
    let f user-file
    if f != false
    [
      file-open f
    ]
  ]
  [
    file-open "listLinks.txt"
  ]
  let line file-read-line
  carefully [
    set datalist run-result line
    if not file-at-end? [ user-message "there was more than one line in the file" ]
  ]
  [
    user-message ( word "There was an error in parsing the datafile:\n" error-message )
  ]
  file-close
  set list-links datalist
  foreach list-links [
    the-link ->
    set current-turtle item 1 the-link
    if not member? current-turtle turtles-present
    [
      set turtles-present lput current-turtle turtles-present
    ]
    set current-turtle item 2 the-link
    if not member? current-turtle turtles-present
    [
      set turtles-present lput current-turtle turtles-present
    ]
  ]
  ct
  clear-links
  foreach turtles-present [
    the-turtle ->
    create-badges 1 [
      set shape "circle"
      set size 0.5
      set color blue
      set xcor random 28 + 2
      set ycor random 28 + 2
      set mod-name the-turtle
      set code ""
      set label mod-name
    ]
  ]
end

to do-thing [ first-badge second-badge time ]
  let temp-list []
  let code1 ""
  let code2 ""
  let one 0
  let two 0
  let check? false
  ;Create link
  ifelse not member? second-badge table:keys connected-badges
  [
    print (word "Badge " first-badge " just received " second-badge " from another badge, but it doesn't exist in this simulation. Failed interaction.")
    let temporary []
    set temporary lput first-badge temporary
    set temporary lput second-badge temporary
    set failed-inters lput temporary failed-inters
    __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges first-badge "/failed") "POST" [] []
  ]
  [
    ask one-of turtles with [ mod-name = first-badge ]
    [
      if not member? second-badge interactions
      [
        set interactions lput second-badge interactions
      ]
      set code1 code
      set one who
    ]
    ask one-of turtles with [ mod-name = second-badge ]
    [
      if not member? first-badge interactions
      [
        set interactions lput first-badge interactions
      ]
      set code2 code
      set two who
    ]
    print (word "Code1: " code1 " and Code2: " code2)
    ask one-of turtles with [ mod-name = first-badge ]
    [
      ask my-links with [ (end1 = turtle one and end2 = turtle two) or (end1 = turtle two and end2 = turtle one) ] [ die ]
      ifelse code1 = code2 and code1 != "" and code2 != ""
      [
        print "same"
        create-link-with one-of turtles with [ mod-name = second-badge ] [set color red set thickness .5]
        __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges first-badge "/match") "POST" [] []
        __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges second-badge "/match") "POST" [] []
        set check? true
      ]
      [
        print "not same"
        create-link-with one-of turtles with [ mod-name = second-badge ]
        __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges first-badge "/successful") "POST" [] []
        __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges second-badge "/successful") "POST" [] []
      ]
    ]
    ;layout-spring badges links .2 5 2

    ;Add the link information to the list, for replay later
    set temp-list lput time temp-list
    set temp-list lput first-badge temp-list
    set temp-list lput second-badge temp-list
    set temp-list lput (word check?) temp-list
    set list-links lput temp-list list-links
  ]
end

to save-info
  file-close-all
  file-delete "longterm_storage.txt"
  file-open "longterm_storage.txt"
  let info []
  set info lput (word new-room-id "," new-room-uuid "," url) info
  file-write info
  file-close-all
end

to load-info
  reset-variables
  file-close-all
  file-open "longterm_storage.txt"
  let text file-read-line
  let pos1 position "\"" text
  let pos2 position "," text
  set new-room-id substring text (pos1 + 1) pos2
  set text substring text (pos2 + 1) length text
  let pos3 position "," text
  set new-room-uuid substring text 0 pos3
  set text substring text (pos3 + 1) length text
  let pos4 position "\"" text
  set url substring text 0 pos4
  file-close-all
  set timestamp parse-timestamp (first web:make-request (word url "/n-data/" new-room-id "/" new-room-uuid "/1") "GET" [] [])
  set prev-length length get-participants
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
    ask turtles with [mod-name = badge-mod-name] [die]
  ]
  let temp []
  set temp lput badge-mod-name temp
  setup-game temp
  table:put connected-badges badge-mod-name badge-bucket
  print (word "Badge " badge-mod-name " connected with bucket " table:get connected-badges badge-mod-name)
end

to send-small-data [target data]
  carefully
  [
    let bucket table:get connected-badges target
    ;Check first to see if badge received previous signal
    let check "1"
    while [check != "0"] [
      set check parse-signal-data (first web:make-request (word url "/signal/" new-room-id "/" bucket) "GET" [] [])
    ]
    ifelse (check = "0")
    [
      __ignore web:make-request (word url "/signal/" new-room-id "/" bucket "/" data) "POST" [] []
      print (word "sent " data " to badge " target)
    ]
    [
      print (word "send failed. Badge " target " did not receive last data yet")
    ]
  ]
  [
    print "It seems that badge isn't connected right now"
  ]
end

to send-large-data [target data]
  let bucket table:get connected-badges target
  let to-send ""
  let index 0
  let num-sent 0
  ;For each item in data list
  while [index < length data]
  [
    set to-send item index data
    set num-sent num-sent + 1
    set index index + 1
    __ignore web:make-request (word url "/data/" new-room-id "/" bucket "/" to-send) "POST" [] []
  ]
  ;Tell badge how many data points to check
  __ignore web:make-request (word url "/signal/" new-room-id "/" bucket "/N" num-sent) "POST" [] []

end

;to send-all-data [data]
;  let index 0
;  ;Get mod-names of all connected badges
;  let keys table:keys connected-badges
;  ;For each connected badge
;  while [index < table:length connected-badges]
;  [
;    ;Get the bucket id associated with the mod-name
;    let temp-bucket table:get connected-badges item index keys
;    ;Send the data request to that bucket
;    __ignore web:make-request (word url "/signal/" new-room-id "/" temp-bucket "/" data) "POST" [] []
;    set index index + 1
;  ]
;  print (word "sent " data " to all connected badges")
;end

to send-all-data [data]
  __ignore web:make-request (word url "/signal/" new-room-id "/" new-room-uuid "/" data) "POST" [] []
end

to join-default
  set homeRoomUUID (first web:make-request (word url "/join/" homeRoomID) "POST" [] [])
end

to-report parse-id [ data ]
  let startPos position "|" data
  let endPos position "&" data
  let id substring data (startPos + 2) endPos
  report id
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

to-report parse-timestamp [ data ]
  set timestamp 0
  let startPos position "timestamp" data
  if (startPos != false)
  [
  set timestamp substring data (startPos + 11) (length data - 2)
  ]
  report timestamp
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

to-report last-n-entries [entries]
  let index 0
  let to-print []
  while [index < entries]
  [
    print item (length data-stream - (entries - index)) data-stream
    set index index + 1
  ]
  report to-print
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

to check-legitimacy [ to-check ]
  let pair []
  let index 0
  let check? true
  repeat 3
  [
    set pair lput item (length data-stream - (to-check - index)) data-stream pair
    set index index + 1
  ]
  while [length pair = 3]
  [
    ifelse (item 0 (item 0 pair) != item 1 (item 1 pair))
    [
      set check? false
      show "failed 1"
    ]
    [
      show "passed 1"
    ]
    ifelse (item 0 (item 1 pair) != item 1 (item 0 pair))
    [
      set check? false
      show "failed 2"
    ]
    [
      show "passed 2"
    ]
    let val abs (read-from-string (item 2 (item 0 pair)) - read-from-string( item 2 (item 1 pair)))
    ifelse (val > tolerance)
    [
      set check? false
      show "failed 3"
    ]
    [
      show "passed 3"
    ]
    carefully [
      ifelse (check? = true)
      [
        set legit-interactions lput item 0 pair legit-interactions
        let code1 ""
        let code2 ""
        show pair
        ask one-of turtles with [mod-name = item 0 item 0 pair]
        [
          set code1 code
        ]
        ask one-of turtles with [mod-name = item 1 item 0 pair]
        [
          set code2 code
        ]
        show (word "code1 is: " code1 " and code2 is: " code2)
        let one item 0 pair
        let two item 1 pair
        let time item 2 pair
        ifelse (code1 = code2)
        [
          __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges one "/match") "POST" [] []
          __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges two "/match") "POST" [] []
        ]
        [
          __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges one "/successful") "POST" [] []
          __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges two "/successful") "POST" [] []
        ]
        do-thing one two time
      ]
      [
        __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges item 0 item 0 pair "/failed") "POST" [] []
        __ignore web:make-request (word url "/signal/" new-room-id "/" table:get connected-badges item 1 item 0 pair "/failed") "POST" [] []
      ]
    ]
    [
      print "Badge ID not correct, couldn't send response"
    ]
    ;;
    set pair replace-item 0 pair item 1 pair
    carefully [
      set pair replace-item 1 pair item (length data-stream - (to-check - index)) data-stream
      set index index + 1
    ]
    [ set pair remove-item 1 pair ]
  ]
end

to-report replace-all [str target replacement]
  let i (position target str)
  report (ifelse-value (i = false) [ str ] [replace-all (replace-item i str replacement) target replacement])
end

;web:make-request (word url "/signal/" homeRoomID "/" homeRoomUUID "/1&e61f999e-3c07-4d68-af31-a9a714395062"
@#$#@#$#@
GRAPHICS-WINDOW
345
55
817
528
-1
-1
14.061
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
30.0

BUTTON
88
123
223
156
NIL
setup
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
88
157
223
190
NIL
go\n
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
1507
108
1785
168
homeRoomID
999999999
1
0
String

INPUTBOX
1507
169
1785
229
homeRoomUUID
11285a06-c692-4b9f-9c1e-284c5c1003aa
1
0
String

MONITOR
1792
161
2014
206
NIL
new-room-id
17
1
11

MONITOR
1792
255
2015
300
NIL
timestamp
17
1
11

MONITOR
1792
302
2016
347
NIL
new-room-uuid
17
1
11

MONITOR
1792
208
2015
253
NIL
num-data
17
1
11

BUTTON
1545
375
1658
408
send-small-data
send-small-data target-badge data-to-send
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
1545
445
1658
478
send-large-data
send-large-data target-badge list-to-send
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
1545
410
1658
443
send-all-data
send-all-data data-to-send
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
1507
231
1785
291
target-badge
442f2e
1
0
String

INPUTBOX
1507
293
1785
353
data-to-send
hello
1
0
String

MONITOR
1792
114
2014
159
NIL
list-to-send
17
1
11

BUTTON
88
228
202
288
fake-simulation
reset-variables\nfill-with-fakes\nsetup-game table:keys connected-badges\ngenerate-codes table:keys connected-badges\nrun-game\n
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
206
228
320
288
how-many
50.0
1
0
Number

SLIDER
313
603
669
636
ticks-elapsed
ticks-elapsed
0
100000
509225.0
5
1
NIL
HORIZONTAL

BUTTON
420
567
563
600
NIL
run-sim
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
565
567
669
600
NIL
set ticks-elapsed 0
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
88
191
223
224
NIL
refresh
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
88
296
320
329
button-press-required?
button-press-required?
0
1
-1000

BUTTON
225
157
318
190
start-game
generate-codes table:keys connected-badges
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
88
336
320
369
NIL
export-link-list
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
225
191
318
224
adjust-layout
repeat 100 [layout-spring badges links .2 10 5]
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
313
567
418
600
NIL
setup-sim
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
171
566
311
599
in-another-file?
in-another-file?
1
1
-1000

INPUTBOX
672
567
812
636
speed-multiplier
5.0
1
0
Number

BUTTON
1068
91
1169
124
get-max
let in 0 \nset test-list []\nwhile [in < count badges] \n[ \nask badge in \n[\ncarefully [\nset test-list lput (word mod-name \"-\" length interactions) test-list \n]\n[\nprint (word \"couldn't add badge \" in \" to the list\") \n]\n]\nset in in + 1\n]\nlet maxi 0\nlet high-badge \"\"\nforeach test-list [\nthe-entry ->\nlet len read-from-string substring the-entry 7 length the-entry\nif len > maxi\n[\nset maxi len\nset high-badge substring the-entry 0 6\n]\n]\nshow (word \"Badge \" high-badge \" had the most entries at \" maxi \" entries\")
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
822
55
1062
666
11

BUTTON
1068
55
1168
88
NIL
clear-output
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
536
10
626
55
badges active
count badges
17
1
11

BUTTON
89
481
284
514
add failed inters to master list
file-close-all\nfile-open \"failed-interactions.txt\"\nforeach failed-inters [\ninter ->\nfile-write inter\n]\nset failed-inters []\nfile-close-all\nfile-open \"strange-exceptions.txt\"\nforeach strange-exceptions [\ninter ->\nfile-write inter\n]\nfile-close-all
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
88
370
178
403
default?
default?
1
1
-1000

SWITCH
88
88
223
121
use-prev-room?
use-prev-room?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

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
NetLogo 6.1.0
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
