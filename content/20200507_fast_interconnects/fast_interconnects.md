Title: Pump Up the Volume: Processing Large Data on GPUs with Fast Interconnects
Date: 2020-05-07
Modified: 2021-06-27
Category: Publications
Slug: pump-up-the-volume
Author: Clemens Lutz
Summary: A brief teaser of the paper
Lang: en

Recently, multiple GPU vendors have released or announced GPUs with
interconnects that provide unprecedented connectivity to the CPU and
main-memory.  NVLink 2.0 by Nvidia [[2]](#2), Infinity Fabric by AMD [[3]](#3),
and Compute Express Link by Intel [[4]](#4) [[5]](#5) are a new class of *fast
GPU interconnects*.  These promise bandwidth up to 150 GB/s, and offer a new
solution to an age-old problem described in database literature called the
*data transfer bottleneck*.

In our recent publication that was accepted at the ACM SIGMOD conference
[[1]](#1), we investigate the benefits and challenges of fast interconnects for
processing data-intensive applications on GPUs.  In this post, we cover what
fast interconnects are capable of today, and why they might change the game for
GPU-enabled data processing.

#### The current state of GPU-enabled data processing

Modern accelerators including GPUs, FPGAs, and ASICs provide high performance
for scientific and business applications.  These accelerators are designed to
    maximize performance for a particular type of computation. GPUs, for
    example, are specialized processors for massive data parallelism. Recent
    GPUs are therefore capable of providing up to 14 TFLOPS of computation and
    1 TB/s of memory bandwidth.

Today, accelerators are in wide-spread use all around us.  29% of Top500 HPC
clusters feature accelerators [[6]](#6), and GPUs have become the go-to
accelerators for deep learning, with dedicated tensor processing units on the
rise [[7]](#7).  In contrast, GPU-enabled databases and dataflow frameworks are
only a small, $200 million part [[8]](#8) of the $46 billion databases market
[[9]](#9).  In fact, many frameworks, including but not limited to Apache Flink
[[10]](#10), currently do not natively support GPU
acceleration at all.

#### The data transfer bottleneck

The reason for the low rate of adoption is that discrete GPUs inherently run
into the *data transfer bottleneck*.  The transfer bottleneck means that the
key limiting factor for performance is the interconnect between the CPU and the
GPU.

Nowadays, applications access data sets with volumes of many terrabytes.  To
achieve high performance, relational and data-flow applications require fast
access to these data.  As the data do not fit into the GPU's on-board memory,
modern databases store the bulk of data in main-memory.  However, due to the
transfer bottleneck, GPUs cannot access data in main-memory fast enough to
achieve their full performance potential.  The result is that CPUs outperform
GPUs by a wide margin, and marginalize the utility of using GPUs.

To make GPU acceleration worthwhile for large-scale data processing, it is
important that we resolve the data transfer bottleneck.

#### Fast from main-memory onto the GPU

The most effective solution to solve the transfer bottleneck is to increase the
transfer bandwidth.  More bandwidth benefits all applications, even those that
compress data to reduce their transfer volume.  True to their name, our
measurements show that fast interconnects deliver bandwidth in spades.

<figure>
<img src="{attach}bandwidth_comparison.svg" class="img-responsive img-thumbnail
center-block" alt="Fast interconnects provide GPUs with bandwidth on the same
level as the CPU's main-memory" />

<figcaption class="text-center">
<b>Figure 1:</b> Fast interconnects provide GPUs with bandwidth on the same
level as the CPU's main-memory.
</figcaption>
</figure>

In Figure 1, we show that NVLink 2.0 enables GPUs to access main-memory with
similar performance as the CPU can.  NVLink 2.0 also provides 6 times higher
throughput than PCI-e 3.0, which is currently the most commonly-used GPU
interconnect.  Note that in this plot, we measure the peak performance of a
perfecly symmetric bi-directional transfer (i.e., memory copy).  Usually,
applications have asymmetric read/write characteristics and will therefore not
achieve this peak.

<figure>
<img src="{attach}bandwidth.svg" class="img-responsive img-thumbnail
center-block" alt="NVLink 2.0 is faster than NUMA interconnects, but slower
than GPU memory" />

<figcaption class="text-center">
<b>Figure 2:</b> NVLink 2.0 is faster than NUMA interconnects, but slower than
GPU memory.
</figcaption>
</figure>

However, even one-way transfers deliver impressive bandwidth.  In Figure 2, we
compare NVLink 2.0 to recent memory technologies and NUMA interconnects.  Fast
interconnects are within a factor of two of modern CPUs when considering memory
reads and writes.  In fact, they outperform the NUMA interconnects of modern
CPUs.  In our in-depth investigation, we found that NUMA interconnects have
significantly lower latency than GPU interconnects, which might explain the
bandwidth difference.  However, all of these technologies pale in relation to
the high-bandwidth memory bolted onto high-end GPUs.  "Fast" is, after all, a
relative term.  In the end, what matters is the performance impact on
applications.

#### Changing the game for GPU-enabled data processing

Fast interconnects enable us to pump up the data volume, with high performance.
We show the performance impact of fast interconnects with two examples: a hash
join and a TPC-H query [[11]](#11).

On paper, hash joins match GPUs perfectly.  Hash joins are very challenging to
implement efficiently on CPUs, because they access memory in highly irregular
patterns.  In contrast, GPUs excel at random memory access patterns, due to
their latency-hiding hardware architecture.  In practice however, the
unparalleled join throughput of GPUs is held back by the transfer bottleneck.
In other words, they do not scale to very large data sets, because these do fit
into the fast on-board memory of GPUs.

The selection (i.e., filter) in TPC-H query 6 is the polar opposite of a hash
join in regard to performance characteristics.  Selections are typically bound
by the instruction latency of if-else branch mispredictions instead of memory
latency.  A common optimization is to replace branches with predicated
instructions.  In this case, the selection becomes bandwidth-bound.  GPUs are
ill-suited for both implementations: GPUs are not optimized for branches, and,
if predicated, interconnect bandwidth becomes the limiting factor.  In our
    test, we measure both cases.

<figure>
<img src="{attach}probe_throughput.svg" class="img-responsive img-thumbnail
center-block" alt="Relational joins on GPUs scale to large data with high
throughput" />

<figcaption class="text-center">
<b>Figure 3:</b> Relational joins on GPUs scale to large data with high
throughput.
</figcaption>
</figure>

In Figure 3, we run a hash join on 2 &#x2a1d; 122 GiB of data, which is at the
limit of our main-memory capacity.  This is 7.5 times more data than fits into
the GPU's dedicated memory.  In the benchmark, NVLink 2.0 is 6 times faster
than PCI-e 3.0, and 7.3 times faster than an optimized CPU implementation.

<figure>
<img src="{attach}tpch_q6.svg" class="img-responsive img-thumbnail
center-block" alt="Relational selections on GPUs are catching up to CPUs" />

<figcaption class="text-center">
<b>Figure 4:</b> Relational selections on GPUs are catching up to CPUs.
</figcaption>
</figure>

In Figure 4, we execute the selection with TPC-H scale factor 1000, which is 90
GiB of data.  As expected, the CPU is 1.7 times faster than the GPU, and the
CPU loves the predicated implementation.  What is interesting is that, on the
GPU, branching is faster than predication.  Why?  The answer lies in the data
volume: predication loads all table columns, whereas branching loads only the
data that is necessary to compute the result.  In this query, branching loads
only half of the table.  Even with a fast interconnect, reducing transfer
volume provides a sizeable performance advantage.

#### Conclusions

Thanks to fast interconnects, GPU-enabled databases and data processing
frameworks can now efficiently process large, out-of-core data sets.

In this post, we are only scratching the surface of the new opportunities for
GPU data processing that fast interconnects enable.  Fast Interconnects also
feature cache coherence, a system-wide address space, and lower latency than
previous GPU interconnects.

To find out more, we invite you to read our full investigation!

<small>(This post was originally published on the H2020 E2Data Project blog. I
republished it on my personal website after the original was taken
offline.)</small>

#### References

<a id="1"> \[1\] [Lutz et al., "Pump Up the Volume: Processing Large Data on GPUs with Fast Interconnects", in SIGMOD 2020](https://www.clemenslutz.com/pdfs/sigmod_2020_processing_large_data_on_gpus_with_fast_interconnects.pdf)

<a id="2"> \[2\] [Nvidia, "NVLink and NVSwitch: The Building Blocks of Advanced Multi-GPU Communication"](https://www.nvidia.com/en-us/data-center/nvlink/)

<a id="3"> \[3\] [AMD, "AMD EPYC CPUs, AMD Radeon Instinct GPUs and ROCm Open Source Software to Power World’s Fastest Supercomputer at Oak Ridge National Laboratory"](https://www.amd.com/en/press-releases/2019-05-07-amd-epyc-cpus-radeon-instinct-gpus-and-rocm-open-source-software-to-power)

<a id="4"> \[4\] [Intel, "Intel Unveils New GPU Architecture with High-Performance Computing and AI Acceleration, and oneAPI Software Stack with Unified and Scalable Abstraction for Heterogeneous Architectures"](https://newsroom.intel.com/news-releases/intel-unveils-new-gpu-architecture-optimized-for-hpc-ai-oneapi/)

<a id="5"> \[5\] [Intel, "A Milestone in Moving Data Compute Express Link Technology will Improve Performance and Remove Bottlenecks in Computation-Intensive Workloads"](https://newsroom.intel.com/editorials/milestone-moving-data)

<a id="6"> \[6\] [Top500.org, "Highlights of the 54th edition of the TOP500"](https://www.top500.org/lists/top500/2019/11/highs/)

<a id="7"> \[7\] [Deloitte, "Hitting the accelerator: the next generation of machine-learning chips"](https://www2.deloitte.com/content/dam/Deloitte/global/Images/infographics/technologymediatelecommunications/gx-deloitte-tmt-2018-nextgen-machine-learning-report.pdf)

<a id="8"> \[8\] [MarketsAndMarkets, "GPU Database Market by Application (GRC, Threat Intelligence, CEM, Fraud Detection and Prevention, SCM), Tools (GPU-accelerated Databases and GPU-accelerated Analytics), Deployment Model, Vertical, and Region - Global Forecast to 2023"](https://www.marketsandmarkets.com/Market-Reports/gpu-database-market-259046335.html)

<a id="9"> \[9\] [Gartner, "On-Premises DBMS Revenue Continues to Decrease as DBMS Market Shifts to the Cloud"](https://www.gartner.com/en/newsroom/press-releases/2019-07-01-gartner-says-the-future-of-the-database-market-is-the)

<a id="10"> \[10\] [Apache Flink](https://flink.apache.org/)

<a id="11"> \[11\] [TPC-H Benchmark](http://www.tpc.org/tpch/)
