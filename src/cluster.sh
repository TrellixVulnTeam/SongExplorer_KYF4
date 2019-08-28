#!/bin/bash

# reduce dimensionality of internal activation states
 
# cluster.sh <config-file> <groundtruth-directory> <pca-fraction-variance-to-retain> <t-sne|umap> [ <tsne-perplexity> <tsne-exaggeration> | <umap-n-neighbors> <umap-min-distance> ]

# e.g.
# $DEEPSONG_BIN cluster.sh `pwd`/configuration.sh `pwd`/groundtruth-data 0.99 t-sne 30 12.0
# $DEEPSONG_BIN cluster.sh `pwd`/configuration.sh `pwd`/groundtruth-data 1 umap 10 0.1

config_file=$1
groundtruth_directory=$2
pca_fraction_variance_to_retain=$3
cluster_algorithm=$4
cluster_ndims=${5:0:1}

echo $cluster_algorithm

shift 5

source $config_file

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cluster_algorithm="$(echo $cluster_algorithm | tr '[A-Z]' '[a-z]')"
varargs=("$@")

expr="$DIR/cluster.py \"$groundtruth_directory\" $pca_fraction_variance_to_retain $pca_batch_size $cluster_algorithm $cluster_ndims $cluster_parallelize ${varargs[@]}"

cmd="date; hostname; $expr; sync; date"
echo $cmd

logfile=${groundtruth_directory}/cluster.log

cluster_it "$cmd" "$logfile"
