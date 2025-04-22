# file_system file_size tail50 tail60 tail70 tail80 tail90 tail95 tail99 tail995 tail999 tail9995 tail9999 
# NOVA 1024 2736 2832 3043 4073 4307 4512 5011 5420 18764 19328 21529
# NOVA 32768 3356 3587 4092 4652 5216 5664 7123 7731 19379 20608 23270

import numpy as np
import pandas as pd

cols = ['Workload', 'MadFS', 'WOLVES', 'Speedup']
rows = ['fileserver.f', 'varmail.f', 'webserver.f', 'webproxy.f']
workload_names = ['Fileserver', 'Varmail', 'Webserver', 'Webproxy']

with open("./performance-comparison-table", "r") as f:
    df = pd.read_csv(f, delim_whitespace=True, engine='python')
with open("./performance-comparison-table-madfs", "r") as f:
    madfs_df = pd.read_csv(f, delim_whitespace=True, engine='python')
    
    
new_df = pd.DataFrame(columns=cols)
for row_idx, row in enumerate(rows):
    bws = []
    for _df in [madfs_df, df]:
        fs_name = "KILLER" if _df is df else "MadFS"
        bws.append(_df.loc[(_df['file_bench'] == row) & (_df["threads"] == 1) & (_df["file_system"] == fs_name), "iops"].values[0] / 1000)
        
    new_df.loc[len(new_df)] = [workload_names[row_idx]] + bws + [bws[1] / bws[0]]
            

print(new_df.to_latex(escape=False, index=False, header=True, column_format='c|c|c|c|c|c'))