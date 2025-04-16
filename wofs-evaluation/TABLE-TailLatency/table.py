# file_system file_size tail50 tail60 tail70 tail80 tail90 tail95 tail99 tail995 tail999 tail9995 tail9999 
# NOVA 1024 2736 2832 3043 4073 4307 4512 5011 5420 18764 19328 21529
# NOVA 32768 3356 3587 4092 4652 5216 5664 7123 7731 19379 20608 23270

import numpy as np
import pandas as pd

fss = ['NOVA', 'PMFS', 'KILLER', 'SplitFS-FIO', "MadFS"]
cols = ['file_system', 'tail50', 'tail90', 'tail99', 'tail999', 'tail9999']
row_names = ['%ile', '50%', '90%', '99%', '99.9%', '99.99%']
col_names = ['KILLER', 'NOVA', 'PMFS', 'SplitFS', "MadFS"]
with open("./performance-comparison-table", "r") as f:
    df = pd.read_csv(f, delim_whitespace=True, engine='python')
    # extract file_size = 32768
    df = df[df['file_size'] == 32768]
    # remain only fss
    df = df[df['file_system'].isin(fss)].reset_index().drop(columns=['index'])
    # remain only tails
    df = df.drop(columns=[col for col in df.columns if col not in cols])
    # divide 1000 for numeric columns
    for col in cols[1:]:
        df[col] = round(df[col] / 1000.0, 2)
    # transpose
    df = df.T
    # rename rows
    df = df.rename(index=dict(zip(df.index, row_names)))
    # sort cols as ['KILLER', 'NOVA', 'PMFS', 'SplitFS-FIO']
    df = df.reindex(columns=[2, 0, 1, 3, 4])
    # do not use bottom rules, using hline instead.
    print(df.to_latex(escape=False, index=True, header=False, column_format='l|r|r|r|r|r|r|r|'))