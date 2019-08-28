Table of Contents
=================

   * [Description](#description)
   * [Public Domain Annotations](#public-domain-annotations)
   * [Citations and Repositories](#citations-and-repositories)
   * [Notation](#notation)
   * [Installation](#installation)
      * [Singularity for Linux, Mac, and Windows](#singularity-for-linux-mac-and-windows)
      * [Docker for Windows, Mac, and Linux](#docker-for-windows-mac-and-linux)
      * [System Configuration](#system-configuration)
      * [Scheduling Jobs](#scheduling-jobs)
         * [Locally](#locally)
         * [Another Workstation](#another-workstation)
         * [An On-Premise Cluster](#an-on-premise-cluster)
   * [Tutorial](#tutorial)
      * [Detecting Sounds](#detecting-sounds)
      * [Visualizing Clusters](#visualizing-clusters)
      * [Manually Annotating](#manually-annotating)
      * [Training a Classifier](#training-a-classifier)
      * [Quantifying Accuracy](#quantifying-accuracy)
      * [Making Predictions](#making-predictions)
      * [Correcting False Alarms](#correcting-false-alarms)
      * [Correcting Misses](#correcting-misses)
      * [Minimizing Annotation Effort](#minimizing-annotation-effort)
      * [Double Checking Annotations](#double-checking-annotations)
      * [Measuring Generalization](#measuring-generalization)
      * [Searching Hyperparameters](#searching-hyperparameters)
      * [Examining Errors](#examining-errors)
      * [Testing Densely](#testing-densely)
      * [Discovering Novel Sounds](#discovering-novel-sounds)
      * [Scripting Automation](#scripting-automation)
   * [Troubleshooting](#troubleshooting)
   * [Frequently Asked Questions](#frequently-asked-questions)
   * [Reporting Problems](#reporting-problems)
   * [Development](#development)
      * [Singularity](#singularity)
      * [Docker](#docker)

# Description #

You have an audio recording, and you want to know where certain classes of
sounds are.  DeepSong is trained to recognize such words by manually giving
it a few examples.  It will then automatically calculate the probability,
over time, of when those words occur in all of your recordings.

Applications suitable for DeepSong include quantifying the rate or pattern
of words emitted by a particular species, distinguishing a recording of one
species from another, and discerning whether individuals of the same species
produce different song.

Underneath the hood is a deep convolutional neural network.  The input is the
raw audio stream, and the output is a set of mutually-exclusive probability
waveforms corresponding to each word of interest.

Training begins by first thresholding one of your recordings in the
time- and frequency-domains to find sounds that exceed the ambient noise.
These sounds are then clustered into similar categories for you to manually
annotate with however many word labels naturally occur.  A classifier is
then trained on this corpus of ground truth, and a new recording is analyzed
by it.  The words it automatically finds are then clustered as before, but
this time are displayed with predicted labels.  You manually correct the
mistakes, both re-labeling words that it got wrong, as well as labeling
words it missed.  These new annotations are added to the ground truth,
and the process of retraining the classifier and analyzing and correcting
new recordings is repeated until the desired accuracy is reached.


# Public Domain Annotations #

DeepSong is open source and free for you to use.  However, DeepSong is not
a static piece of software.  It’s performance is improved with additional
high-quality annotations.

Therefore, when you publish results based on DeepSong, we request that you make
all of your primary data and annotations freely available in a recognized data
repository, such as [figshare](http://figshare.com),
[Dryad](http://datadryad.org), or [Zenodo](http://zenodo.org).  Many journals
already require deposition of raw data, but we strongly encourage you to also
provide your manual annotations.  These manual annotations will serve to
improve the performance of DeepSong over time, helping both your own work and
that of everyone else.

Please let us know where you have deposited your raw
data and annotations by posting an issue to the [DeepSong
repository](https://github.com/JaneliaSciComp/DeepSong).  We will endeavor to
maintain a database of these recordings and annotations and will periodically
re-train DeepSong with the new data.

In addition, consider donating your recordings to library or museum, like the
Cornell Lab of Ornithology's [Macauley Library](www.macaulaylibrary.org) or the
Museo de Ciencias Naturales de Madrid's [Fonoteca Zoológica](www.fonozoo.com).


# Citations and Repositories

BJ Arthur, Y Ding, M Sosale, F Khalif, S Turaga, DL Stern (in prep)  
DeepSong: A machine-learning classifier to segment and discover animal acoustic communication signals   
[BioRxiv]()  
[datadryad]()


# Notation #

Throughout this document `Buttons` and `variables` in the DeepSong graphical
user interface (GUI) as well as `code` are highlighted like so.  Files and
paths are enclosed in double quotes ("...").  The dollar sign ($) in code
snippets signifies your computer terminal's command line.  Square brackets
([...]) in code indicate optional components, and angle brackets (<...>)
represent sections which you much customize.


# Installation #

DeepSong can be run on all three major platforms.  The installation procedure
is different on each due to various support of the technologies used.  We
recommend using Singularity on Linux and Apple Macintosh, and Conda on
Microsoft Windows.  Training your own classifier is fastest with an Nvidia
graphics processing unit (GPU).

TensorFlow, the machine learning framework from Google that DeepSong uses,
supports Ubuntu, Mac and Windows.  The catch is that TensorFlow (and Nvidia)
currently doesn't support GPUs on Macs.  So while using a pre-trained
classifier would be fine on a Mac, because inference is just as fast on the
CPU, training your own would be ~10x slower.

Docker, a popular container framework which provides an easy way to deploy
software across platforms, supports Linux, Mac and Windows, but only supports
GPUs on Linux.  Moreover, on Mac and Windows it runs within a heavy-weight
virtual machine, and on all platforms it requires administrator privileges to
both install and run.

Singularity is an alternative to Docker that does not require root access.  For
this reason it is required in certain high-performance computing (HPC)
environments.  Currently it only natively supports Linux, and uses a
light-weight virtual machine on Macs; you can run it on Windows within a
virtual environment, like Docker does, but would have to set that up yourself.
As with Docker, GPUs are only accessible on Linux.

To use DeepSong with a GPU on Windows one must install it manually, without
the convenience of a container.  We're looking for volunteers to write a
Conda recipe to make this easy.

## Singularity for Linux, Mac, and Windows ##

Platform-specific installation instructions can be found at
[Sylabs](https://www.sylabs.io).  DeepSong has been tested with version 3.4.

You'll also need to install the CUDA and CUDNN drivers from nvidia.com.
The latter requires you to register for an account.  DeepSong was tested and
built with version 10.1.

Next download the DeepSong image from the cloud.  You can either go to
[DeepSong's cloud.sylabs.io
page](https://cloud.sylabs.io/library/_container/5ccca72a800ca26aa6ccf008) and
click the Download button, or equivalently use the command line (for which you
might need an access token):

    $ singularity pull library://bjarthur/default/deepsong:latest
    INFO:    Container is signed
    Data integrity checked, authentic and signed by:
      ben arthur (deepsong) <arthurb@hhmi.org>, Fingerprint XXABCXXX

    $ ls -lht | head -n 2
    total 16G
    -rwxr-xr-x  1 arthurb scicompsoft 1.5G Sep  2 08:16 deepsong_latest.sif*

Finally, put these definitions in your .bashrc file:

    export DEEPSONG_BIN='singularity exec -B `pwd` --nv <path-to-deepsong_latest.sif>'
    alias deepsong="$DEEPSONG_BIN gui.sh `pwd`/configuration.sh 5006"

Note that the current directory is mounted in the `export` above with the `-B`
flag.  If you want to access any other directories, you'll have to add additional
flags (e.g. `-B /groups:/groups`).

## Docker for Windows, Mac, and Linux ##

Platform-specific installation instructions can be found at
[Docker](http://www.docker.com).  Once you have it installed, download the
[DeepSong image from
cloud.docker.com](https://cloud.docker.com/u/bjarthur/repository/docker/bjarthur/deepsong):

    $ docker pull bjarthur/deepsong
    Using default tag: latest
    latest: Pulling from bjarthur/deepsong
    Digest: sha256:466674507a10ae118219d83f8d0a3217ed31e4763209da96dddb03994cc26420
    Status: Image is up to date for bjarthur/deepsong:latest

    $ docker image ls
    REPOSITORY        TAG    IMAGE ID     CREATED      SIZE
    bjarthur/deepsong latest b63784a710bb 20 hours ago 2.27GB

Finally, put these definitions in your .bashrc file:

    export DEEPSONG_BIN='docker run -w `pwd` -v `pwd`:`pwd` --env DEEPSONG_BIN \
        -h=`hostname` -p 5006:5006 bjarthur/deepsong'
    alias deepsong="$DEEPSONG_BIN gui.sh `pwd`/configuration.sh 5006"

Note that the current directory is mounted in the `export` above with the
`-v` flag.  If you want to access any other directories, you'll have to
add additional flags (e.g. `-v /C:/C`).

Should docker ever hang, or run for an interminably long time, and you
want to kill it, you'll need to open another terminal window and issue the
`stop` command:

    $ docker ps
    CONTAINER ID IMAGE             COMMAND               CREATED       STATUS ...
    6a26ad9d005e bjarthur/deepsong "detect.sh /src/p..." 3 seconds ago Up 2 seconds ...

    $ docker stop 6a26ad9d005e

If you have to do this often, consider putting this short cut in your
.bashrc file:

    $ alias dockerkill='docker stop $(docker ps --latest --format "{{.ID}}")'

The virtual machine that docker runs within is configured by default with only
2 GB of memory.  You will probably want to increase this limit.

## System Configuration ##

DeepSong is capable of training a classifier and making predictions on
recordings either locally on the host computer or remotely on a workstation, a
cluster, or the cloud.  You specify how you want this to work by editing
"configuration.sh".

Copy an exemplar configuration file out of the container and into your home
directory:

    $ $DEEPSONG_BIN cp /opt/deepsong/configuration.sh .

Inside you'll find many shell variables and functions which control where
DeepSong does its work:

    $ grep _where= configuration.sh 
    default_where=local
    detect_where=$default_where
    misses_where=$default_where
    train_where=$default_where
    generalize_where=$default_where
    xvalidate_where=$default_where
    hidden_where=$default_where
    cluster_where=$default_where
    accuracy_where=$default_where
    freeze_where=$default_where
    classify_where=$default_where
    ethogram_where=$default_where
    compare_where=$default_where
    dense_where=$default_where

    $  grep -A21 GENERIC configuration.sh 
    # GENERIC HOOK
    generic_it () {
        cmd=$1
        logfile=$2
        where=$3
        deepsongbin=$4
        localargs=$5
        localdeps=$6
        clusterflags=$7
        if [ "$where" == "local" ] ; then
            hetero submit "{ export CUDA_VISIBLE_DEVICES=\$QUEUE1; $cmd; } &> $logfile" \
                          $localargs "$localdeps" >${logfile}.job
        elif [ "$where" == "server" ] ; then
            ssh c03u14 "$deepsongbin bash -c \"$cmd\" &> $logfile"
        elif [ "$where" == "cluster" ] ; then
            ssh login1 bsub \
                       -P stern \
                       -J ${logfile}.job \
                       "$clusterflags" \
                       -oo $logfile <<<"$deepsongbin bash -c \"$cmd\""
        fi
    }


    $  grep -A7 train_gpu configuration.sh 
    train_gpu=1
    train_where=$default_where
    train_it () {
        if [ "$train_gpu" -eq "1" ] ; then
            generic_it "$1" "$2" "$train_where" \
                       "2 1 1" "" "-n 2 -W 1440 -gpu \"num=1\" -q gpu_rtx"
        else
            generic_it "$1" "$2" "$train_where" \
                       "12 0 1" "" "-n 24 -W 1440"
        fi
    }

Each operation (e.g. detect, train, classify, generalize, etc.) is dispatched
by an eponymous function ending in `\_it`.  In the example above, `train_it` is
called when you train a model.  This function hook references a variable called
`train_where` that is used by `generic_it` to switch between using the "local"
host computer, a remote "server", or an on-premise "cluster".

DeepSong comes with each `_where` variable set to "local" via the
`default_where` variable at the top of the configuration file.  You can change
which computer is used either globally through this variable, or by configuring
the operation specific ones later in the file.

## Scheduling Jobs ##

Irrespective of where you want to perform your compute, the aforementioned hook
functions need to be tailored to your specific resources.  How your compute
environment needs to be set up also depend on this choice.

### Locally ###

When running locally DeepSong uses a job scheduler to manage the resources
required by different commands.  So that multiple tasks can be performed
simultaneously without overwhelming your workstation, you must list its
specifications in "configuration.sh", as well as how much of those resources
each action maximally requires.

    $ grep -A4 \'local configuration.sh 
    # specs of the 'local' computer
    local_ncpu_cores=12
    local_ngpu_cards=1
    local_ngigabytes_memory=32

The fifth argument input to the `generic_it` function, called `localargs`,
controls how many resources are allocated to a job when run locally.
Specifically, its a string of three integers, which specify the number of CPU
cores, number of GPU cards, and number of gigabytes of memory needed
respectively.

Training a model in the [Tutorial](#tutorial) below, for example, typically
needs two CPU cores, one GPU, and a megabyte of memory, and hence the string "2
1 1" in the fifth position to the first reference to `generic_it` inside the
`train_it` example above.  Alternatively, if you don't have a GPU, you could
use an entire CPU with "12 0 1" as in the second reference.

To assess how much resources your particular workflow requires, use the `top`
and `nvidia-smi` commands to monitor jobs while they are running.

    $ $DEEPSONG_BIN top -b | head -10
    top - 09:36:18 up 25 days,  1:18,  0 users,  load average: 11.40, 12.46, 12.36
    Tasks: 252 total,   1 running, 247 sleeping,   0 stopped,   4 zombie
    %Cpu(s):  0.7 us,  0.9 sy, 87.9 ni, 10.4 id,  0.1 wa,  0.0 hi,  0.0 si,  0.0 st
    KiB Mem : 32702004 total,  3726752 free,  2770128 used, 26205124 buff/cache
    KiB Swap: 16449532 total, 16174964 free,   274568 used. 29211496 avail Mem 

      PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
    21124 arthurb   20   0 55.520g 2.142g 320792 S 131.2  6.9   1:38.17 python3
        1 root      20   0  191628   3004   1520 S   0.0  0.0   1:20.57 systemd
        2 root      20   0       0      0      0 S   0.0  0.0   0:00.33 kthreadd

The output above shows that a `python3` command, which is how a training session
appears, is currently using 131.2% of a CPU core (e.g. 1.3 cores), and 6.9% of
the 32702004 KiB of total system memory (so about 2.15 GiB).  To monitor how
these numbers change throughout the course of an entire job, omit the `-b` flag
and do *not* pipe the output into `head` (so just use `$DEEPSONG_BIN top`) and
the screen will be refreshed every few seconds.

The output below shows how to similarly monitor the GPU card.  The same
`python3` command as above is currently using 4946 MiB of GPU memory and 67% of
the GPU cores.  Use the `watch` command to receive repeated updates (i.e.
`$DEEPSONG_BIN watch nvidia-smi`).

    $ $DEEPSONG_BIN nvidia-smi
    Fri Jan 31 09:35:13 2020       
    +-----------------------------------------------------------------------------+
    | NVIDIA-SMI 418.39       Driver Version: 418.39       CUDA Version: 10.1     |
    |-------------------------------+----------------------+----------------------+
    | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
    | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
    |===============================+======================+======================|
    |   0  GeForce GTX 980 Ti  Off  | 00000000:03:00.0 Off |                  N/A |
    | 22%   65C    P2   150W / 250W |   4957MiB /  6083MiB |     67%      Default |
    +-------------------------------+----------------------+----------------------+
                                                                                   
    +-----------------------------------------------------------------------------+
    | Processes:                                                       GPU Memory |
    |  GPU       PID   Type   Process name                             Usage      |
    |=============================================================================|
    |    0     21124      C   /usr/bin/python3                            4946MiB |
    +-----------------------------------------------------------------------------+

### Another Workstation ###

Using a lab or departmental server, or perhaps a colleague's workstation
remotely, is easiest if you run DeepSong on it directly and then view the GUI
in your own personal workstation's internet browser.  To do this, simply `ssh`
into the server and install DeepSong as described above.

Alternatively, you can run the GUI code (in addition to viewing its output) on
your own personal workstation and batch compute jobs to the remote server.
This is easiest if there is a shared file system between the two computers.
The advantage here is that less compute intensive jobs (e.g. freeze, accuracy)
can be run on your workstation.  In this case:

* Store all DeepSong related files on the share, including the container image,
"configuration.sh", and all of your data.

* Make the remote and local file paths match by creating a symbolic link.
For example, if on a Mac you use SMB to mount as "/Volumes/sternlab"
an NSF drive whose path is "/groups/stern/sternlab", then add `-[v|B]
/groups/stern/sternlab` to `DEEPSONG_BIN` and `mkdir -p /groups/stern &&
ln -s /Volumes/sternlab/ /groups/stern/sternlab`.  With Docker you'll
additionally need to open the preferences panel and configure file sharing
to bind "/groups".

* Set the `DEEPSONG` environment variable plus the `deepsong` alias on both
your workstation and the server to point to this same image.

* You might need an RSA key pair.  If so, you'll need to add `-[v|B]
~/.ssh:/ssh` to `DEEPSONG_BIN`.

* You might need to use ssh flags `-i /ssh/id_rsa -o "StrictHostKeyChecking
no"` in "configuration.sh".

If you do not have a shared file system, the DeepSong image and configuration file
must be separately installed on both computers, and you'll need to do all of
the compute jobs remotely.

Lastly, update "configuration.sh" with the specification of the server.  As
when doing compute locally, DeepSong uses a job scheduler on the server to
manage resources.

    $ grep -A5 \'server configuration.sh 
    # specs of the 'server' computer
    server_ipaddr=c03u14
    server_ncpu_cores=24
    server_ngpu_cards=4
    server_ngigabytes_memory=256

### An On-Premise Cluster ###

Submitting jobs to a cluster is similar to using a remote workstation, so read
the above section first.  You might want to even try batching to a another
workstation first, as it can be easier to debug problems than doing so on a
cluster.

You use your own workstation to view the GUI in a browser, and can either run
the GUI code locally or on the cluster.  With the former you have the option to
submit only a portion of the compute jobs to the cluster, whereas with the
latter they must all be performed by the cluster.  Running the GUI code on the
cluster also requires that the cluster be configured to permit hosting a web
page.  Moreover, if your cluster charges a use fee, you'll be charged even when
the GUI is sitting idle.

As before, it is easiest if there is a shared file system, and if so, all files
need to be on it, and the local and remote file paths must be the same or made
to be the same with links.  The environment variables and aliases must also be
the same.

You'll likely need an RSA key pair, possibly need special `ssh` flags, and
almost assuredly need to change the `bsub` command and/or its flags.  The best
person to ask for help here is your system administrator.

The seventh argument input to `generic_it`, called `clusterflags`, controls how
many resources are allocated to a job when submitted to a cluster.  Its syntax
is highly specific to the type of scheduler your cluster uses.  DeepSong comes
with these arguments set to use the Load Sharing Facility (LSF) from IBM.  You
could easily change them and the corresponding call to `bsub` in `generic_it`
to support any cluster scheduler (e.g. SGE, PBS, Slurm, etc.).


# Tutorial #

Let's walk through the steps needed to train a classifier completely from
scratch.

Recordings need to be monaural 16-bit little-endian PCM-encoded WAV files.
They should all be sampled at the same rate, which can be anything.  For this
tutorial we supply you with *Drosophila melanogaster* data sampled at 2500 Hz.

First, let's get some data bundled with DeepSong into your home directory.

    $ $DEEPSONG_BIN ls /opt/deepsong/data
    20161207T102314_ch1_p1.wav     PS_20130625111709_ch3_p2.wav
    20161207T102314_ch1_p2.wav     PS_20130625111709_ch3_p3.wav
    20161207T102314_ch1_p3.wav     my_frozen_graph_1k_0.pb     
    PS_20130625111709_ch3_p1.wav   vgg_labels.txt              

    $ mkdir -p groundtruth-data/round1

    $ $DEEPSONG_BIN cp /opt/deepsong/data/PS_20130625111709_ch3_p1.wav \
          ./groundtruth-data/round1

## Detecting Sounds ##

Now that we have some data, let's extract the timestamps of some sounds from
one of these as-of-yet unannotated audio recordings.

First, start DeepSong's GUI:

    $ deepsong

Then in your favorite internet browser navigate to `http://localhost:5006`.  If
you are running the DeepSong GUI on a remote computer, replace `localhost` with
that computer's hostname or IP address:

    $ hostname [-i]
    arthurb-ws2

On the left you'll see three empty panels (two large squares side by side and
one wide rectangle underneath) in which the sound recordings are displayed and
annotated.  In the middle are buttons and text boxes used to train the
classifier and make predictions with it.  On the right is this instruction
manual for easy reference.

Click on the `Label Sounds` button and then `Detect`.  All of the parameters
below that are *not* used will be greyed out and disabled.  If all of the
required parameters are filled in, the `DoIt!` button in the upper right will
in addition be enabled and turn red.

The first time you use DeepSong all of the parameters will need to be
specified.  In the File Dialog browser immediately below, navigate to the
"configuration.sh" file that you copied from the container and then click
on the `Parameters` button.  Notice that the large text box to the right of the
`File Dialog` browser now contains the text of this file.  Similarly, navigate
to the WAV file in the "round1/" directory and click on the `WAV,TF,CSV Files`
button.  Lastly you'll need to specify the six numeric parameters that control
the algorithm used to find sounds:  In the time domain, subtract the median,
take the absolute value, threshold by the median absolute deviation times `time
σ`, and morphologically close gaps shorter than `time smooth` milliseconds.
Separately, use multi-taper harmonic analysis ([Thomson, 1982;
IEEE](https://ieeexplore.ieee.org/document/1456701)) in the frequency domain to
create a spectrogram using a window of length `freq N` milliseconds (`freq N` /
1000 * tic_rate should be a power of two) and twice `freq NW` Slepian tapers,
multiply the default threshold of the F-test by a factor of `freq ρ`, and open
islands and close gaps shorter than `freq smooth`.  Sound events are considered
to be periods of time which pass either of these two criteria.

Once all the needed parameters are specified, click on the red `DoIt!` button to
start detecting sounds.  It will turn orange while the job is being
asynchronously dispatched, and then back to grey.  "detect
PS_20130625111709_ch3_p1.wav" will appear in the status bar.  It's font will
initially be grey to indicate that it is pending, then turn black when it is
running, and finally either blue if it successfully finished or red if it
failed.

The result is a file of comma-separated values with the start and stop times
(in tics) of sounds which exceeded a threshold in either the time or frequency
domain.

    $ head -3 groundtruth-data/round1/PS_20130625111709_ch3_p1-detected.csv
    PS_20130625111709_ch3_p1.wav,4501,4503,detected,time
    PS_20130625111709_ch3_p1.wav,4628,4631,detected,time
    PS_20130625111709_ch3_p1.wav,4807,4810,detected,time

    $ tail -3 groundtruth-data/round1/PS_20130625111709_ch3_p1-detected.csv
    PS_20130625111709_ch3_p1.wav,945824,946016,detected,frequency
    PS_20130625111709_ch3_p1.wav,947744,947936,detected,frequency
    PS_20130625111709_ch3_p1.wav,962720,962912,detected,frequency

## Visualizing Clusters ##

To cluster these detected sounds we're going to use the same method that we'll
later use to cluster the hidden state activations of a trained classifier.

Click on the `Train` button to create a randomly initialized network.  Before
clicking the `DoIt!` button though, change `# steps`, `validate period`, and
`validation %` to all be 0 and make `restore from` blank.  You'll also need to
use the `File Dialog` browser to choose directories in which to put the log
files and to find the ground-truth data.  The latter should point to a folder
two-levels up in the file hierarchy from the WAV and CSV files (i.e.
".../groundtruth-data" in this case).  Lastly you'll need to specify
"time,frequency" as the `wanted words` and "detected" as the `label types` to
match what is in the CSV file you just created above.  Now press `DoIt!`.
Output into the log file directory are "train.log", "train_1.log", and
"train_1/".  The former two files contain error transcripts should any problems
arise, and the latter folder contains checkpoint files prefixed with
"vgg.ckpt-" which save the weights of the neural network at regular intervals.

Use the `Activations` button to save the input to the neural network as well as
its hidden state activations and output logits by mock-classifying these
detected sounds with this untrained network.  You'll need to tell it which
model to use by selecting the last checkpoint file in the untrained
classifier's log files with the `File Dialog` browser
(".../groundtruth-data/train_1/vgg.ckpt-0" in this case).  The time and amount
of memory this takes depends directly on the number and dimensionality of
detected sounds.  To limit the problem to a manageable size one can use `max
samples` to randomly choose a subset of samples to cluster.  (The `time σ` and
`freq ρ` variables can also be used limit how many sound events were detected
in the first place.)  The `Activations` button also limits the relative proportion
of each `wanted word` to `equalize ratio`.  In the case of "detected" `label
types` you'll want to set this to a large number, as it does not matter if the
number of samples which pass the "time" threshold far exceeds the "frequency"
threshold, or vice versa.  Output are three files in the ground-truth directory
beginning with "hidden":  the two ending in ".log" report any errors, and
"hidden.npz" contains the actual data in binary format.

Now cluster the hidden state activations with the `Cluster` button.
Choose to do so using either UMAP ([McInnes, Healy, and Melville
(2018)](https://arxiv.org/abs/1802.03426)) or t-SNE ([van der Maaten and
Hinton (2008)](http://www.jmlr.org/papers/v9/vandermaaten08a.html)) or PCA.
Each are controlled by separate parameters, a description of which can be
found in the aforementioned articles.  Output are two or three files in the
ground-truth directory beginning with "cluster":  a ".log" file with errors
and a ".npz" file with binary data as before, plus a PDF file showing the
results of the principal components analysis (PCA) that precedes t-SNE.

Finally, click on the `Visualize` button to render the clusters in
two-dimensional space in the left-most panel.  You can choose to display
them with a scatter of semi-transparent circles, or a hexagonally-binned
density map, by clicking on the `hexs` or `dots` buttons, respectively.
Nominally there should be some structure to the clusters based on just
the waveforms alone.  This structure will become much more pronounced after
a model is trained with annotated data.

To browse through your recordings, click on one of the more dense areas and a
fuchsia circle will appear.  In the right panel are now displayed snippets of
detected waveforms which are nominally similar to one another.  They will each
be labeled "detected time" or "detected frequency" to indicate which threshold
criterion they passed and that they were detected (as opposed to annotated,
predicted, or missed; see below).  The color is the scale bar-- yellow is loud
and purple is quiet.  Clicking on a snippet will show it in greater temporal
context in the wide panel below.  Pan and zoom with the buttons labeled `<`,
`>`, `+`, `-`, and `0`.  The size of the fuchsia circle can be adjusted with
the `circle radius` variable, and the size of the hexagons with `hex size`.
The `Play` button can be used to listen to the sound, and if the `Video` button
is selected and a movie with the same root basename exists alongside the
corresponding WAV file, it will be displayed as well.

## Manually Annotating ##

To record a manual annotation, first pick a waveform snippet that contains an
unambiguous example of a particular word.  In addition to looking at the
waveform shape, you can also listen to it with the `Play` button.  Type the
word's name into one of the text boxes at the bottom left and hit return to
activate the corresponding counter to its left.  Hopefully the gray box in the
upper half of the wide context window nicely demarcates the temporal extent of
the word.  If so, all you have to do is to double click either the grey box
itself, or the corresponding snippet above, and it will be extended to the
bottom half and your chosen label will be applied.  If not, either double-click
or click-and-drag in the bottom half of the wide context window to create a
custom time span for a new annotation.  In all cases, annotations can be
deleted by double clicking any of the gray boxes.

For this tutorial, choose the words "mel-pulse", "mel-sine", "ambient", and
"other".  We use the syntax "A-B" here, where A is the species (mel
being short for *D.  melanogaster*) and B is the song type, but that is not
strictly required.  The word syntax could nominally be anything.  The GUI
does have a feature, however, to split labels at the hyphen and display
groups of words that share a common prefix or suffix.

## Training a Classifier ##

Once you have a few tens of examples for each word, it's time to train a
classifier.  First, confirm that the annotations you just made were saved into
an "-annotated.csv" file in the ground-truth folder.

    $ tree groundtruth-data
    groundtruth-data
    ├── cluster.npz
    ├── cluster.log
    ├── hidden.npz
    ├── hidden.log
    ├── hidden-samples.log
    └── round1
        ├── PS_20130625111709_ch3_p1-annotated.csv
        ├── PS_20130625111709_ch3_p1-detected.csv
        ├── PS_20130625111709_ch3_p1-threshold.log
        └── PS_20130625111709_ch3_p1.wav

    $ tail -5 groundtruth-data/round1/PS_20130625111709_ch3_p1-annotated.csv
    PS_20130625111709_ch3_p1.wav,771616,775264,annotated,mel-sine
    PS_20130625111709_ch3_p1.wav,864544,870112,annotated,mel-sine
    PS_20130625111709_ch3_p1.wav,898016,910276,annotated,ambient
    PS_20130625111709_ch3_p1.wav,943493,943523,annotated,mel-pulse
    PS_20130625111709_ch3_p1.wav,943665,943692,annotated,mel-pulse

Now train a classifier on your annotations using the `Train` button.  Fifty steps
suffices for this amount of ground truth.  So we can accurately monitor the
progress, withhold 40% of the annotations to validate on, and do so every 10
steps.  You'll also need to change the `wanted words` variable to
"mel-pulse,mel-sine,ambient,other" and `label types` to "annotated" so that it
will ignore the detected annotations in the ground-truth directory.  It's
important to include "other" as a wanted word here, even if you haven't labeled
any sounds as such, as it will be used later by DeepSong to highlight false
negatives ([see Correcting Misses](#correcting-misses)).  Note that the total
number of annotations must exceed the size of the mini-batches, which is
specified by the `mini-batch` variable.

With small data sets the network should just take a minute or so to train.
As your example set grows, you might want to monitor the training progress
as it goes:

    $ watch tail trained-classifier/train_1.log
    Every 2.0s: tail trained-classifier1/train_1.log      Mon Apr 22 14:37:31 2019

    INFO:tensorflow:Elapsed 39.697532, Step #9: accuracy 75.8%, cross entropy 0.947476
    INFO:tensorflow:Elapsed 43.414184, Step #10: accuracy 84.4%, cross entropy 0.871244
    INFO:tensorflow:Saving to "/home/arthurb/deepsong/trained-classifier1/train_1k/vgg.ckpt-10"
    INFO:tensorflow:Confusion Matrix:
     ['mel-pulse', 'mel-sine', 'ambient']
     [[26  9  9]
     [ 0  4  0]
     [ 0  0  4]]
    INFO:tensorflow:Elapsed 45.067488, Step 10: Validation accuracy = 65.4% (N=52)
    INFO:tensorflow:Elapsed 48.786851, Step #11: accuracy 79.7%, cross entropy 0.811077

It is common for the accuracy, as measured on the withheld data and reported as
"Validation accuracy" in the log file above, to be worse than the training
accuracy.  If so, it is an indication that the classifier does not generalize
well at that point.  With more training steps and more ground-truth data though
the validation accuracy should become well above chance.

## Quantifying Accuracy ##

Measure the classifier's performance using the `Accuracy` button.  Output are the
following charts and tables in the logs folder and the `train_*` subdirectories
therein:

* "train-loss.pdf" shows the training and validation accuracies, and loss
value, as a function of the number of training steps and wall-clock time.
Should the curves not quite plateau, choose a checkpoint to `restore from`,
increase `# steps`, and train some more.  If you've changed any of the
parameters, you'll need to first reset them as they were, which is made easy by
selecting one of the original log files and pressing the `Copy` button.

* "train-overlay.pdf" shows the same validation accuracy overlayed across all
cross-validation folds or leave-one-out models.  This is the best place to make
sure that the validation accuracy has not plateaued before the first epoch of
data has been train upon.

* "confusion-matrices.pdf" shows which word each annotation was classified as,
separately for each cross-validation fold or leave-one-out model.  The upper
right triangle in each square is normalized to the row and is called the
recall, while the lower left is to the column-normalized precision.

* "validation-F1.pdf" plots the F1 score (the product divided by the sum of the
precision and recall) over time for each of the `wanted words` separately.
Check here to make sure that the accuracy of each word has converged.

* "accuracy.pdf" has plots showing the final accuracy for each model, the sum
of the confusion matrices across all models, and the final precision and recall
for each word and all models.

* "precision-recall.pdf" and "sensitivity-specificity.pdf" show how the ratio
of false positives to false negatives changes as the threshold used to call an
event changes.  The areas underneath these curves are widely-cited metrics of
performance.

* "thresholds.csv" lists the word-specific probability thresholds that one can
use to achieve a specified precision-recall ratio.  This file is used when
creating ethograms ([see Making Predictions](#making-predictions)).

* "probability-density.pdf" shows, separately for each word, histograms of the
values of the classifier's output taps across all of that word's annotations.
The difference between a given word's probability distribution and the second
most probable word can be used as a measure of the classifier's confidence.

* The CSV files in the "predictions/" directory list the specific annotations
which were mis-classified (plus those that were correct).  The WAV files and
time stamps therein can be used to look for patterns in the raw data ([see
Examining Errors](#examining-errors)).


## Making Predictions ##

For the next round of manual annotations, we're going to have this newly
trained classifier find sounds for us instead of using a simple threshold.  And
we're going to do so with a different recording so that the classifier learns
to be insensitive to experimental conditions.

First let's get some more data bundled with DeepSong into your home directory:

    $ mkdir groundtruth-data/round2

    $ $DEEPSONG_BIN cp /opt/deepsong/data/20161207T102314_ch1_p1.wav \
            groundtruth-data/round2

Then use the `Freeze` button to save the classifier's neural network graph
structure and weight parameters into the single file that TensorFlow needs for
inference.  You'll need to choose a checkpoint to use with the File Dialog
browser as before.  Output into the log files directory are two ".log" files
for errors, and a file ending with ".pb" containing the binary data.  This latter
PB file can in future be chosen as the model instead of a checkpoint file.

Now use the `Classify` button to generate probabilities over time for each
annotated word.  Specify which recordings using the `File Dialog` browser and
the `WAV,TF,CSV Files` button.  These are first stored in a file ending in
".tf", and then converted to WAV files for easy viewing.

    $ ls groundtruth-data/round2/
    20161207T102314_ch1_p1-ambient.wav    20161207T102314_ch1_p1-other.wav
    20161207T102314_ch1_p1-classify.log   20161207T102314_ch1_p1.tf
    20161207T102314_ch1_p1-mel-pulse.wav  20161207T102314_ch1_p1.wav
    20161207T102314_ch1_p1-mel-sine.wav

Discretize these probabilities using thresholds based on a set of
precision-recall ratios using the `Ethogram` button.  The ratios used are those
in the "thresholds.csv" file in the log files folder, which is created by the
`Accuracy` button and controlled by the `P/Rs` variable.  You'll need to specify
which ".tf" files to threshold using the `File Dialog` browser and the `WAV,TF,CSV`
button.

    $ ls -t1 groundtruth-data/round2/ | head -4
    20161207T102314_ch1_p1-ethogram.log
    20161207T102314_ch1_p1-predicted-0.5pr.csv
    20161207T102314_ch1_p1-predicted-1.0pr.csv
    20161207T102314_ch1_p1-predicted-2.0pr.csv

    $ head -5 groundtruth-data/round2/20161207T102314_ch1_p1-predicted-1.0pr.csv 
    20161207T102314_ch1_p1.wav,19976,20008,predicted,mel-pulse
    20161207T102314_ch1_p1.wav,20072,20152,predicted,mel-sine
    20161207T102314_ch1_p1.wav,20176,20232,predicted,mel-pulse
    20161207T102314_ch1_p1.wav,20256,20336,predicted,mel-sine
    20161207T102314_ch1_p1.wav,20360,20416,predicted,mel-pulse

The resulting CSV files are in the same format as those generated when we
detected sounds in the time and frequency domains as well as when we manually
annotated words earlier using the GUI.  Note that the fourth column
distinguishes whether these words were detected, annotated, or predicted.

## Correcting False Alarms ##

In the preceding section we generated three sets of predicted sounds by
applying three sets of word-specific thresholds to the probability waveforms:

    $ cat trained-classifier/thresholds.csv 
    precision/recall,2.0,1.0,0.5
    mel-pulse,0.9977890984593017,0.508651224000211,-1.0884193525904096
    mel-sine,0.999982304641803,0.9986744484433365,0.9965472849431617
    ambient,0.999900757998532,0.9997531463467944,0.9996660975683063

Higher thresholds result in fewer false positives and more false negatives.
A precision-recall ratio of one means these two types of errors occur at
equal rates.  Your experimental design drives this choice.

Let's manually check whether our classifier in hand accurately calls sounds
using these thresholds.  First, click on the `Fix False Positives` button to
disable the irrelevant actions and fields.  Then choose one of the predicted
CSV files that has a good mix of the labels and either delete or move outside
of the ground-truth directory the other ones.  Double check that the `label
types` variable was auto-populated with "annotated,predicted".  Not having
"detected" in this field ensures that "detected.csv" files in the ground-truth
folder is ignored.  Finally, cluster and visualize the neural network's hidden
state activations as we did before using the `Activations`, `Cluster`, and
`Visualize` buttons.  So that words with few samples are not obscured by those
with many, randomly subsample the latter by setting `equalize ratio` to a small
integer when saving the hidden state activations.

Now let's correct the mistakes!  Select `predicted` and `ambient` from the
`kind` and `no hyphen` pull-down menus, respectively, and then on a dense part
of the density map.  Optionally adjust the `circle radius` and `hex size`
variables.  Were the classifier perfect, all the snippets now displayed would
look like background noise.  Click on the ones that don't and manually annotate
them appropriately.  Similarly select `mel-` and `-pulse` from the `species`
and `word` pull-down menus and correct any mistakes, and then `mel-` and
`-sine`.

Keep in mind that the only words which show up in the clusters are those that
exceed the chosen threshold.  Any mistakes you find in the snippets are hence
strictly false positives.

## Correcting Misses ##

It's important that false negatives are corrected as well.  One way find them
is to click on random snippets and look in the surrounding context in the
window below for sounds that have not been predicted.  A better way is to home
in on detected sounds that don't exceed the probability threshold.

To systematically label missed sounds, first click on the `Fix False Negatives`
button.  Then detect sounds in the recording you just classified, using the
`Detect` button as before, and create a list of the subset of these sounds which
were not assigned a label using the `Misses` button.  For the latter, you'll need
to specify both the detected and predicted CSV files with the `File Dialog`
browser and the `WAV,TF,CSV` button.  The result is another CSV file, this time
ending in "missed.csv":

    $ head -5 groundtruth-data/round2/20161207T102314_ch1_p1-missed.csv 
    20161207T102314_ch1_p1.wav,12849,13367,missed,other
    20161207T102314_ch1_p1.wav,13425,13727,missed,other
    20161207T102314_ch1_p1.wav,16105,18743,missed,other
    20161207T102314_ch1_p1.wav,18817,18848,missed,other
    20161207T102314_ch1_p1.wav,19360,19936,missed,other

Now visualize the hidden state activations--  Double check that the `label
types` variable was auto-populated with "annotated,missed", and then press the
`Activations`, `Cluster`, and `Visualize` buttons in turn.

Examine the false negatives by selecting `missed` in the `kind` pull-down menu
and click on a dense cluster.  Were the classifier perfect, none of the
snippets would be an unambiguous example of any of the labels you trained upon
earlier.  Annotate any of them that are, and add new label types for sound
events which fall outside the current categories.

## Minimizing Annotation Effort

From here, we just keep alternating between annotating false positives and
false negatives, using a new recording for each iteration, until mistakes
become sufficiently rare.  The most effective annotations are those that
correct the classifier's mistakes, so don't spend much time, if any, annotating
what it got right.

Each time you train a new classifier, all of the existing "predicted.csv",
"missed.csv", ".tf", and word-probability WAV files are moved to an "oldfiles"
sub-folder as they will be out of date.  You might want to occasionally delete
these folders to conserve disk space:

    $ rm groundtruth-data/*/oldfiles*

Ideally a new model would be trained after each new annotation is made, so that
subsequent time is not spent correcting a prediction (or lack thereof) that
would no longer be made in error.  Training a classifier takes time though, so
a balance must be struck with how quickly you alternate between annotating and
training.

Since there are more annotations each time you train, use a proportionately
smaller percentage of them for validation and proportionately larger number of
training steps.  You don't need more than ten-ish annotations for each word to
confirm that the learning curves converge, and a hundred-ish suffice to
quantify accuracy.  Since the learning curves generally don't converge until
the entire data set has been sampled many times over, set `# steps` to be
several fold greater than the number of annotations (shown in the table near
the labels) divided by the `mini-batch` size, and check that it actually
converges with the "train-loss.pdf" "validation-F1.pdf" figures generated by
the `Accuracy` button.  If the accuracy converges before an entire epoch
has been trained upon, use a smaller `learning rate`.

As the wall-clock time spent training is generally shorter with larger
mini-batches, set it as high as the memory in your GPU will permit.  Multiples
of 32 are generally faster.  The caveat here is that exceedingly large
mini-batches can reduce accuracy, so make sure to compare it with smaller ones.

One should make an effort to choose a recording at each step that is most
different from the ones trained upon so far.  Doing so will produce a
classifier that generalizes better.

Once a qualitatively acceptable number of errors in the ethograms is achieved,
quantitatively measure your model's ability to generalize by leaving entire
recordings out for validation ([see Measuring
Generalization](#measuring-generalization)), and/or using cross validation (see
[Searching Hyperparameters](#searching-hyperparameters)).  Then train a single
model with nearly all of your annotations for use in your experiments.  Report
its accuracy on an entirely separate set of densely-annotated test data([see
Testing Densely](#testing-densely)).

## Double Checking Annotations

If a mistake is made annotating, say the wrong label is applied to a particular
time interval, and one notices this immediately, the `Undo` button can be used
to correct it.

Sometimes though, mistakes might slip into the ground truth and a model is
trained with them.  These latter mistakes can be corrected in a fashion similar
to correcting false positives and false negatives.  Simply cluster the hidden
state activations as before making sure that "annotated" is in `label types`.
Then click on `annotated` and select one of your labels (e.g.  `mel-` and
`-pulse`).  If you want to change the label of an annotation, simply choose the
correct label in one of the text boxes below and then double click on either
the snippet itself or the corresponding gray box in the upper half of the wide
context window.  If you want to remove the annotation entirely, choose a label
with an empty text box and double-click.  In both cases, the entry in the
original "annotated.csv" file is removed, and in the former case a new entry is
created in the current "annotated.csv" file.  Should you make a mistake while
correcting a mistake, simply `Undo` it, or double click it again.  In this
case, the original CSV entry remains deleted and the new one removed from the
current "annotated.csv" file.

## Measuring Generalization ##

Up to this point we have validated on a small portion of each recording.  Once
you have annotated many recordings though, it is good to set aside entire WAV
files to validate on.  In this way we measure the classifier's ability to
extrapolate to different microphones, individuals, or whatever other
characteristics that are unique to the withheld recordings.

To train one classifier with a single recording or set of recordings withheld
for validation, first click on `Generalize` and then `Omit All`.  Use the `File
Dialog` browser to either select (1) specific WAV file(s), (2) a text file
containing a list of WAV file(s) (either comma separated or one per line), or
(3) the ground-truth folder or a subdirectory therein.  Finally press the
`Validation Files` button and `DoIt!`.

To train multiple classifiers, each of which withholds a single recording in a
set you specify, click on `Omit One`.  Select the set as described above for
`Omit All`.  The `DoIt!` button will then iteratively launch a job for each WAV
file that has been selected, storing the result in the same Logs Folder in
separate files and subdirectories that are suffixed the letter "w".  Of course,
training multiple classifiers is quickest when done simultaneously instead of
sequentially.  If your model is small, you might be able to fit multiple on a
single GPU (see the "njobs_per_gpu" variable in "configuration.sh").
Otherwise, you'll need a machine with multiple GPUs, access to a cluster or
the cloud, or patience.

A simple jitter plot of the accuracies on withheld recordings is included in
the output of the `Accuracy` button ("accuracy.pdf").  It will likely be worse
than a model trained on a portion of each recording.  If so, label more data,
or try modifying the hyperparameters ([Searching
Hyperparameters](#searching-hyperparameters))

## Searching Hyperparameters ##

Achieving high accuracy is not just about annotating lots of data, it also
depends on choosing the right model.  While DeepSong is (currently) set up
solely for convolutional neural networks, there are many free parameters by
which to tune its architecture.  You configure them by editing the variables
itemized below, and then use cross-validation to compare different choices.
One could of course also modify the source code to permit radically different
neural architectures, or even something other than neural networks.

* `context` is the temporal duration, in milliseconds, that the classifier
inputs

* `shift by` is the asymmetry, in milliseconds, of `context` with respect to the
point in time that is annotated or being classified.  `shift by` divided by
`stride` (see below) should be an integer.  For positive values the duration of
the context preceding the annotation is longer than that succeeding it.

* `representation` specifies whether to use the raw waveform directly, to make
a spectrogram of the waveform to input to the neural network, or to use a
mel-frequency cepstrum (see [Davis and Mermelstein 1980;
IEEE](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.462.5073&rep=rep1&type=pdf)).
Waveforms do not make any assumptions about the data, and so can learn
arbitrary features that spectrograms and cepstrums might be blind to, but need
more annotations to make the training converge.

* `window` is the length of the temporal slices, in milliseconds, that
constitute the spectrogram.  `window` / 1000 * `tic rate` should round down
to a power of two.

* `stride` is the time, in milliseconds, by which the `window`s in the
spectrogram are shifted.  1000/`stride` must be an integer.

* `mel & DCT` specifies how many taps to use in the mel-frequency cepstrum.  The
first number is for the mel-frequency resampling and the second for the
discrete cosine transform.  Modifying these is tricky as valid values depend on
`tic rate` and `window`.  The table below shows the maximum permissible
values for each, and are what is recommended.  See the code in
"tensorflow/contrib/lite/kernels/internal/mfcc.cc" for more details.

|sample rate|window|mel,DCT|
|:---------:|:----:|:-----:|
|10000      |12.8  |28,28  |
|10000      |6.4   |15,15  |
| 5000      |6.4   |11,11  |
| 2500      |6.4   |7,7    |
| 1250      |6.4   |3,3    |
|10000      |3.2   |7,7    |
| 6000      |10.7  |19,19  |

* `dropout` is the fraction of hidden units on each forward pass to omit
during training.  See [Srivastava, Hinton, *et al* (2014; J. Machine Learning Res.)](http://jmlr.org/papers/v15/srivastava14a.html).

* `optimizer` can be one of stochastic gradient descent (SGD),
[Adam](https://arxiv.org/abs/1412.6980),
[AdaGrad](http://www.jmlr.org/papers/volume12/duchi11a/duchi11a.pdf), or
[RMSProp](https://www.cs.toronto.edu/~tijmen/csc321/slides/lecture_slides_lec6.pdf).

* `learning rate` specifies the fraction of the gradient to change each weight
by at each training step.  Set it such that the training curve accuracy in
"train-loss.pdf" does not saturate until after at least one epoch of ground
truth has been trained upon.

* `kernels` is a 3-vector of the size of the convolutional kernels.  The first
value is used for each layer until the tensor height in the frequency axis is
smaller than it.  Then the second value is then repeatedly used until the
height is again smaller than it.  Finally the third value is used until the
width is less than `last conv width`.  Only the third value matters when
`representation` is "waveform".

* `# features` is the number of feature maps to use at each of the corresponding stages
in `kernel_sizes`.  See [LeCun *et al* (1989; Neural Computation)](http://yann.lecun.com/exdb/publis/pdf/lecun-89e.pdf).

* `dilate after` specifies the first layer, starting from zero, at which to
start dilating the convolutional kernels.  See [Yu and Koltun (2016;
arXiv)](https://arxiv.org/pdf/1511.07122.pdf).

* `stride after` specifies the first layer, starting from zero, at which to
start striding the convolutional kernels by two.

* `connection` specifies whether to use identity bypasses, which can help
models with many layers converge.  See [He, Zhang, Ren, and Sun (2015;
arXiv](https://arxiv.org/abs/1512.03385).

To search for the optimal value for a particular hyperparameter, first choose
how many folds you want to partition your ground-truth data into using
`k-fold`.  Then set the hyperparameter of interest to the first value you want
to try and choose a name for the `Logs Folder` such that its prefix will be
shared across all of the hyperparameters values you plan to validate.  Suffix
any additional hyperparameters of interest using underscores.  (For example, to
search mini-batch and keep track of kernel size and feature maps, use
"mb-64_ks129_fm64".)  Click the `X-Validate` button and then `DoIt!`.  One
classifier will be trained for each fold, using it as the validation set and
the remaining folds for training.  Separate files and subdirectories are
created in the `Logs Folder` that are suffixed by the fold number and the
letter "k".  Plot overlayed training curves with the `Accuracy` button, as
before.  Repeat the above procedure for each of remaining hyperparameter values
you want to try (e.g. "mb-128_ks129_fm64", "mb-256_ks129_fm64", etc.).  Then
use the `Compare` button to create a figure of the cross-validation data over
the hyperparameter values, specifying the prefix that the logs folders have in
common ("mb" in this case).  Output are three files:

* "[suffix]-compare-confusion-matrices.pdf" contains the summed confusion matrix
for each of the values tested.

* "[suffix]-compare-overall-params-speed.pdf" plots the accuracy, number of
trainable parameters, and training time for each model.

* "[suffix]-compare-precision-recall.pdf" shows the final false negative and
false positive rates for each model and wanted word.

## Examining Errors ##

Mistakes can possibly be corrected if more annotations are made of similar
sounds.  To find such sounds, cluster the errors made on the ground-truth
annotations with sounds detected in your recordings.  Then look for
localized hot spots of mistakes and make annotations therein.

DeepSong provides two ways to generate lists of errors, which you'll need to
choose between.  The `Accuracy` button does so just for the validation data,
while `Activations` uses the entire ground truth or a randomly sampled subset
thereof.

As [mentioned earlier](#quantifying-accuracy), the `Accuracy` button creates a
"predictions/" folder in the Log Folder containing CSV files itemizing whether
the sounds in the validation set were correctly or incorrectly classified.
Each CSV file corresponds to a sub-folder within the ground-truth folder.  The
file format is similar to DeepSong's other CSV files, with the difference being
that the penultimate column is the prediction and the final one the annotation.
To use these predictions, copy these CSV files into their corresponding
ground-truth sub-folders.

    $ tail -n 10 trained-classifier/predictions/round2-mistakes.csv 
    PS_20130625111709_ch3_p1.wav,377778,377778,correct,mel-pulse,mel-pulse
    PS_20130625111709_ch3_p1.wav,157257,157257,correct,mel-pulse,mel-pulse
    PS_20130625111709_ch3_p1.wav,164503,165339,correct,ambient,ambient
    PS_20130625111709_ch3_p1.wav,379518,379518,mistaken,ambient,mel-pulse
    PS_20130625111709_ch3_p1.wav,377827,377827,correct,mel-pulse,mel-pulse
    PS_20130625111709_ch3_p1.wav,378085,378085,correct,mel-pulse,mel-pulse
    PS_20130625111709_ch3_p1.wav,379412,379412,mistaken,ambient,mel-pulse
    PS_20130625111709_ch3_p1.wav,160474,161353,correct,ambient,ambient
    PS_20130625111709_ch3_p1.wav,207780,208572,correct,mel-sine,mel-sine
    PS_20130625111709_ch3_p1.wav,157630,157630,correct,mel-pulse,mel-pulse

Similarly, the `Activations` button creates an "activations.npz" file
containing the logits of the output layer (which is just a vector of word
probabilities), as well as the correct answer from the ground-truth
annotations.  To turn these data into a CSV file, use the `Mistakes` button.
In the ground-truth sub-folders, CSV files are created for each WAV file, with
an extra column just like above.  No need to copy any files here.

Now detect sounds in the ground-truth recordings for which you haven't done so
already.  Press the `Examine Errors` wizard and confirm that `label types` is
set to "detected,mistaken", and save the hidden state activations, cluster, and
visualize as before.  Select `mistaken` in the `kind` pull-down menu to look
for a localized density.  View the snippets in any hot spots to examine the
shapes of waveforms that are mis-classified-- the ones whose text label, which
is the prediction, does not match the waveform.  Then select `detected` in the
`kind` pull-down menu and manually annotate similar waveforms.  Nominally they
will cluster at the same location.

## Testing Densely ##

The accuracy statistics reported in the confusion matrices described above are
limited to the points in time which are annotated.  If an annotation withheld
to validate upon does not elicit the maximum probability across all output taps
at the corresponding label, it is considered an error.  Quantifying accuracy in
this way is a bit misleading, as when a model is used to make ethograms, a
word-specific threshold is applied to the probabilities instead.  Moreover,
ethograms are made over the entire recording, not just at specific times of
interest.  To more precisely quantify a model's accuracy then, as it would be
used in your experiments, a dense annotation is needed-- one for which all
occurrences of any words of interest are annotated.

To quantify an ethogram's accuracy, first select a set of recordings in your
validation data that are collectively long enough to capture the variance in
your data set but short enough that you are willing to manually label every
word in them.  Then detect and cluster the sounds in these recordings using the
`Detect`, `Activations`, `Cluster`, and `Visualize` buttons as described
earlier.  Annotate every occurrence of each word of interest by jumping to the
beginning of each recording and panning all the way to the end.  Afterwards,
manually suffix each resulting "annotated.csv" file with the name of the
annotator (e.g. "annotated-yyyymmddThhmmss-ben.csv").  Take your best model to
date and make ethograms of these densely annotated recordings using the
`Classify` and `Ethogram` buttons as before.  Finally, use the `Congruence`
button to plot the fraction of false positives and negatives, specifying which
files you've densely annotated with `Ground Truth` and either `Validation
Files` or `Test Files` (a comma-separated list of .wav files, a text file of
.wav filenames, or a folder of .wav files; see [Measuring
Generalization](#measuring-generalization)).  If the accuracy is not
acceptable, iteratively adjust the hyperparameters, train a new model, and make
new ethograms and congruence plots until it is.  You might also need to add new
annotations to your training set.

Once the accuracy is acceptable on validation data, quantify the accuracy on a
densely annotated test set.  The network should have never been trained or
validated on these latter data before; otherwise the resulting accuracy could
be spuriously better.  Label every word of interest as before, make ethograms
with your best model, and plot the congruence with DeepSong's predictions.
Hopefully the accuracy will be okay.  If not, and you want to change the
hyperparameters or add more training data, then the proper thing to do is to
use this test data as training or validation data going forward, and densely
annotate a new set of data to test against.

The congruence between multiple human annotators can be quantified using the
same procedure.  Simply create "annotated-yyyymmddThhmmss-\<name\>.csv" files
for each one.  The plot created by `Congruence` will include bars for the
number of sounds labeled by all annotators (including DeepSong), only each
annotator, and not by a given annotator.

Much as one can examine the mistakes of a particular model with respect to
sparsely annotated ground truth by clustering with "mistaken" as one of the
`label types`, one can look closely at the errors in congruence between a model
and a densely annotated test set by using
"everyone|{tic,word}-{only,not}{1.0pr,annotator1,annotator2,...}".  Note that
the Congruence button generates a bunch of "disjoint.csv" files:
"disjoint-everyone.csv" contains the intersection of intervals that DeepSong
and all annotators agreed upon; "disjoint-only.csv" files contain the intervals
which only DeepSong or one particular annotator labelled; "disjoint-not.csv"
contains those which were labelled by everyone except DeepSong or a given
annotator.  Choose one or all of these label types and then use the
Activations, Cluster, and Visualize buttons as before.

## Discovering Novel Sounds ##

After amassing a sizeable amount of ground truth one might wonder whether one
has manually annotated all types of words that exist in the recordings.  One
way to check for any missed types is to look for hot spots in the clusters of
detected sounds that have no corresponding annotations.  Annotating known types
in these spots should improve generalization too.

First, set `label types` to "annotated" and train a model that includes "time"
and "frequency" plus all of your existing wanted words
("mel-pulse,mel-sine,ambient,other").  Then, use the `Detect` button to
threshold the recordings that you want to search for novel sounds.  Save their
hidden state activations, along with those of the manually annotated sounds,
using the `Activations` button by setting the label types to "annotated,detected".
Cluster and visualize as before.  Now rapidly and alternately switch between
`annotated` and `detected` in the `kind` pull-down menu to find any differences
in the density distributions.  Click on any new hot spots you find in the
detected clusters, and annotate sounds which are labeled as detected but not
annotated.  Create new word types as necessary.

## Scripting Automation ##

For some tasks it may be easier to write code instead of use the GUI--
tasks which require many tedious mouse clicks, for example, or simpler ones
that must be performed over and over again.  To facilitate coding your
analysis, DeepSong is structured such that each action button (`Detect`,
`Misses`, `Activations`, etc.) is backed by a linux shell script.  At the top each
script is documentation showing how to call it.  Here, for example, is the
interface for `Classify`:

    $ $DEEPSONG_BIN head -n 8 /opt/deepsong/src/classify.sh
    #!/bin/bash

    # generate per-class probabilities

    # classify.sh <config-file> <context_ms> <shiftby_ms> <representation> \
      <stride_ms> <logdir> <model> <check-point> <wavfile>

    # e.g.
    # deepsong classify.sh `pwd`/configuration.sh 204.8 0.0 waveform 1.6 \
      `pwd`/trained-classifier train_1 50 \
      `pwd`/groundtruth-data/round1/20161207T102314_ch1_p1.wav

The following example uses this script to make predictions on a set of
recordings in different folders.  It is written in bash, but you could easily
use Julia, Python, Matlab, or any other language that can execute shell
commands.

    $ basepath=groundtruth-data
    $ logdir=trained-classifier
    $ model=train_1
    $ ckpt=100

    $ wavfiles=(
          round1/20161207T102314_ch1_p1
          round3/20161207T102314_ch1_p2
          round5/20161207T102314_ch1_p3
          round2/PS_20130625111709_ch3_p1
          round4/PS_20130625111709_ch3_p2
          round6/PS_20130625111709_ch3_p3
          )

    $ for wavfile in ${wavfiles[@]} ; do
          $DEEPSONG_BIN classify.sh deepsong/configuration.sh \
                  204.8 0.0 waveform 1.6 \
                  $logdir $model $ckpt $basepath/$wavfile.wav
      done


# Troubleshooting #

* Sometimes using control-C to quit out of DeepSong does not work.  In this
case, kill it with `ps auxc | grep -E '(gui.sh|bokeh)'` and then `kill -9
<pid>`.  Errant jobs can be killed similarly.


# Frequently Asked Questions #

* The `WAV,TF,CSV Files` textbox, being plural, can contain multiple
comma-separated filenames.  Just select multiple files in the File Dialog
browser using shift/command-click as you would in most other file browsers.


# Reporting Problems #

The code is hosted on [github](https://github.com/JaneliaSciComp/DeepSong).
Please file an issue there for all bug reports and feature requests.
Pull requests are also welcomed!  For major changes it is best to file an
issue first so we can discuss implementation details.  Please work with us
to improve DeepSong instead instead of forking your own version.


# Development #

## Singularity ##

To build an image, change to a local (i.e. not NFS mounted; e.g.
/opt/users) directory and:

    $ git clone https://github.com/JaneliaSciComp/DeepSong.git
    $ rm -rf deepsong/.git
    $ sudo singularity build -s deepsong.img deepsong/containers/singularity.def

To confirm that the image works:

    $ singularity run --nv deepsong.img
    >>> import tensorflow as tf
    >>> msg = tf.constant('Hello, TensorFlow!')
    >>> tf.print(msg)

Optionally, compress the image into a single file:

    $ sudo singularity build deepsong.sif deepsong.img

To push an image to the cloud, first create an access token at cloud.sylabs.io
and save it using `singularity remote login SylabsCloud`.  Then:

    $ singularity sign deepsong.sif
    $ singularity push deepsong.sif library://bjarthur/default/deepsong:<version>[_cpu]

To build an image without GPU support, comment out the section titled "install CUDA" in
"singularity.def" and omit the `--nv` flags.

To use the DeepSong source code outside of the container, set
SINGULARITYENV_PREPEND_PATH to the full path to DeepSong's `src` directory in
your shell environment.  `server_export` in "configuration.sh" must be set
similarly if using a remote workstation.

## Docker ##

To start docker on linux and set permissions:

    $ service docker start
    $ setfacl -m user:$USER:rw /var/run/docker.sock

To build a docker image and push it to docker hub:

    $ cd deepsong
    $ docker build --file=containers/dockerfile-cpu --tag=bjarthur/deepsong \
          [--no-cache=true] .
    $ docker login
    $ docker {push,pull} bjarthur/deepsong

To monitor resource usage:

    $ docker stats

To run a container interactively add "-i --tty".
