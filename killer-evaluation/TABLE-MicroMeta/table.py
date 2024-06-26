# file_system workload tput(works/sec)
# NOVA DWTL 324248.226477
# NOVA MRPL 1886536.077307
# NOVA MWCL 132908.027645
# NOVA MWUL 108308.80139
# NOVA MWRL 95349.245215
# PMFS DWTL 544019.275122
# PMFS MRPL 1906196.171859
# PMFS MWCL 4375.47506
# PMFS MWUL 102069.562448
# PMFS MWRL 156326.209027
# KILLER DWTL 1491806.20183
# KILLER MRPL 1903694.261478
# KILLER MWCL 146539.040931
# KILLER MWUL 166253.250251
# KILLER MWRL 330692.204923
# SplitFS-FIO DWTL 28558.514324
# SplitFS-FIO MRPL 381436.615448
# SplitFS-FIO MWCL 69361.403431
# SplitFS-FIO MWUL 107863.694806
# SplitFS-FIO MWRL 271728.792926

import numpy as np
import pandas as pd

with open("./performance-comparison-table", "r") as f:
    df = pd.read_csv(f, delim_whitespace=True, engine='python')
    
    df = df.pivot(index='workload', columns='file_system', values='tput(works/sec)')
    df = df.applymap(lambda x: round(round(x) / 1000, 2))
    
    # print(df)
    # convert to latex
    print(df.to_latex())