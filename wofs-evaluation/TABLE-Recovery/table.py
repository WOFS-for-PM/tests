# file_system file_size tail50 tail60 tail70 tail80 tail90 tail95 tail99 tail995 tail999 tail9995 tail9999 
# NOVA 1024 2736 2832 3043 4073 4307 4512 5011 5420 18764 19328 21529
# NOVA 32768 3356 3587 4092 4652 5216 5664 7123 7731 19379 20608 23270

import numpy as np
import pandas as pd

cols = ['Category', 'Workload', 'NOVA', 'DR', 'DR-OPT', 'WOLVES']
rows = ['fio', 'fileserver', 'weberver']
workload_names = ['FIO-32G', 'Fileserver', 'Webserver']
cat_names = ['Large file', 'Write intensive', 'Read intensive']

with open("./performance-comparison-table", "r") as f:
    df = pd.read_csv(f, delim_whitespace=True, engine='python')
    fss = df['file_system'].drop_duplicates().reset_index().drop(columns=['index'])['file_system']
    sort_dict = {
        "NOVA-FAIL" : 0, 
        "KILLER-DR-OPT" : 2,
        "KILLER-DR": 1,
        "KILLER-FAIL": 3,
    }
    sort_df = pd.DataFrame(df['file_system'].map(sort_dict))
    sort_df["workload"] = df['workload']
    df = df.iloc[sort_df.sort_values(by = ["file_system", "workload"]).index]

    new_df = pd.DataFrame(columns=cols)
    for row_idx, row in enumerate(rows):
        new_df.loc[len(new_df)] = [cat_names[row_idx], workload_names[row_idx]] + df.loc[(df['workload'] == row), "recovery"].values.tolist()
    
    print(new_df.to_latex(escape=False, index=False, header=True, column_format='c|c|c|c|c|c'))