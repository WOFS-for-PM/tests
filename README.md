# WOFS Artifacts Evaluation



## Troubleshooting

### Filebench Evaluation

SplitFS will stuck under `webproxy.f` with more than 8 threads. Our workaround is to report the test results using our previous results. 

The user can also manually tests SplitFS under `webproxy.f` using our provided scripts.

There are two methods to resolve stuck issue:

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

### Real-world Workload Evaluation

SplitFS will also stuck for YCSB workload. Our workaround is also to report the test results using our previous results.