# WOFS Artifacts Evaluation



## Troubleshooting

Currently, we fail to incorporate the SplitFS test into our AE pipeline, as SplitFS will stuck under `webproxy.f` with more than 8 threads, and YCSB workload. Our workaround is to report the test results using the results in our paper.

Users can manually tests SplitFS using our provided scripts. 

- **For Filebench workload**, there are two methods to resolve stuck issue:

  - **Kill the `proxycache`**

      We find that once the `proxycache` process is killed, the test will continue. 

      ```bash
      kill -9 $(pidof proxycache)
      ```

      However, this will probably get an unexpected result, and we use the method below in our paper to ensure the correctness of the test.

  - **Re-run from the last successful test**
      ```bash
      cd tests/wofs-evaluation/FIG-Filebench
      # Start SplitFS test from 1 thread
      bash test-splitfs-webproxy.sh 1
      # if SplitFS stuck at 8 threads, please cancel the test with ctrl+c
      # Start SplitFS test from 8 threads
      bash test-splitfs-webproxy.sh 8
      ...
      # Until SplitFS has been successfully tested with 16 threads
      # Merge these results
      bash merge-splitfs.sh
      ```

- **For LevelDB-on-YCSB workload**

    - Manually run `test-ycsb-splitfs.sh`

    - The output will be saved in as `performance-comparison-table-splitfs`.
    