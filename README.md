# WOFS Artifacts Evaluation

This repository contains the artifacts for the paper "Fast and Synchronous Crash Consistency with Metadata Write-Once File System" (WOFS) accepted by OSDI'25.

- [WOFS Artifacts Evaluation](#wofs-artifacts-evaluation)
  - [1. Artifact Overview](#1-artifact-overview)
  - [2. Primary Evaluation on Optane DCPMM](#2-primary-evaluation-on-optane-dcpmm)
    - [2.1 Quick Start](#21-quick-start)
      - [2.1.1 Prerequisites](#211-prerequisites)
      - [2.1.2 Usage of Repository](#212-usage-of-repository)
      - [2.1.3 One-click run](#213-one-click-run)
    - [2.2 Step-by-Step Reproducing](#22-step-by-step-reproducing)
      - [2.2.1 Output Results](#221-output-results)
      - [2.2.2 Reproducing Figures](#222-reproducing-figures)
      - [2.2.3 Reproducing Tables](#223-reproducing-tables)
  - [3. Crash Consistency Evaluation on Virtual Machine](#3-crash-consistency-evaluation-on-virtual-machine)
    - [3.1 Quick Start](#31-quick-start)
      - [3.1.1 Prerequisites](#311-prerequisites)
      - [3.1.2 Usage of Repository](#312-usage-of-repository)
    - [3.2 Crash Consistency Evaluation](#32-crash-consistency-evaluation)
  - [4. MS-SSD Evaluation on an NVMe Server](#4-ms-ssd-evaluation-on-an-nvme-server)
    - [4.1 Quick Start](#41-quick-start)
      - [4.1.1 Prerequisites](#411-prerequisites)
      - [4.1.2 Usage of Repository](#412-usage-of-repository)
      - [4.1.3 One-click run](#413-one-click-run)
    - [4.2 Step-by-Step Reproducing](#42-step-by-step-reproducing)
  - [Troubleshooting](#troubleshooting)

## 1. Artifact Overview

Our artifacts involve three platforms: (1) a server with Optane DCPMM that conducts primary performance evaluation, (2) a virtual machine with emulated PM that conducts crash consistency evaluation, and (3) a server with NVMe SSD that conducts our emulated memory-semantic SSD evaluation. For reviewer's convenience, we have provided the isolated environments for each platform. 

**NOTE: The overall experiments can take around one day or less, please run experiments in the tmux or other terminal multiplexers to avoid losing AE progress.**

**Organization of repositories.** WOFS project is composed of various repositories, which are all available. We now briefly introduce the usage of each repository as follows:

- Wolves source code for Optane DCPMM: https://github.com/WOFS-for-PM/WOFS.git
- Wolves source code for MS-SSD: https://github.com/WOFS-for-PM/WOFS-MS-SSD.git
- PMFS@EuroSys'12 source code: https://github.com/WOFS-for-PM/PMFS.git
- NOVA@FAST'16 source code: https://github.com/WOFS-for-PM/NOVA.git
- SplitFS@SOSP'19 source code: https://github.com/WOFS-for-PM/SplitFS.git
- SoupFS@USENIX ATC'17 source code: https://github.com/WOFS-for-PM/SoupFS.git
- MadFS@FAST'23 source code: https://github.com/WOFS-for-PM/MadFS.git
- WineFS@SOSP'21 source code: https://github.com/WOFS-for-PM/WineFS.git
- F2FS@FAST'16 source code: https://github.com/WOFS-for-PM/F2FS-6.6.32.git
- Evaluation tools and scripts: https://github.com/WOFS-for-PM/tests.git.
- LevelDB and RocksDB source code: https://github.com/WOFS-for-PM/applications.git

## 2. Primary Evaluation on Optane DCPMM

### 2.1 Quick Start

#### 2.1.1 Prerequisites

- **Kernel**: Linux kernel 5.1.0 modified by [SplitFS](https://github.com/rohankadekodi/SplitFS-5.1).

- **Hardware**: At least one PM equipped (>64\,GiB), which can be either real PM or emulated PM (via `memmap` or QEMU `-device nvdimm` options). PM should be configured in `fsdax` mode.

- **Software**: The following software should be installed in the system:

  - FIO version 3.X, which can be installed via `apt install fio` or `yum install fio`.
  
  - Filebench version 1.5-alpha3, which is compiled from [Filebench](https://github.com/Workeryuan/filebench.git). Also make sure that the binary is located in `/usr/local/filebench/filebench`, our test scripts are based on this path.

#### 2.1.2 Usage of Repository

Now, the user should run the following command to organize repositories so that the scripts can work correctly:

```bash
#!/bin/bash
cd <Your directory>

git clone https://github.com/WOFS-for-PM/applications.git applications
bash compile.sh # compile LevelDB and RocksDB
bash install.sh # install LevelDB and RocksDB to /usr/local

git clone https://github.com/WOFS-for-PM/tests.git tests
git clone https://github.com/WOFS-for-PM/WOFS.git hunter-kernel
git clone https://github.com/WOFS-for-PM/NOVA.git nova
git clone https://github.com/WOFS-for-PM/SoupFS.git eulerfs
git clone https://github.com/WOFS-for-PM/SplitFS.git splitfs
git clone https://github.com/WOFS-for-PM/WineFS.git winefs
git clone https://github.com/WOFS-for-PM/MadFS.git MadFS
git clone https://github.com/WOFS-for-PM/PMFS.git pmfs
```

#### 2.1.3 One-click run

All the corresponding test scripts and results for reference (in the "paper" directory) are included in the `tests/wofs-evaluation` directory. After setting up the experimental environment, the user changes the directory to where the scripts stand and runs the script by typing `./test.sh`. Note that the user is required to run in `sudo` mode. Also note that we have provided a one-click script `run_all.sh` in the root directory of "tests", which can automatically run all the experiments involved in the paper, draw all the figures in our paper, and build similar Latex tables presented in our paper. The specific reproducing steps of each experiment are described in the following subsections.

### 2.2 Step-by-Step Reproducing

#### 2.2.1 Output Results

We focus on introducing the files in the directories with prefixes "FIG" and "TABLE". The raw output files are mostly named with the prefix "performance-comparison-table", which can be obtained by running `bash test.sh`. `plot.ipynb` and `table.py` scripts are provided for drawing figures and building latex table, respectively. Almost all experiments (except Filebench\footnote{Filebench naturally runs a fairly long time, and its output is very stable; thus, we only report its one run.}) can be conducted many times just by passing a `loop` variable to the `test.sh`, and a `agg.sh` script is provided to present the average values. We rename the original file with the suffix `_orig`.

Generally, typical workflows for reproducing figures and tables are presented as follows.

```bash
# General workflow to reproducing tables

cd <Your directory>/tests/wofs-evaluation/TABLE-xx/
# Step 1. Run Experiment
bash ./test.sh $loop
# Step 2. Aggregate Results
bash agg.sh "$loop"
# Step 3. Building Table
python3 table.py > latex-table
```

```bash
# General workflow to reproducing figures
cd <Your directory>/tests/wofs-evaluation/FIG-xx/
# Step 1. Run Experiment
bash ./test.sh $loop
# Step 2. Aggregate Results
bash agg.sh "$loop"
# Step 3. Drawing Figures
ipython plot.ipynb
```

In the following subsections, we consider the `loop` as 1 by default for brevity.

#### 2.2.2 Reproducing Figures

**Figure 2: The study of crash consistency techniques in PM.** The script is located at `tests/wofs-evaluation/FIG-CrashConsistencyBreakdown/test.sh`. The output performance results are presented in `performance-comparison-table-NOVA`, `performance-comparison-table-PMFS`, and `performance-comparison-table-SplitFS`. The user can use `plot.ipynb` to plot the figure: `FIG-MetaObservation.pdf`.

**Figure 6: I/O performance comparison under different I/O patterns.** The script for Figure 6 is located at `tests/wofs-evaluation/FIG-IO-Single/test.sh`. The output results are presented in `performance-comparison-table-bsize` and `performance-comparison-table-bsize-madfs` (for various block size with a total of 1\,GiB I/O), and `performance-comparison-table-fsize` and `performance-comparison-table-fsize-madfs` (for various file size under the same 4\,KiB block size). The plot script is located in `tests/wofs-evaluation/FIG-IO-Single/plot.ipynb`, and the output figure is `FIG-IO-VERTICAL.pdf`.

**Figure 7: Concurrency performance comparison.** The corresponding script is presented in `tests/wofs-evaluation/FIG-MT-FIO/test.sh`. The output results are presented in `performance-comparison-table`. Simply run the `plot.py` to obtain the figure: `FIG-Concurrency-Small.pdf`.

**Figure 8: FxMark evaluation.** The corresponding script is presented in `tests/wofs-evaluation/FIG-MicroMeta/test.sh`. The output results are presented in `performance-comparison-table`. The user can use `plot.ipynb` to plot the figure: `FIG-Meta.pdf`.

**Figure 9: Filebench evaluation.** The script is presented in `tests/wofs-evaluation/FIG-Filebench/test.sh`. The output results are presented in `performance-comparison-table`. The user can use `plot.ipynb` to plot the figure: `FIG-Filebench.pdf`.

Note that SplitFS might fail (in an unknown probability) during multi-threaded Filebench tests. Please manually exclude SplitFS from `test.sh` script, and repeat running the SplitFS using another stand-alone script, such as `test-splitfs-webproxy.sh` provided in our repository.

**Figure 10: Filebench operation latency breakdown.** The script is presented in `tests/wofs-evaluation/FIG-Filebench/breakdown.sh`, which simply parses the output results in Figure 9. The output results are presented in `performance-comparison-table-fileserver`, `performance-comparison-table-varmail`, `performance-comparison-table-webproxy`, and `performance-comparison-table-webserver`. The user can use `plot-breakdown.ipynb` to plot the figure: `FIG-MacroBreakdown-VERTICAL.pdf`.

**Figure 11: Wolves I/O breakdown.** The test script for Figure 2 has already evaluated the I/O breakdown of Wolves. The output results are presented in `performance-comparison-table-KILLER` (KILLER is our previous name, which should be modified in the future) in `tests/wofs-evaluation/FIG-CrashConsistencyBreakdown/`. The user can use `plot.ipynb` to plot the figure: `FIG-KILLERStudy.pdf`.

**Figure 12: Wolves techniques breakdown.** The corresponding script is located at `tests/wofs-evaluation/FIG-Breakdown/test.sh`. The results are presented in `performance-comparison-table-large`. The user can use `plot.ipynb` to plot the figure: `FIG-Breakdown.pdf`.

**Figure 13: Application performance comparison.** The corresponding script is located at `tests/wofs-evaluation/FIG-RealWorld/test.sh`. The results are composed of two parts: `performance-comparison-table` for LevelDB-on-YCSB, and `performance-comparison-table-rocksdb` for RocksDB. The user can use `plot.ipynb` to plot the figure: `FIG-RealWorld.pdf`.

Note that SplitFS might stuck during LevelDB test, which is caused by older version of `libtcmalloc.so` library. The user can fix this issue by either compiling [LevelDB without using `libtcmalloc`](https://github.com/WOFS-for-PM/applications/leveldb-no-tcmalloc), or linking LevelDB to [the newest version of `libtcmalloc`](https://github.com/WOFS-for-PM/applications/gperfools).

**Figure 14: Aging/Fragmentation performance.** The corresponding test script is located at `tests/wofs-evaluation/FIG-Fragmentation/test.sh`. The performance results are composed of six parts: `seq/rand-KILLER_bw.1.log` for Wolves sequential/rand write bandwidth curves, `seq/rand-NOVA_bw.1.log` for NOVA bandwidth curves, and `seq/rand-WINEFS_bw.1.log` for PMFS bandwidth curves (with WineFS's defragmentation technique). The user can use `plot.ipynb` to plot the figure: `FIG-Aging.pdf`.

Note that we do not aim to run the real Agrawal profile, but we emulate its block distribution for Wolves. WineFS and NOVA should have negligible performance degradation compared to a freshed system since (1) WineFS mainly optimizes `mmap` performance, and (2) NOVA adopts no huge allocation techniques, and it timely triggers GC to avoid fragmentation.

**Figure 15: Comparison with (synchronous) soft update.** The corresponding test script is presented at `tests/wofs-evaluation/FIG-SOFT-UPDATE/test.sh`. The results are presented in `performance-comparison-table-fio`, `performance-comparison-table-fio-fsync`, and `performance-comparison-table-filebench`. The user can use `plot.ipynb` to plot the figure: `FIG-SU.pdf`.

#### 2.2.3 Reproducing Tables

<!-- \paragraph{Table 4: Tail latency comparison.} The corresponding scripts for Table 4 are presented in \lstinline|tests/wofs-evaluation/TABLE-TailLatency/test.sh|. To reproduce the table, one can follow the commands: -->

**Table 4: Tail latency comparison.** The corresponding scripts for Table 4 are presented in `tests/wofs-evaluation/TABLE-TailLatency/test.sh`. To reproduce the table, one can follow the commands:

```bash
cd tests/wofs-evaluation/TABLE-TailLatency/
# Run FIO and extract tail latency with extract.py
bash ./test.sh 1
# build Table 2
python3 table.py > latex-table
```

**Table 5: Filebench comparison with MadFS.** The corresponding script for Table 5 is presented in `tests/wofs-evaluation/TABLE-Filebench/test-madfs.sh`. Similarly, to reproduce this table, one can follow the commands:

```bash
cd tests/wofs-evaluation/FIG-Filebench/
bash ./test-madfs.sh 1
bash agg.sh 1
# build Table 5
python3 table.py > latex-table
```

<!-- \paragraph{Table 6: Failure recovery time.} The corresponding script for Table 6 is presented in \lstinline|tests/wofs-evaluation/TABLE-Recovery/test-common.sh|. To reproduce this table, one can follow the commands: -->

**Table 6: Failure recovery time.** The corresponding script for Table 6 is presented in `tests/wofs-evaluation/TABLE-Recovery/test-common.sh`. To reproduce this table, one can follow the commands:

```bash
cd tests/wofs-evaluation/FIG-Recovery/
bash ./test-common.sh 1
# formatting time
bash agg.sh 1
# build Table 6
python3 table.py > latex-table
```

Note that there are still some bugs in the `osdi25-dr-recovery` and `osdi25-dr-opt-recovery` branches, which may lead to memory leaks, which we plan to fix in the future. We also provide `worst.sh` to reproduce the worst-case recovery time, which is now described in Subsection 6.9. The result is presented in `performance-comparison-table-worst`.

## 3. Crash Consistency Evaluation on Virtual Machine

We perform crash consistency evaluation using Virtual Machine (VM), since it is more lightweight to manipulate PM (e.g., only wipe a small portion of PM space for a fresh start).

### 3.1 Quick Start

#### 3.1.1 Prerequisites

- **Kernel**: Linux kernel 5.1.0 modified by [SplitFS](https://github.com/rohankadekodi/SplitFS-5.1).

- **VM Setup**: We setup a VM environment using `libvirt`, with the following configurations:
    ```xml
        <domain type='kvm'>
            <name>deepin-pm</name>
            <maxMemory slots='3' unit='GiB'>64</maxMemory>
            <vcpu>16</vcpu>
            <cpu mode='host-passthrough' migratable='off'>
                <feature policy='disable' name='lahf_lm'/>
                <numa>
                    <cell id='0' cpus='0-15' memory='16' unit='GiB'/>
                </numa>
            </cpu>
            <features>
                <acpi/>
                <apic/>
            </features>
            <os>  
                <type arch='x86_64' machine='pc'>hvm</type>
            </os> 
            <devices> 
                <emulator>/usr/libexec/qemu-kvm</emulator>
                <disk type='file' device='disk'>
                <driver name='qemu' type='qcow2'/>
                <source file='/home/VirtualMachines/deepin.img'/>
                <target dev='vda' bus='virtio'/>
                </disk>
                <memory model='nvdimm' access='shared'>
                <source>
                    <path>/home/pm-backend.img</path>
                </source>
                <target>
                    <size unit='GiB'>16</size>
                    <node>0</node>
                </target>
                </memory>
                <memory model='nvdimm' access='shared'>
                <source>
                    <path>/home/pm-backend2.img</path>
                </source>
                <target>
                    <size unit='GiB'>16</size>
                    <node>0</node>
                </target>
                </memory>
            </devices>
            </domain>
    ```

    The `/home/VirtualMachines/deepin.img` is a simple Deepin Image downloaded from the official website. The `/home/pm-backend.img` and `/home/pm-backend2.img` are two PM images with 16\,GiB each, which are created using `dd` command. The VM is configured with 16 virtual CPUs and 64\,GiB of memory. The PM images are mounted as `/dev/pmem0` and `/dev/pmem1` in the VM.

- **Software**: For crash consistency evaluation, we only require installing ndctl to configure PM to `fsdax` mode. 
    ```bash
    #!/bin/bash
    # Configure PM to fsdax mode
    sudo apt install ndctl
    sudo ndctl create-namespace -f -e namespace0.0 --mode=fsdax
    sudo ndctl create-namespace -f -e namespace1.0 --mode=fsdax
    ```

#### 3.1.2 Usage of Repository

Now, the user should run the following command to organize repositories so that the scripts can work correctly:

```bash
# Download required artifacts
cd <Your directory>/
git clone https://github.com/WOFS-for-PM/tests.git tests
git clone https://github.com/WOFS-for-PM/WOFS.git hunter-kernel

# Install gen_cp
cd <Your directory>/tests/wofs-evaluation/TABLE-CC
make -j16
```

### 3.2 Crash Consistency Evaluation

Now, the user can run the following commands to evaluate the crash consistency:

```bash
cd tests/wofs-evaluation/TABLE-CC
bash crashmonkey-test.sh 1
# The output results are in performance-comparison-table
cat performance-comparison-table | grep "passed" | wc -l
```

Now, there should be 3000 tests either tagged as "passed" or "early-passed" in the output file `performance-comparison-table`.

## 4. MS-SSD Evaluation on an NVMe Server

### 4.1 Quick Start

#### 4.1.1 Prerequisites

- **OS and Kernel**: Tested under Ubuntu 22.04 LTS with Linux kernel 6.6.32 and Linux kernel 5.4.0.

- **Hardware**: At least one NVMe SSD equipped (>4\,GiB)

- **Software**: Running the following instructions to obtain the required software:
    - `apt install fio`
	- `apt install xfsprog`
	- `apt install f2fs-tools`
	- `apt install libboost-all-dev`

#### 4.1.2 Usage of Repository

Now, the user should run the following command to organize repositories so that the scripts can work correctly:

```bash
cd <Your directory>/
git clone https://github.com/WOFS-for-PM/tests.git tests
git clone https://github.com/WOFS-for-PM/WOFS-MS-SSD.git killer-nvme
```

#### 4.1.3 One-click run

We provide a one-click script `run_all.sh` in the root directory of `tests/wofs-ssd-evaluation`, running the following commands will automatically run all the experiments.

```bash
cd tests/wofs-ssd-evaluation/
bash run_all.sh 1
```

### 4.2 Step-by-Step Reproducing

We only evaluate **Figure 16: Performance comparison in MS-SSD** atop the MS-SSD server. The corresponding script is presented in `tests/wofs-ssd-evaluation/FIG-IO/test.sh`. The results are presented in `performance-comparison-table`. The user can use `plot.ipynb` to plot the figure: `FIG-IO-NVMe.pdf`.


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
    