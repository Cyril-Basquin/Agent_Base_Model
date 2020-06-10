;TO DO => When worm eat
;      Reduce energy of the CalfLiver by the appropriate amount of energy


; The agent of the model
breed [ flatworms flatworm ]
flatworms-own [ energy food hungry recovery ]

; The food of the "main" Agent
breed [ CalfLivers CalfLiver ]
CalfLivers-own [ food ]


; Initilization of the environment
to setup
  clear-all

  set-default-shape flatworms "schmidtea"
  create-flatworms initial-number-flatworms [
       set color orange
       set energy flatworm-min-initial-size + random ( flatworm-max-initial-size - flatworm-min-initial-size )
       resize-flatworm
       setxy random-xcor random-ycor
       ]

  reset-ticks
end

to go
  if ticks >= max-ticks [ stop ]
  ; An option to feed and wash worms cyclically
  if automatic-washing = True [ if remainder (ticks - wash-after)  feed-each = 0 [ wash ] ]
  if automatic-feeding = True [ if remainder ticks feed-each = 0 [ make-CalfLiver ] ]
  if cut_at_start = True [ if ticks = 0 [ cut ] ]
  if automatic-cut = True [ if remainder ticks cut-each = 0 [ cut ] ]

  ; When food is present, diffuse a gradient that will attract worms
  diffuse-CalfLiver

  ; Worms basic behavior: Move & Eat
  ; Note the worms rush towards the food as they move twice when they see it.
  ask flatworms
     [ move-flatworm
     move-to-CalfLiver
     eat-CalfLiver
     if cannibalism = True [ cannibal ]
     degrowth-hungry
     degrowth-flatworm
     resize-flatworm
  ]

  ; Add +1 to tick counter
  tick
end

; Cutted worms move more slowly that 'healthy' one
; As the box is closed, those parameters is enough to stuck worms on the edge of the box which is an expected behavior
to move-flatworm
  (ifelse shape = "schmidtea"
                  [ rt random 50
                    lt random 50
                    fd 1 ]
                  [ set recovery recovery - 1
                    rt random 120
                    lt random 120
                    fd 0.1
                    if recovery < 0 [ set shape "schmidtea" ] ]
  )
end

; If worms are 'healthy' (not cut) they rush to food
to move-to-CalfLiver
  if (shape = "schmidtea") and (food = 0) and (hungry < 0)
         [ ask turtles-here
            [ if pcolor > CalfLiver-Detection [ uphill pcolor] ]
         ]
end

to degrowth-flatworm
  set energy energy * ( 1 - degrowth-rate )
end

to degrowth-hungry
   set hungry hungry - satiated-decrease
end

to resize-flatworm
  (ifelse shape = "schmidtea" [set size energy / flatworm-max-size * 3 ]
                              [set size energy / flatworm-max-size * 2 ] )
end


to reproduce-flatworms
  ; A fct to setup worm reproduction
  ;     If size of the worm < user-define-number, worms can't reproduce
  ;     If they reach the appropriate size they have a probability to reproduce
  ;     If density of the population is to high, reproduction is inhibited
  if (energy > size-to-reproduce * flatworm-max-size / 100) and (random-float 100 < probability-to-reproduce) and ( (count flatworms) * (mean [energy] of flatworms) < density-to-reproduce-threshold)

     ; When they reproduce the 'mother' worm keep 2/3 of it's size (= energy)
      [ set energy (energy / 3 * 2 )

     ; The 'daughter' worm is no
        hatch 1 [ ;rt random-float 360 fd 1
              set shape "circle"
              set energy energy / 2
              set recovery random (max-recovery-time - min-recovery-time) + min-recovery-time
              ;set size energy / flatworm-max-size * 2
            ]
      ]

end

to death  ;; turtle procedure
  ; When energy goes below zero, die
  if ( energy < 0 )  [ die ]
end



to make-CalfLiver
  if count CalfLivers < 1
  [
     set-default-shape CalfLivers "sheep"
     create-CalfLivers  1
       [
       set size 2
       set color red
       setxy x-CalfLiver y-CalfLiver
       set food
          (ifelse-value
                InfiniteEnergyCalfLiver = True [ 9999999999 ]
                                               [ SetEnergyCalfLiver ]
          )
       ]
  ]
end

; If a CalfLi
to diffuse-CalfLiver
  if count CalfLivers > 0
     [
     repeat 50
       [
       ask patch x-CalfLiver y-CalfLiver [ set pcolor white ]
       diffuse pcolor 1
       ]
     ask patch x-CalfLiver y-CalfLiver [ set pcolor white ]
     ]
end


;#################   EAT RELATED CODE   ###########################

to eat-CalfLiver  ; sheep procedure
  let prey one-of CalfLivers-here
  if (prey != nobody) and (food = 0)
     [
     ; Growth the worm ( = augment their energy)
     (ifelse  energy * ( 1 + growth-rate / 100 ) > flatworm-max-size [ set energy flatworm-max-size]
                                                                      [ set energy energy * ( 1 + growth-rate / 100 ) ]  )

     ; Set food to 1 ( as they ate, they can't eat anymore before a wash )
     set food 1
     set hungry satiated
     ]
end


to cannibal  ; wolf procedure
  let prey one-of flatworms-here                    ; grab a random sheep
  if (prey != nobody) and ( [energy] of prey <  energy * ( cannibalism-size / 100 ) ) and (hungry < 1) and (food = 0) and (pcolor < CalfLiver-detection) and (energy < flatworm-max-size)
  [                          ; did we get one? if so,
    set energy energy + ( ([energy] of prey) * cannibalism-efficiency / 100 )
    (ifelse    (energy + ( ([energy] of prey) * cannibalism-efficiency / 100 ) ) > flatworm-max-size [ set energy flatworm-max-size]
                                                                                                     [ set energy energy + ( ([energy] of prey) * cannibalism-efficiency / 100 ) ]  )
    set hungry satiated
    ask prey [ die ]
    ; get energy from eating
  ]
end


to wash
  ; Remove the food
  ask CalfLivers [ die ]
  ;
  ask flatworms [ set food 0
                  reproduce-flatworms
                  ;set size energy / flatworm-max-size * 3
                ]  ; max size of Healthy worms is 3
  ; Remove gradient diffusion of the food
  clear-patches
end


; ##################### AMPUTATION RELATED ###################################

to cut
  ask flatworms
  [if (energy > Min_Worm_Size) and (energy < Max_Worm_Size)

     ; When they reproduce the 'mother' worm keep 2/3 of it's size (= energy)
      [ set shape  "circle"
        set energy energy / 4
        ;set size energy / flatworm-max-size * 2
        set recovery random (max-recovery-time - min-recovery-time) + min-recovery-time
     ; The 'daughter' worm is no
        hatch Cut_In - 1 [ rt random-float 360 fd 1
              set shape "circle"
              set energy energy
              set recovery random (max-recovery-time - min-recovery-time) + min-recovery-time
        ]
]]
end



to extract

end
@#$#@#$#@
GRAPHICS-WINDOW
302
12
866
577
-1
-1
16.85
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
14
10
81
43
SETUP
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
165
10
228
43
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
86
10
161
43
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
13
89
249
122
initial-number-flatworms
initial-number-flatworms
1
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
13
158
249
191
flatworm-max-initial-size
flatworm-max-initial-size
flatworm-min-initial-size + 1
flatworm-max-size
200.0
1
1
NIL
HORIZONTAL

SLIDER
15
367
274
400
size-to-reproduce
size-to-reproduce
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
15
401
273
434
probability-to-reproduce
probability-to-reproduce
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
435
273
468
density-to-reproduce-threshold
density-to-reproduce-threshold
0
100000
60000.0
10
1
NIL
HORIZONTAL

SLIDER
12
614
248
647
flatworm-max-size
flatworm-max-size
0
1000
200.0
1
1
NIL
HORIZONTAL

SLIDER
911
52
1083
85
x-CalfLiver
x-CalfLiver
min-pxcor
max-pxcor
-4.0
1
1
NIL
HORIZONTAL

SLIDER
1087
51
1259
84
y-CalfLiver
y-CalfLiver
min-pycor
max-pycor
-4.0
1
1
NIL
HORIZONTAL

SLIDER
911
88
1082
121
SetEnergyCalfLiver
SetEnergyCalfLiver
0
10000
10000.0
1
1
NIL
HORIZONTAL

SWITCH
1086
89
1260
122
InfiniteEnergyCalfLiver
InfiniteEnergyCalfLiver
1
1
-1000

BUTTON
910
180
1020
213
NIL
make-CalfLiver
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
910
146
1021
179
NIL
wash
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
123
250
156
flatworm-min-initial-size
flatworm-min-initial-size
1
flatworm-max-initial-size - 1
1.0
1
1
NIL
HORIZONTAL

SLIDER
14
500
151
533
CalfLiver-Detection
CalfLiver-Detection
0
10
3.0
0.1
1
NIL
HORIZONTAL

PLOT
1306
286
1702
406
Number of worms
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"All" 1.0 0 -16777216 true "" "plot count flatworms"
"Small" 1.0 0 -13840069 true "" "plot count flatworms with [ size < 1 ]"
"Medium" 1.0 0 -5825686 true "" "plot count flatworms with [ ( size >= 1 ) and ( size < 2 )  ]"
"Big" 1.0 0 -955883 true "" "plot count flatworms with [ ( size >= 2 ) ]"

SLIDER
14
535
151
568
growth-rate
growth-rate
0
100
35.0
1
1
NIL
HORIZONTAL

PLOT
911
406
1306
526
Worms Size
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Bigger" 1.0 0 -2674135 true "" "plot max [ energy ] of flatworms"
"Smaller" 1.0 0 -13840069 true "" "plot min [ energy ] of flatworms"
"Mean" 1.0 0 -13345367 true "" "plot mean [ energy ] of flatworms"

PLOT
1117
534
1317
684
density
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ( sum [ energy ] of flatworms ) "

SWITCH
1022
180
1178
213
automatic-feeding
automatic-feeding
0
1
-1000

SWITCH
1022
146
1178
179
automatic-washing
automatic-washing
0
1
-1000

INPUTBOX
1250
146
1317
211
wash-after
30.0
1
0
Number

INPUTBOX
1184
146
1248
212
feed-each
200.0
1
0
Number

MONITOR
1100
237
1150
282
Smaller
min [ energy ] of flatworms
0
1
11

MONITOR
1149
237
1199
282
Bigger
max [ energy ] of flatworms
0
1
11

MONITOR
1198
237
1248
282
Count
count flatworms
17
1
11

MONITOR
1247
237
1306
282
Density
( sum [ energy ] of flatworms ) / density-to-reproduce-threshold * 100
1
1
11

TEXTBOX
33
61
296
88
Initial worm population
20
15.0
1

TEXTBOX
66
219
216
244
Worms Biology
20
15.0
1

TEXTBOX
17
245
167
265
Healing
16
0.0
1

TEXTBOX
16
478
166
498
Eating
16
0.0
1

TEXTBOX
941
126
1091
146
Manual
16
0.0
1

TEXTBOX
1217
126
1367
146
Automatic
16
0.0
1

TEXTBOX
911
32
1108
50
Localisation & Quantity
16
0.0
1

TEXTBOX
16
345
166
365
Reproduction
16
0.0
1

TEXTBOX
1047
10
1197
35
Feeding
20
15.0
1

TEXTBOX
914
245
1064
270
Monitoring
20
15.0
1

INPUTBOX
15
265
119
325
min-recovery-time
90.0
1
0
Number

INPUTBOX
120
265
224
325
max-recovery-time
150.0
1
0
Number

TEXTBOX
14
595
164
615
Miscellaneous
16
0.0
1

TEXTBOX
644
580
715
606
Cutting
20
15.0
1

INPUTBOX
401
613
494
673
Min_Worm_Size
30.0
1
0
Number

INPUTBOX
499
612
592
672
Max_Worm_Size
110.0
1
0
Number

INPUTBOX
689
612
739
672
Cut_In
4.0
1
0
Number

BUTTON
620
627
683
660
Cut
cut
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
774
581
1029
606
Extraction
20
15.0
1

BUTTON
772
627
844
660
NIL
Extract
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
531
692
663
725
automatic-cut
automatic-cut
1
1
-1000

INPUTBOX
686
676
739
736
cut-each
2000.0
1
0
Number

SWITCH
401
692
526
725
cut_at_start
cut_at_start
1
1
-1000

INPUTBOX
243
10
301
70
max-ticks
20000.0
1
0
Number

SLIDER
13
651
248
684
degrowth-rate
degrowth-rate
0
0.01
0.001
0.001
1
NIL
HORIZONTAL

SWITCH
17
700
135
733
cannibalism
cannibalism
1
1
-1000

SLIDER
155
500
291
533
satiated
satiated
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
155
536
292
569
satiated-decrease
satiated-decrease
0
10
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
137
701
285
734
cannibalism-efficiency
cannibalism-efficiency
0
100
80.0
1
1
%
HORIZONTAL

PLOT
912
284
1306
404
% of worm by size
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Small" 1.0 0 -13840069 true "" "plot (count flatworms with [ size < 1 ]) / (count flatworms) "
"Medium" 1.0 0 -5825686 true "plot ( count flatworms with [ ( size >= 1 ) and ( size < 2 )  ] ) / ( count flatworms )" "plot ( count flatworms with [ ( size >= 1 ) and ( size < 2 )  ] ) / ( count flatworms )"
"Big" 1.0 0 -955883 true "plot (count flatworms with [ size > 2 ]) / (count flatworms)" "plot (count flatworms with [ size > 2 ]) / (count flatworms)"

SLIDER
136
736
284
769
cannibalism-size
cannibalism-size
0
100
40.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the evolution of a population of flatworms (Schmidtea Mediterranea) in a controlled Laboratory condition.

 

## HOW IT WORKS

### WORMS STATE:
Worms have 2 states:
    - 'Healthy' (shape "schmidtea"): they are able to eat and reproduce
    - 'Wounded' (shape "circle") : the contrary

To switch from wounded to healthy, a worm need to wait a certain recovery time

### FEEDING:
When food is put in the box, it diffuse odor in the container that attract Healthy worms. When worms reach the food they eat it (once). Of course it makes them growth. After food is removed (wash) worms can reproduce by scission and move quite randomly in the container. 

### REPRODUCTION:
(When wash is triggered) 
The 'mother' worm stay healthy (but loose 33% of it's size (=energy)) the daughter worm is wounded and 'born' with a size of 33% of her mother.


**Note: If they are starved, worms don't degrowth.**


## HOW TO USE IT

Note: the name of the parameter is the same that the name of the variable use in the code

### SETUP & GO

**SETUP**: Initialize the population
**go once**: move forward in time ('tick')
**go**: move forward continously


### INITIAL WORM POPULATION

**inital-number-flatworms** : How many flatworm do you want to start with?
**flatworm-min-initial-size** : Minimal flatworms size in the population
**flatworm-max-initial-size** : Maximal flatworms size in the population

### WORMS BIOLOGY

Some biological properties of the worms.

#### *HEALING:*
In how many time worms recover from wounded to healthy:
**min-recovery-time / max-recovery-time** . The existence of those 2 parameters allows to have some heterogeneity in the population. This might be usefull if the rate of feeding is higher that the rate of recovery.

#### *REPRODUCTION:*
**size-to-reproduce** : the minimal size require to allow reproduction of a worm
**probability-to-reproduce** : the probability of reproduction if the worm is allowed to reproduce.
**density-to-reproduce-threshold** : this parameters correspond to the total size (energy) of the flatworms population. If this threshold is reach, worms can't reproduce.

Note: with a density of 10000 and a max size of 50-100, the max number of worm is ~250-300.

#### *EATING:*
**CalfLiver-Detection**: worms detect food thanks to the difusion of a gradient of 'odor'. This parameter define what is the detection sensibility of this odor by the worm. This parameter can be useful if you don't want to attract all the worms to the food  
**growth-rate**: Define the growth (in %) of the worm once he ate.

#### *MISCELLANEOUS:*
**flatworm-max-size**: The maximum size that a worm can reach.


### FEEDING

Condition of the feeding:

#### *LOCALISATION & QUANTITY:*

Not completly implemented (V2). So far Food is unlimited and localisation is quite redondant with **CalfLiver-Diffusion**  and **wash-after**: it can affect the number of worms which have enough time to eat.

**x-CalfLiver / y-CalfLiver**: Localisation of the food in the container
**SetEnergyCalfLiver**: amount of food you put in the container (not implemented)
**InfiniteEnergyCalfLiver**: (ON/OFF) do you put an infinite amount of food in the container (not implemented)

#### *MANUAL / AUTOMATIC:*
**automatic-feeding** / **automatic-washing** : (ON/OFF) 

If They are set ON automatic, define the periodicity of feeding (**feed-each**). Then the container is wash **wash-after** after feeding.
Note: if **automatic-feeding** is set to off and **automatic-washing** is set to ON this rule still apply: the periodicity of washing is set each **feed-each**

If They are set OFF automatic, just click **make-CalfLiver** button to put food an **wash** to wash.

Note: the **wash** button can also be use as a **reproduce** button since it trigger worm scission.


### MONITORING

Monitoring of some features of the population. Size of the **smaller** and the **bigger** worm. Total number of worms (**count**). **Density** of the population normalized in % with **density-to-reproduce-threshold** (When this value reach 100, worms do not reproduce anymore)

Plot **Number of worms** shows the evolution of the total number of worms, and numbers of **Small**, **Medium** and **Big** worms. Those catergories are define thanks to the **flatworm-max-size** as follow:
0 < **Small** < 0.33 * flatworm-max-size
0.33 * flatworm-max-size =< **Medium** < 0.66 * flatworm-max-size
0.66 * flatworm-max-size =< **Big**

Plot **Worm Size** shows evolution of the **Smaller** and **Bigger** worm as well as the **Mean** size of the population

### CUTTING 

A Button that Cut in **Cut_in** pieces all the worms of size bigger than **Min_Worm_Size** and smaller that **Max_Worm_Size**
**cut_at_start** : Do you want the initial population to be cut?
**cut-automatic**: Do you want to cut automatically each **cut-each** ticks

### EXTRACT

Not implemented yet.
A Button that Extract (and count) from the container all the worms of size bigger than **Min_Worm_Size** and smaller that **Max_Worm_Size**

## NOT IMPLEMENTED / TO MODIFY
Extract button is not yet implemented
Amount of food is for the moment only infinite
CANNIBALISM

So far, the gradient is created as : Create patch at position X-Y
I should modify this by            : If CalfLiver-here create patch
This modification will allow to put food in a random manner, and more that 1 piece of liver can be put on the container


## EXTENDING THE MODEL
Locomotion behavior:
  - In the current model, worms are 'stuck' in the edge of the container due to the limitation in the difficulty that they have to turn. In reality, they like the edge of the container because it's not horizontal (they 'climb' on the side of the container) and lhey like to be together.
  - They avoid light. Adding a light to make them fly away the source of the light
  - A week proportion of worm glide (slowly) under the surface of the water

Note: in laboratory conditions, worms eat Calf not Sheep but there is no Calf symbol.
	


## CREDITS AND REFERENCES

Author of this NetLogo Model: Cyril Basquin
Contact: cyril.basquin@edu.dsti.institute
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

schmidtea
true
2
Circle -955883 true true 117 76 67
Circle -955883 true true 117 158 67
Rectangle -955883 true true 117 109 184 198
Circle -16777216 true false 131 93 13
Circle -16777216 true false 131 93 13
Circle -16777216 true false 155 93 13

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
<experiments>
  <experiment name="Optimize_reproduction" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="cut_at_start">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="40"/>
      <value value="70"/>
      <value value="100"/>
      <value value="130"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="100000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Optimize_reproduction_sgle_output" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="cut_at_start">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="40"/>
      <value value="70"/>
      <value value="100"/>
      <value value="130"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="100000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Optimize_food_sgle_40" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="cut_at_start">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="100000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cannibalism_feed_50" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-size">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-efficiency">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut_at_start">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrowth-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated-decrease">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cannibalism_feed_100" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-size">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-efficiency">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut_at_start">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrowth-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated-decrease">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cannibalism_feed_150" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-size">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-efficiency">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut_at_start">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrowth-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated-decrease">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cannibalism_feed_200" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>count turtles</metric>
    <metric>sum [ energy ] of flatworms</metric>
    <enumeratedValueSet variable="Max_Worm_Size">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-flatworms">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-min-initial-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfiniteEnergyCalfLiver">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="20000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-feeding">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-recovery-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-size">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wash-after">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut-each">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism-efficiency">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-to-reproduce">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cut_at_start">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cut_In">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flatworm-max-initial-size">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-cut">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_Worm_Size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-to-reproduce-threshold">
      <value value="60000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-to-reproduce">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrowth-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-CalfLiver">
      <value value="-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satiated-decrease">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="automatic-washing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-recovery-time">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfLiver-Detection">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetEnergyCalfLiver">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cannibalism">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feed-each">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
