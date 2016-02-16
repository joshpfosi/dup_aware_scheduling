# Duplicate Aware Scheduling

The goal of this project is to quantitatively measure the effects of duplicate
aware scheduling on a real distributed application. For more details, refer to
the report under `report/report.pdf`.

This repository contains a plethora of bash scripts which compose to run
experiments, tweaking various parameters of YCSB and memcached. At a high level,
a configurable number of clients and servers are set up via `ssh` on
appropriately named hosts managed by (Emulab)[https://www.emulab.net/] and
described by the `ns-2` script `emulab.tcl`. A brief explanation of each
directory and its contents follows:

## Cloning

This repository relies on modified versions of YCSB and memcached which it
stores as submodules to distinct clones also owned by joshpfosi. When cloning
this repository be sure to do one of the following:

```shell
git clone --recursive https://github.com/joshpfosi/dup_aware_scheduling.git
```

OR after cloning, execute:

```shell
git submodule init
git submodule update
```

## build

The `build` directory is comprised of two kinds of scripts `build-*` and
`setup-*`. The former are ran locally and run the corresponding `setup-*` script
on the relevant client or server hosted by Emulab. After swapping in the
experiment on Emulab, running 

```shell
build/build-emulab
```

will execute all other `build-*` scripts in the appropriate order. The scripts
run on remote hosts in parallel using subshells. Refer to individual scripts for
usage, parameters, and primary function. They are mostly self-documenting.

Additionally, the build directory contains copies of the libraries required to
run the experiments: `libevent`, `memcached` and `YCSB`. You may notice that
YCSB is copied into two directories. `YCSB_unaware` is, as its name implies, a
vanilla clone of YCSB and so therefore does not send duplicate requests.
`YCSB_aware`, on the other hand, will send duplicate requests.

## bin

This directory contains a handful of scripts which at one point or another were
useful for collecting or aggregating data. The ones of most general utility are:

- `experiment` - Runs an experiment with a variety of configuration options
- `full-experiment` - Runs a given configuration (see `experiment`) with both
duplicate unaware and aware scheduling
- `run-client` - Runs a YCSB client on remote hosts
- `run-server` - Runs a memcached server on remote hosts
- `kill-experiments` - Kills any currently running experiments on Emulab clients
or servers

## Running an Experiment

The simplest procedure to run an experiment after swapping in on Emulab is:

```shell
./build/build-emulab 24 8 # 24 clients and 8 servers
./bin/full-experiment workload1 4 output 1000 10 24 8 1000

# This spins up 8 memcached instances each with 4 threads, 24 YCSB instances each
# with 10 threads, generates a workload defined by `workload1` using a record size
# of 1 KB, and consisting of 1000 operations, and outputs all debug and
# experimental output to `output/*`
```

## Comp 112 Final Project Notes

### Building and Installation of libevent

     $ ./configure --disable-openssl # El Capitan does not support this easily
     $ make
     $ make verify   # (optional)
     $ sudo make install

### memcached

#### Processing Flow

1) Sets up an array of worker threads
2) Each thread runs `event_base_loop` which is fine-grained `libevent` API to
notify thread of incoming events
3) Each thread maintains a queue of TCP connections (`new_conn_queue`)
  * pops off and initializes as new connections come in
  * see `thread.c:setup_thread`: Thread is initialized to listen for new
    connections
    (`event_init`) with a persistent (meaning it listens forever, opposed
        to listening for 1 event then dying), read-triggered (event handler
          called if `fd` is readable) event. Action on this event calls
    `thread_libevent_process` which registers the new connection.
  * NOTE: If set up for UDP, this queue raises an exception
4) Each new connection (appears) to be initialized via `memcached.c:conn_new`
which sets up the libevent handler `event_handler` w/ flags set by the thread
  * `event_handler` calls `drive_machine` which handles all kinds of events
    (i.e. switches on `c->state`)

#### Miscellaneous

  * 4 worker threads by default for TCP connections
  * memcached uses an old version of Libevent (entirely deprecated methods -- should be okay)
  * memcached allocates a total (by default) of 1024 possible connections
  * Main thread uses `dispatch_conn_new` to select the next thread (`last_thread
        + 1 % num_threads` which is global var) and round-robins incoming
  connections to each thread
    * it allocates a "new_connection_queue item" and populates it with the `fd`,
      `event_flags` and other data before pushing it onto the connection queue
      of the chosen thread
  * Each new thread grabs one of these connections in `thread_libevent_process`
   by checking for the flag 'c' char on their input fd and then popping from
   their new_connection queue

### Duplicate Aware Scheduling

#### Implementation Plan

  * Modify memcached to use priority `event_base` i.e. * event_base_priority_init(&base, 2);
    * priority 0 => PRIMARY
    * priority 1 => DUP
    * NOTE: May need to use `event_priority_init()` as memcached uses an older libevent version
  * We can set up events to have a given priority
  * Libevent priority semantics are precisely what we need i.e. (this
      reference)[http://www.wangafu.net/~nickm/libevent-book/Ref4_event.html]:
  > When multiple events of multiple priorities become active, the low-priority
  > events are not run. Instead, Libevent runs the high priority events, then
  > checks for events again. Only when no high-priority events are active are the
  > low-priority events run.
  * As long as we can have separate events (i.e. separate file descriptors with
        flags `EV_READ | EV_PERSIST`) we are all set
  * This implies that memcached must establish separate TCP connections for
    primary and duplicate requests (in order to have separate sockets)

-------------------------------------------------------------------------------

Processing Flow (Simplified)

1) Start `memcached`
2) Designate dispatcher thread
3) Create 4 worker threads (`setup_thread` and `create_worker`)
  * dispatcher thread listens on port for new connections
  * sets up a Libevent base in each worker thread which listens on dispatcher
    pipe for new connections sent by dispatcher
4) Client A connects
  * dispatcher thread delegates new connection in round-robin fashion to next
    thread which adds a new event to listen on that socket for incoming requests
  * dispatcher thread instantiates a new connection queue item and populates it
    with connection information which the thread then pops off

Each thread logically manages a pipe file descriptor for new connections and one
or more sockets for active connections. New connections are handled via
`libevent_thread_process => conn_new` and requests are handled via
`event_handler => drive_machine => <state transitions>`.

Leveraging the round-robin implementation of Memcached connection allocation,
our duplicate-aware client can maintain 4*2*n connections for a given `n`
Memcached instances. This first 4 such connections will correspond to file
descriptors in Memcached with priority 0, and therefore will be used for primary
requests to each of the four threads. The next four (via hardcoding) will
correspond to file descriptors in Memcached with priority 1, and therefore will
be used for duplicate requests.

The remaining questions are to determine how our client will distribute the key
space over multiple Memcached instances and what workload will effectively
demonstrate the benefit of duplicate requests.

### Running memcached:

```
./memcached -vv -p 8888
```

### Running YCSB:

```
./bin/ycsb run memcached -P workloads/workloada
```

NOTE: if you receive an error such as:

memcached: error while loading shared libraries: libevent-2.1.so.5: cannot
open shared object file: No such file or directory

This can be fixed with a symlink:

sudo ln -s /usr/local/lib/libevent-2.1.so.5 /usr/lib/libevent-2.1.so.5

Source:
http://www.nigeldunn.com/2011/12/11/libevent-2-0-so-5-cannot-open-shared-object-file-no-such-file-or-directory/
