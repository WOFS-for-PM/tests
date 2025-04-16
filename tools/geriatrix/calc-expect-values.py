#!/usr/bin/env python3

output="""
data_locality[4]: 0.035037
data_locality[5]: 0.0176691
data_locality[6]: 0.00750794
data_locality[7]: 0.00321714
data_locality[8]: 0.0477665
data_locality[9]: 0.0667372
data_locality[10]: 0.0606737
data_locality[11]: 0.0375551
data_locality[12]: 0.0195577
data_locality[13]: 0.00943899
data_locality[14]: 0.00351452
data_locality[15]: 0.00156415
data_locality[16]: 0.0188471
data_locality[17]: 0.01602
data_locality[18]: 0.013556
data_locality[19]: 0.00689772
data_locality[20]: 0.00332141
data_locality[21]: 0.00137877
data_locality[22]: 0.000339865
data_locality[23]: 0.000355314
data_locality[24]: 0.00231726
data_locality[25]: 0.00212416
data_locality[26]: 0.0020083
data_locality[27]: 0.000417108
data_locality[28]: 0.000108139
data_locality[32]: 0.0615465
data_locality[33]: 0.0887049
data_locality[34]: 0.0690699
data_locality[35]: 0.0394707
data_locality[36]: 0.0190479
data_locality[37]: 0.0071449
data_locality[38]: 0.00352224
data_locality[39]: 0.000301244
data_locality[40]: 0.0307424
data_locality[41]: 0.0256521
data_locality[42]: 0.0240069
data_locality[43]: 0.0131196
data_locality[44]: 0.00271892
data_locality[45]: 0.00139036
data_locality[46]: 0.000710628
data_locality[48]: 0.00240996
data_locality[49]: 0.00302789
data_locality[50]: 0.00308969
data_locality[51]: 0.000984837
data_locality[52]: 0.00100415
data_locality[53]: 0.000409383
data_locality[56]: 0.000432556
data_locality[57]: 0.00022014
data_locality[58]: 0.000224002
data_locality[64]: 0.0158192
data_locality[65]: 0.0160664
data_locality[66]: 0.00943127
data_locality[67]: 0.00569275
data_locality[68]: 0.00157574
data_locality[69]: 0.00106594
data_locality[70]: 0.000270348
data_locality[72]: 0.00333686
data_locality[73]: 0.00422901
data_locality[74]: 0.00257216
data_locality[75]: 0.00202761
data_locality[77]: 0.000297382
data_locality[81]: 0.00156415
data_locality[83]: 0.00064111
data_locality[85]: 0.000328279
data_locality[96]: 0.00222457
data_locality[97]: 0.00112387
data_locality[98]: 0.000756973
data_locality[100]: 0.000772421
data_locality[104]: 0.00120498
data_locality[105]: 0.000405521
data_locality[107]: 0.000413245
data_locality[128]: 0.0079096
data_locality[256]: 0.000988699
data_locality[384]: 0.00148305
"""

# extract subscript and value
data = {}
for line in output.split("\n"):
    if not line:
        continue
    key, value = line.split(":")
    key = key.split("[")[1].split("]")[0]
    data[key] = float(value)

# calculate expected value
expected = 0
for key in data:
    expected += (data[key] * int(key))

# round up to ^2
expected = 2 ** (round(expected).bit_length())

print(expected)