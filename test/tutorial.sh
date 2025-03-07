#!/usr/bin/env bash

# recapitulate the tutorial via the shell interface

#${SONGEXPLORER_BIN/-B/-B /tmp:/opt/songexplorer/test/scratch -B} bash -c "test/tutorial.sh"

check_file_exists() {
  if [[ ! -e $1 ]] ; then
    echo ERROR: $1 is missing
    return 1
  fi
  return 0; }

count_lines_with_label() {
  check_file_exists $1 || return
  local count=$(grep $2 $1 | wc -l)
  (( "$count" == "$3" )) && return
  echo $4: $1 has $count $2 when it should have $3
  if [ "$4" == "WARNING" ]; then echo $4: it is normal for this to be close but not exact; fi; }

count_lines() {
  check_file_exists $1 || return
  local count=$(cat $1 | wc -l)
  (( "$count" == "$2" )) && return
  echo ERROR: $1 has $count lines when it should have $2; }

repo_path=$(dirname $(dirname $(readlink -f $(which songexplorer))))

mkdir -p $repo_path/test/scratch/tutorial-sh
cp $repo_path/configuration.pysh $repo_path/test/scratch/tutorial-sh

source $repo_path/test/scratch/tutorial-sh/configuration.pysh
deterministic=1

mkdir -p $repo_path/test/scratch/tutorial-sh/groundtruth-data/round1
cp $repo_path/data/PS_20130625111709_ch3.wav \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/round1

wavpath_noext=$repo_path/test/scratch/tutorial-sh/groundtruth-data/round1/PS_20130625111709_ch3
detect_parameters='{"time_sigma":"9,4","time_smooth_ms":"6.4","frequency_n_ms":"25.6","frequency_nw":"4","frequency_p":"0.1,1.0","frequency_smooth_ms":"25.6","time_sigma_robust":"median"}'
cmd="${detect_plugin}.py \
      ${wavpath_noext}.wav \
      '$detect_parameters' \
      $audio_tic_rate $audio_nchannels"
echo $cmd &>> ${wavpath_noext}-detect.log
eval $cmd &>> ${wavpath_noext}-detect.log

check_file_exists ${wavpath_noext}-detect.log
check_file_exists ${wavpath_noext}-detected.csv
count_lines_with_label ${wavpath_noext}-detected.csv time 536 ERROR
count_lines_with_label ${wavpath_noext}-detected.csv frequency 45 ERROR
count_lines_with_label ${wavpath_noext}-detected.csv neither 1635 ERROR

cp $repo_path/data/PS_20130625111709_ch3-annotated-person1.csv \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/round1

context_ms=204.8
shiftby_ms=0.0
optimizer=Adam
learning_rate=0.0002
architecture=convolutional
model_parameters='{"representation":"mel-cepstrum","window_ms":"6.4","stride_ms":"1.6","mel_dct":"7,7","dropout_kind":"unit","dropout_rate":"50","augment_volume":"1,1","augment_noise":"0,0","normalization":"none","kernel_sizes":"5x5,3","nconvlayers":"2","denselayers":"","nfeatures":"64,64","stride_time":"","stride_freq":"","dilate_time":"","dilate_freq":"","connection_type":"plain"}'
logdir=$repo_path/test/scratch/tutorial-sh/trained-classifier1
data_dir=$repo_path/test/scratch/tutorial-sh/groundtruth-data
labels_touse=mel-pulse,mel-sine,ambient
kinds_touse=annotated
nsteps=300
restore_from=
save_and_test_period=30
validation_percentage=40
mini_batch=32
testing_files=
batch_seed=1
weights_seed=1
ireplicates=1
mkdir $logdir
cmd="train \
      $context_ms $shiftby_ms \
      $optimizer $learning_rate  \
      $audio_read_plugin $audio_read_plugin_kwargs \
      $video_read_plugin $video_read_plugin_kwargs \
      $video_findfile_plugin $video_bkg_frames \
      $data_loader_queuesize $data_loader_maxprocs \
      $architecture '$model_parameters' \
      $logdir $data_dir $labels_touse $kinds_touse \
      $nsteps '$restore_from' $save_and_test_period $validation_percentage \
      $mini_batch '$testing_files' \
      $audio_tic_rate $audio_nchannels \
      $video_frame_rate $video_frame_width $video_frame_height $video_channels \
      $batch_seed $weights_seed $deterministic \
      $ireplicates"
echo $cmd &>> $logdir/train1.log
eval $cmd &>> $logdir/train1.log

check_file_exists $logdir/train1.log
check_file_exists $logdir/train_1r.log
check_file_exists $logdir/train_1r/ckpt-$nsteps.index
check_file_exists $logdir/train_1r/logits.validation.ckpt-$nsteps.npz

precision_recall_ratios=0.5,1.0,2.0
cmd="accuracy $logdir $precision_recall_ratios \
      $nprobabilities $accuracy_parallelize"
echo $cmd &>> $logdir/accuracy.log
eval $cmd &>> $logdir/accuracy.log

check_file_exists $logdir/accuracy.log
check_file_exists $logdir/accuracy.pdf
check_file_exists $logdir/train_1r/precision-recall.ckpt-$nsteps.pdf
check_file_exists $logdir/train_1r/probability-density.ckpt-$nsteps.pdf
check_file_exists $logdir/train_1r/thresholds.ckpt-$nsteps.csv
check_file_exists $logdir/train-loss.pdf
check_file_exists $logdir/validation-F1.pdf
for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists $logdir/validation-PvR-$label.pdf
done

check_point=$nsteps
cmd="freeze \
      --context_ms=$context_ms \
      --model_architecture=$architecture \
      --model_parameters='$model_parameters' \
      --start_checkpoint=${logdir}/train_${ireplicates}r/ckpt-$check_point \
      --output_file=${logdir}/train_${ireplicates}r/frozen-graph.ckpt-${check_point}.pb \
      --labels_touse=$labels_touse \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --audio_nchannels=$audio_nchannels \
      --video_frame_rate=$video_frame_rate \
      --video_frame_height=$video_frame_height \
      --video_frame_width=$video_frame_width \
      --video_channels=$video_channels"
echo $cmd &>> $logdir/train_${ireplicates}r/freeze.ckpt-${check_point}.log
eval $cmd &>> $logdir/train_${ireplicates}r/freeze.ckpt-${check_point}.log

check_file_exists $logdir/train_${ireplicates}r/freeze.ckpt-${check_point}.log
check_file_exists $logdir/train_${ireplicates}r/frozen-graph.ckpt-${check_point}.pb

mkdir $repo_path/test/scratch/tutorial-sh/groundtruth-data/round2
cp $repo_path/data/20161207T102314_ch1.wav \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/round2

wavpath_noext=$repo_path/test/scratch/tutorial-sh/groundtruth-data/round2/20161207T102314_ch1
cmd="classify \
      --context_ms=$context_ms \
      --shiftby_ms=$shiftby_ms \
      --model=$logdir/train_${ireplicates}r/frozen-graph.ckpt-${check_point}.pb \
      --model_labels=$logdir/train_${ireplicates}r/labels.txt \
      --wav=${wavpath_noext}.wav \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --audio_nchannels=$audio_nchannels \
      --video_frame_rate=$video_frame_rate \
      --video_frame_height=$video_frame_height \
      --video_frame_width=$video_frame_width \
      --video_channels=$video_channels \
      --deterministic=$deterministic \
      --labels= \
      --prevalences="
echo $cmd &>> ${wavpath_noext}-classify.log
eval $cmd &>> ${wavpath_noext}-classify.log

check_file_exists ${wavpath_noext}-classify.log

for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-${label}.wav
done

cmd="ethogram \
      $logdir train_${ireplicates}r thresholds.ckpt-${check_point}.csv \
      ${wavpath_noext}.wav $audio_tic_rate"
echo $cmd &>> ${wavpath_noext}-ethogram.log
eval $cmd &>> ${wavpath_noext}-ethogram.log

check_file_exists ${wavpath_noext}-ethogram.log
for pr in $(echo $precision_recall_ratios | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-predicted-${pr}pr.csv
done
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv mel-pulse 510 WARNING
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv mel-sine 767 WARNING
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv ambient 124 WARNING

cmd="${detect_plugin}.py\
      ${wavpath_noext}.wav \
      '$detect_parameters' \
      $audio_tic_rate $audio_nchannels"
echo $cmd &>> ${wavpath_noext}-detect.log
eval $cmd &>> ${wavpath_noext}-detect.log

check_file_exists ${wavpath_noext}-detect.log
check_file_exists ${wavpath_noext}-detected.csv
count_lines_with_label ${wavpath_noext}-detected.csv time 1298 ERROR
count_lines_with_label ${wavpath_noext}-detected.csv frequency 179 ERROR

csvfiles=${wavpath_noext}-detected.csv,${wavpath_noext}-predicted-1.0pr.csv
cmd="misses $csvfiles"
echo $cmd &> ${wavpath_noext}-misses.log
eval $cmd &> ${wavpath_noext}-misses.log

check_file_exists ${wavpath_noext}-misses.log
check_file_exists ${wavpath_noext}-missed.csv
count_lines_with_label ${wavpath_noext}-missed.csv other 1569 WARNING

model=train_${ireplicates}r
check_point=$nsteps
kinds_touse=annotated,missed
equalize_ratio=1000
max_sounds=10000
cmd="activations \
      --context_ms=$context_ms \
      --shiftby_ms=$shiftby_ms \
      --video_findfile=$video_findfile_plugin \
      --video_bkg_frames=$video_bkg_frames \
      --data_loader_queuesize=$data_loader_queuesize \
      --data_loader_maxprocs=$data_loader_maxprocs \
      --model_architecture=$architecture \
      --model_parameters='$model_parameters' \
      --start_checkpoint=$logdir/$model/ckpt-$check_point \
      --data_dir=$data_dir \
      --labels_touse=$labels_touse \
      --kinds_touse=$kinds_touse \
      --testing_equalize_ratio=$equalize_ratio \
      --testing_max_sounds=$max_sounds \
      --batch_size=$mini_batch \
      --audio_tic_rate=$audio_tic_rate \
      --nchannels=$audio_nchannels \
      --validation_percentage=0.0 \
      --validation_offset_percentage=0.0 \
      --deterministic=$deterministic \
      --save_activations=True"
echo $cmd &>> $data_dir/activations.log
eval $cmd &>> $data_dir/activations.log

check_file_exists $data_dir/activations.log
check_file_exists $data_dir/activations.npz

groundtruth_directory=$data_dir
these_layers=2,3
pca_fraction_variance_to_retain=1.0
pca_batch_size=0
cluster_algorithm=UMAP
cluster_ndims=3
cluster_parallelize=1
cluster_args=(10 0.1)
cmd="cluster \
      $groundtruth_directory $these_layers \
      $pca_fraction_variance_to_retain $pca_batch_size \
      $cluster_algorithm $cluster_ndims $cluster_parallelize ${cluster_args[@]}"
echo $cmd &>> $data_dir/cluster.log
eval $cmd &>> $data_dir/cluster.log

check_file_exists $data_dir/cluster.log
check_file_exists $data_dir/cluster.npz

cp $repo_path/data/20161207T102314_ch1-annotated-person1.csv \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/round2

logdir=$repo_path/test/scratch/tutorial-sh/omit-one
wavfiles=(PS_20130625111709_ch3.wav 20161207T102314_ch1.wav)
mkdir $logdir
ioffsets=$(seq 0 $(( "${#wavfiles[@]}" - 1 )) )
for ioffset in $ioffsets ; do
  cmd="generalize \
        $context_ms $shiftby_ms \
        $optimizer $learning_rate \
        $audio_read_plugin $audio_read_plugin_kwargs \
        $video_read_plugin $video_read_plugin_kwargs \
        $video_findfile_plugin $video_bkg_frames \
        $data_loader_queuesize $data_loader_maxprocs \
        $architecture '$model_parameters' \
        $logdir $data_dir $labels_touse $kinds_touse \
        $nsteps '$restore_from' $save_and_test_period $mini_batch \
        '$testing_files' $audio_tic_rate $audio_nchannels \
        $video_frame_rate $video_frame_width $video_frame_height $video_channels \
        $batch_seed $weights_seed $deterministic \
        $ioffset ${wavfiles[ioffset]}"
  echo $cmd &>> $logdir/generalize$(( "${ioffset}" + 1 )).log
  eval $cmd &>> $logdir/generalize$(( "${ioffset}" + 1 )).log
done

for ioffset in $ioffsets ; do
  ioffset1=$(( "${ioffset}" + 1 ))
  check_file_exists $logdir/generalize${ioffset1}.log
  check_file_exists $logdir/generalize_${ioffset1}w.log
  check_file_exists $logdir/generalize_${ioffset1}w/ckpt-$nsteps.index
  check_file_exists $logdir/generalize_${ioffset1}w/logits.validation.ckpt-$nsteps.npz
done

cmd="accuracy $logdir $precision_recall_ratios \
      $nprobabilities $accuracy_parallelize"
echo $cmd &>> $logdir/accuracy.log
eval $cmd &>> $logdir/accuracy.log

check_file_exists $logdir/accuracy.log
check_file_exists $logdir/accuracy.pdf
check_file_exists $logdir/confusion-matrices.pdf
for ioffset in $ioffsets ; do
  ioffset1=$(( "${ioffset}" + 1 ))
  check_file_exists $logdir/generalize_${ioffset1}w/precision-recall.ckpt-$nsteps.pdf
  check_file_exists $logdir/generalize_${ioffset1}w/probability-density.ckpt-$nsteps.pdf
  check_file_exists $logdir/generalize_${ioffset1}w/thresholds.ckpt-$nsteps.csv
done
check_file_exists $logdir/train-loss.pdf
check_file_exists $logdir/validation-F1.pdf
for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists $logdir/validation-PvR-$label.pdf
done

nfeaturess=(32,32 64,64)
precision_recall_ratios=1.0
for nfeatures in ${nfeaturess[@]} ; do
  logdir=$repo_path/test/scratch/tutorial-sh/nfeatures-${nfeatures%%,*}
  kfold=2
  ifolds=$(seq 1 $kfold)
  mkdir $logdir
  for ifold in $ifolds ; do
    cmd="xvalidate \
          $context_ms $shiftby_ms \
          $optimizer $learning_rate  \
          $audio_read_plugin $audio_read_plugin_kwargs \
          $video_read_plugin $video_read_plugin_kwargs \
          $video_findfile_plugin $video_bkg_frames \
          $data_loader_queuesize $data_loader_maxprocs \
          $architecture '$model_parameters' \
          $logdir $data_dir $labels_touse $kinds_touse \
          $nsteps '$restore_from' $save_and_test_period $mini_batch \
          '$testing_files' $audio_tic_rate $audio_nchannels \
          $video_frame_rate $video_frame_width $video_frame_height $video_channels \
          $batch_seed $weights_seed $deterministic \
          $kfold $ifold"
    echo $cmd &>> $logdir/xvalidate${ifold}.log
    eval $cmd &>> $logdir/xvalidate${ifold}.log
  done

  for ifold in $ifolds ; do
    check_file_exists $logdir/xvalidate${ifold}.log
    check_file_exists $logdir/xvalidate_${ifold}k.log
    check_file_exists $logdir/xvalidate_${ifold}k/ckpt-$nsteps.index
    check_file_exists $logdir/xvalidate_${ifold}k/logits.validation.ckpt-$nsteps.npz
  done

  cmd="accuracy $logdir $precision_recall_ratios $nprobabilities $accuracy_parallelize"
  echo $cmd &>> $logdir/accuracy.log
  $cmd &>> $logdir/accuracy.log

  check_file_exists $logdir/accuracy.log
  check_file_exists $logdir/accuracy.pdf
  check_file_exists $logdir/confusion-matrices.pdf
  for ifold in $ifolds ; do
    check_file_exists $logdir/xvalidate_${ifold}k/precision-recall.ckpt-$nsteps.pdf
    check_file_exists $logdir/xvalidate_${ifold}k/probability-density.ckpt-$nsteps.pdf
    check_file_exists $logdir/xvalidate_${ifold}k/thresholds.ckpt-$nsteps.csv
  done
  check_file_exists $logdir/train-loss.pdf
  check_file_exists $logdir/validation-F1.pdf
  for label in $(echo $labels_touse | sed "s/,/ /g") ; do
    check_file_exists $logdir/validation-PvR-$label.pdf
  done
done

logdirs_prefix=$repo_path/test/scratch/tutorial-sh/nfeatures
cmd="compare $logdirs_prefix"
echo $cmd &> ${logdirs_prefix}-compare.log
eval $cmd &> ${logdirs_prefix}-compare.log

check_file_exists ${logdirs_prefix}-compare.log
check_file_exists ${logdirs_prefix}-compare-precision-recall.pdf
check_file_exists ${logdirs_prefix}-compare-confusion-matrices.pdf
check_file_exists ${logdirs_prefix}-compare-overall-params-speed.pdf

cmd="mistakes $data_dir"
echo $cmd &> $data_dir/mistakes.log
eval $cmd &> $data_dir/mistakes.log

check_file_exists $data_dir/mistakes.log
check_file_exists $data_dir/round1/PS_20130625111709_ch3-mistakes.csv

logdir=$repo_path/test/scratch/tutorial-sh/trained-classifier2
kinds_touse=annotated
validation_percentage=20
mkdir $logdir
cmd="train \
      $context_ms $shiftby_ms \
      $optimizer $learning_rate  \
      $audio_read_plugin $audio_read_plugin_kwargs \
      $video_read_plugin $video_read_plugin_kwargs \
      $video_findfile_plugin $video_bkg_frames \
      $data_loader_queuesize $data_loader_maxprocs \
      $architecture '$model_parameters' \
      $logdir $data_dir $labels_touse $kinds_touse \
      $nsteps '$restore_from' $save_and_test_period $validation_percentage \
      $mini_batch '$testing_files' \
      $audio_tic_rate $audio_nchannels \
      $video_frame_rate $video_frame_width $video_frame_height $video_channels \
      $batch_seed $weights_seed $deterministic \
      $ireplicates"
echo $cmd &>> $logdir/train1.log
eval $cmd &>> $logdir/train1.log

check_file_exists $logdir/train1.log
check_file_exists $logdir/train_1r.log
check_file_exists $logdir/train_1r/ckpt-$nsteps.index
check_file_exists $logdir/train_1r/logits.validation.ckpt-$nsteps.npz

cmd="accuracy $logdir $precision_recall_ratios $nprobabilities $accuracy_parallelize"
echo $cmd &>> $logdir/accuracy.log
eval $cmd &>> $logdir/accuracy.log

check_file_exists $logdir/accuracy.log
check_file_exists $logdir/accuracy.pdf
check_file_exists $logdir/train_1r/precision-recall.ckpt-$nsteps.pdf
check_file_exists $logdir/train_1r/probability-density.ckpt-$nsteps.pdf
check_file_exists $logdir/train_1r/thresholds.ckpt-$nsteps.csv
check_file_exists $logdir/train-loss.pdf
check_file_exists $logdir/validation-F1.pdf
for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists $logdir/validation-PvR-$label.pdf
done

cmd="freeze \
      --context_ms=$context_ms \
      --model_architecture=$architecture \
      --model_parameters='$model_parameters' \
      --start_checkpoint=${logdir}/train_${ireplicates}r/ckpt-$check_point \
      --output_file=${logdir}/train_${ireplicates}r/frozen-graph.ckpt-${check_point}.pb \
      --labels_touse=$labels_touse \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --audio_nchannels=$audio_nchannels \
      --video_frame_rate=$video_frame_rate \
      --video_frame_height=$video_frame_height \
      --video_frame_width=$video_frame_width \
      --video_channels=$video_channels"
echo $cmd &>> $logdir/train_${ireplicates}r/freeze.ckpt-${check_point}.log
eval $cmd &>> $logdir/train_${ireplicates}r/freeze.ckpt-${check_point}.log

check_file_exists $logdir/train_${ireplicates}r/freeze.ckpt-${check_point}.log
check_file_exists $logdir/train_${ireplicates}r/frozen-graph.ckpt-${check_point}.pb

mkdir $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence
cp $repo_path/data/20190122T093303a-7.wav \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence

wavpath_noext=$repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence/20190122T093303a-7
cmd="classify \
      --context_ms=$context_ms \
      --shiftby_ms=$shiftby_ms \
      --model=$logdir/train_${ireplicates}r/frozen-graph.ckpt-${check_point}.pb \
      --model_labels=$logdir/train_${ireplicates}r/labels.txt \
      --wav=${wavpath_noext}.wav \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --audio_nchannels=$audio_nchannels \
      --video_frame_rate=$video_frame_rate \
      --video_frame_height=$video_frame_height \
      --video_frame_width=$video_frame_width \
      --video_channels=$video_channels \
      --deterministic=$deterministic \
      --labels= \
      --prevalences="
echo $cmd &>> ${wavpath_noext}-classify.log
eval $cmd &>> ${wavpath_noext}-classify.log

check_file_exists ${wavpath_noext}-classify.log

for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-${label}.wav
done

cmd="ethogram \
      $logdir train_${ireplicates}r thresholds.ckpt-${check_point}.csv \
      ${wavpath_noext}.wav $audio_tic_rate"
echo $cmd &>> ${wavpath_noext}-ethogram.log
eval $cmd &>> ${wavpath_noext}-ethogram.log

check_file_exists ${wavpath_noext}-ethogram.log
for pr in $(echo $precision_recall_ratios | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-predicted-${pr}pr.csv
done

wav_file_noext=20190122T093303a-7
cp $repo_path/data/${wav_file_noext}-annotated-person2.csv \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence
cp $repo_path/data/${wav_file_noext}-annotated-person3.csv \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence

portion=union
convolve_ms=0.0
measure=both
cmd="congruence \
      $data_dir ${wav_file_noext}.wav $portion $convolve_ms $measure $nprobabilities \
      $audio_tic_rate $congruence_parallelize"
echo $cmd &>> $data_dir/congruence.log
eval $cmd &>> $data_dir/congruence.log

check_file_exists $data_dir/congruence.log
mv $data_dir/congruence.log $data_dir/congruence
check_file_exists $data_dir/congruence/$wav_file_noext-disjoint-everyone.csv
kinds=(tic label)
persons=(person2 person3)
IFS=', ' read -r -a prs <<< "$precision_recall_ratios"
IFS=', ' read -r -a labels <<< "$labels_touse"
for kind in ${kinds[@]} ; do
  for label in ${labels[@]} ; do
    check_file_exists $data_dir/congruence.${kind}.${label}.csv
    count_lines $data_dir/congruence.${kind}.${label}.csv $(( $nprobabilities + 2 ))
    check_file_exists $data_dir/congruence.${kind}.${label}.pdf
    mv $data_dir/congruence.${kind}.${label}.pdf $data_dir/congruence
    mv $data_dir/congruence.${kind}.${label}.csv $data_dir/congruence
  done
  for pr in ${prs[@]} ; do
    for label in ${labels[@]} ; do
      check_file_exists $data_dir/congruence.${kind}.${label}.${pr}pr-venn.pdf
      check_file_exists $data_dir/congruence.${kind}.${label}.${pr}pr.pdf
      mv $data_dir/congruence.${kind}.${label}.${pr}pr-venn.pdf $data_dir/congruence
      mv $data_dir/congruence.${kind}.${label}.${pr}pr.pdf $data_dir/congruence
    done
    check_file_exists $data_dir/congruence/$wav_file_noext-disjoint-${kind}-not${pr}pr.csv
    check_file_exists $data_dir/congruence/$wav_file_noext-disjoint-${kind}-only${pr}pr.csv
  done
  for person in ${persons[@]} ; do
    check_file_exists $data_dir/congruence/$wav_file_noext-disjoint-${kind}-not${person}.csv
    check_file_exists $data_dir/congruence/$wav_file_noext-disjoint-${kind}-only${person}.csv
  done
done

logdir=${repo_path}/test/scratch/tutorial-sh/nfeatures-64

mkdir ${logdir}/xvalidate_1k,2k
cmd="ensemble \
      --start_checkpoints=${logdir}/xvalidate_1k/ckpt-300,${logdir}/xvalidate_2k/ckpt-300 \
      --output_file=${logdir}/xvalidate_1k,2k/frozen-graph.ckpt-300,300.pb \
      --labels_touse=mel-pulse,mel-sine,ambient \
      --context_ms=$context_ms \
      --model_architecture=$architecture \
      --model_parameters='$model_parameters' \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --nchannels=$audio_nchannels"
echo $cmd &> ${logdir}/xvalidate_1k,2k/ensemble.log
eval $cmd &> ${logdir}/xvalidate_1k,2k/ensemble.log

check_file_exists ${logdir}/xvalidate_1k,2k/ensemble.log
check_file_exists ${logdir}/xvalidate_1k,2k/frozen-graph.ckpt-${check_point},${check_point}.pb/saved_model.pb 

mkdir -p $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence-ensemble
cp $repo_path/data/20190122T132554a-14.wav \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence-ensemble

wavpath_noext=$repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence-ensemble/20190122T132554a-14
cmd="classify \
      --context_ms=$context_ms \
      --shiftby_ms=$shiftby_ms \
      --model=${logdir}/xvalidate_1k,2k/frozen-graph.ckpt-${check_point},${check_point}.pb \
      --model_labels=${logdir}/xvalidate_1k,2k/labels.txt \
      --wav=${wavpath_noext}.wav \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --audio_nchannels=$audio_nchannels \
      --video_frame_rate=$video_frame_rate \
      --video_frame_height=$video_frame_height \
      --video_frame_width=$video_frame_width \
      --video_channels=$video_channels \
      --deterministic=$deterministic \
      --labels= \
      --prevalences="
echo $cmd &>> ${wavpath_noext}-classify.log
eval $cmd &>> ${wavpath_noext}-classify.log

check_file_exists ${wavpath_noext}-classify.log

for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-${label}.wav
done

cmd="ethogram \
      $logdir xvalidate_1k thresholds.ckpt-${check_point}.csv \
      ${wavpath_noext}.wav $audio_tic_rate"
echo $cmd &>> ${wavpath_noext}-ethogram.log
eval $cmd &>> ${wavpath_noext}-ethogram.log

check_file_exists ${wavpath_noext}-ethogram.log
for pr in $(echo $precision_recall_ratios | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-predicted-${pr}pr.csv
done
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv mel-pulse 56 WARNING
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv mel-sine 140 WARNING
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv ambient 70 WARNING

wav_file_noext=20190122T132554a-14
cp $repo_path/data/${wav_file_noext}-annotated-person2.csv \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence-ensemble
cp $repo_path/data/${wav_file_noext}-annotated-person3.csv \
   $repo_path/test/scratch/tutorial-sh/groundtruth-data/congruence-ensemble

cmd="congruence \
      $data_dir ${wav_file_noext}.wav $portion $convolve_ms $measure $nprobabilities \
      $audio_tic_rate $congruence_parallelize"
echo $cmd &>> $data_dir/congruence.log
eval $cmd &>> $data_dir/congruence.log

check_file_exists $data_dir/congruence.log
check_file_exists $data_dir/congruence-ensemble/$wav_file_noext-disjoint-everyone.csv
kinds=(tic label)
persons=(person2 person3)
IFS=', ' read -r -a prs <<< "$precision_recall_ratios"
IFS=', ' read -r -a labels <<< "$labels_touse"
for kind in ${kinds[@]} ; do
  for label in ${labels[@]} ; do
    check_file_exists $data_dir/congruence.${kind}.${label}.csv
    count_lines $data_dir/congruence.${kind}.${label}.csv $(( $nprobabilities + 2 ))
    check_file_exists $data_dir/congruence.${kind}.${label}.pdf
  done
  for pr in ${prs[@]} ; do
    for label in ${labels[@]} ; do
      check_file_exists $data_dir/congruence.${kind}.${label}.${pr}pr-venn.pdf
      check_file_exists $data_dir/congruence.${kind}.${label}.${pr}pr.pdf
    done
    check_file_exists $data_dir/congruence-ensemble/$wav_file_noext-disjoint-${kind}-not${pr}pr.csv
    check_file_exists $data_dir/congruence-ensemble/$wav_file_noext-disjoint-${kind}-only${pr}pr.csv
  done
  for person in ${persons[@]} ; do
    check_file_exists $data_dir/congruence-ensemble/$wav_file_noext-disjoint-${kind}-not${person}.csv
    check_file_exists $data_dir/congruence-ensemble/$wav_file_noext-disjoint-${kind}-only${person}.csv
  done
done

wavpath_noext=$repo_path/test/scratch/tutorial-sh/groundtruth-data/round1/PS_20130625111709_ch3
cmd="classify \
      --context_ms=$context_ms \
      --shiftby_ms=$shiftby_ms \
      --model=${logdir}/xvalidate_1k,2k/frozen-graph.ckpt-${check_point},${check_point}.pb \
      --model_labels=${logdir}/xvalidate_1k,2k/labels.txt \
      --wav=${wavpath_noext}.wav \
      --parallelize=$classify_parallelize \
      --audio_tic_rate=$audio_tic_rate \
      --audio_nchannels=$audio_nchannels \
      --video_frame_rate=$video_frame_rate \
      --video_frame_height=$video_frame_height \
      --video_frame_width=$video_frame_width \
      --video_channels=$video_channels \
      --deterministic=$deterministic \
      --labels= \
      --prevalences="
echo $cmd &>> ${wavpath_noext}-classify.log
eval $cmd &>> ${wavpath_noext}-classify.log

check_file_exists ${wavpath_noext}-classify.log

for label in $(echo $labels_touse | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-${label}.wav
done

thresholds_dense_file=$(basename $(ls ${logdir}/xvalidate_1k/thresholds-dense-*))
mv ${logdir}/xvalidate_1k/${thresholds_dense_file} ${logdir}/xvalidate_1k,2k

cmd="ethogram \
      $logdir xvalidate_1k,2k ${thresholds_dense_file} \
      ${wavpath_noext}.wav $audio_tic_rate"
echo $cmd &>> ${wavpath_noext}-ethogram.log
eval $cmd &>> ${wavpath_noext}-ethogram.log

check_file_exists ${wavpath_noext}-ethogram.log
for pr in $(echo $precision_recall_ratios | sed "s/,/ /g") ; do
  check_file_exists ${wavpath_noext}-predicted-${pr}pr.csv
done
count_lines_with_label ${wavpath_noext}-predicted-1.0pr.csv mel-pulse 594 WARNING
