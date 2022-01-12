#This file, originally from the TensorFlow speech recognition tutorial,
#has been heavily modified for use by SongExplorer.


# Copyright 2017 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
"""Model definitions for simple speech recognition.

"""
import hashlib
import math
import os.path
import random
import re
import sys
import tarfile
import csv
import scipy.io.wavfile as spiowav

import numpy as np
import tensorflow as tf

MAX_NUM_WAVS_PER_CLASS = 2**27 - 1  # ~134M


def which_set(filename, validation_percentage, validation_offset_percentage, testing_percentage):
  """Determines which data partition the file should belong to.

  We want to keep files in the same training, validation, or testing sets even
  if new ones are added over time. This makes it less likely that testing
  sounds will accidentally be reused in training when long runs are restarted
  for example. To keep this stability, a hash of the filename is taken and used
  to determine which set it should belong to. This determination only depends on
  the name and the set proportions, so it won't change as other files are added.

  It's also useful to associate particular files as related (for example words
  spoken by the same person), so anything after '_nohash_' in a filename is
  ignored for set determination. This ensures that 'bobby_nohash_0.wav' and
  'bobby_nohash_1.wav' are always in the same set, for example.

  Args:
    filename: File path of the sound.
    validation_percentage: How much of the data set to use for validation.
    validation_offset_percentage: Which part of the data set to use for validation.
    testing_percentage: How much of the data set to use for testing.

  Returns:
    String, one of 'training', 'validation', or 'testing'.
  """
  base_name = os.path.basename(filename)
  # We want to ignore anything after '_nohash_' in the file name when
  # deciding which set to put a wav in, so the data set creator has a way of
  # grouping wavs that are close variations of each other.
  hash_name = re.sub(r'_nohash_.*$', '', base_name)
  # This looks a bit magical, but we need to decide whether this file should
  # go into the training, testing, or validation sets, and we want to keep
  # existing files in the same set even if more files are subsequently
  # added.
  # To do that, we need a stable way of deciding based on just the file name
  # itself, so we do a hash of that and then use that to generate a
  # probability value that we use to assign it.
  hash_name_hashed = hashlib.sha1(tf.compat.as_bytes(hash_name)).hexdigest()
  percentage_hash = ((int(hash_name_hashed, 16) %
                      (MAX_NUM_WAVS_PER_CLASS + 1)) *
                     (100.0 / MAX_NUM_WAVS_PER_CLASS))
  if percentage_hash < testing_percentage:
    result = 'testing'
  elif percentage_hash > (testing_percentage + validation_offset_percentage) and \
       percentage_hash < (testing_percentage + validation_offset_percentage + validation_percentage):
    result = 'validation'
  else:
    result = 'training'
  return result


class AudioProcessor(object):
  """Handles loading, partitioning, and preparing audio training data."""

  def __init__(self, data_dir,
               shiftby_ms,
               labels_touse, kinds_touse,
               validation_percentage, validation_offset_percentage, validation_files,
               testing_percentage, testing_files, subsample_skip, subsample_label,
               partition_label, partition_n, partition_training_files, partition_validation_files,
               random_seed_batch,
               testing_equalize_ratio, testing_max_sounds, model_settings):
    self.data_dir = data_dir
    random.seed(None if random_seed_batch==-1 else random_seed_batch)
    np.random.seed(None if random_seed_batch==-1 else random_seed_batch)
    self.prepare_data_index(shiftby_ms,
                            labels_touse, kinds_touse,
                            validation_percentage, validation_offset_percentage, validation_files,
                            testing_percentage, testing_files, subsample_skip, subsample_label,
                            partition_label, partition_n, partition_training_files, partition_validation_files,
                            testing_equalize_ratio, testing_max_sounds,
                            model_settings)


  def prepare_data_index(self,
                         shiftby_ms,
                         labels_touse, kinds_touse,
                         validation_percentage, validation_offset_percentage, validation_files,
                         testing_percentage, testing_files, subsample_skip, subsample_label,
                         partition_label, partition_n, partition_training_files, partition_validation_files,
                         testing_equalize_ratio, testing_max_sounds,
                         model_settings):
    """Prepares a list of the sounds organized by set and label.

    The training loop needs a list of all the available data, organized by
    which partition it should belong to, and with ground truth labels attached.
    This function analyzes the folders below the `data_dir`, figures out the
    right
    labels for each file based on the name of the subdirectory it belongs to,
    and uses a stable hash to assign it to a data set partition.

    Args:
      labels_touse: Labels of the classes we want to be able to recognize.
      validation_percentage: How much of the data set to use for validation.
      validation_offset_percentage: Which part of the data set to use for validation.
      testing_percentage: How much of the data set to use for testing.

    Returns:
      Dictionary containing a list of file information for each set partition,
      and a lookup map for each class to determine its numeric index.

    Raises:
      Exception: If expected files are not found.
    """
    shiftby_tics = int((shiftby_ms * model_settings["audio_tic_rate"]) / 1000)
    # Make sure the shuffling is deterministic.
    labels_touse_index = {}
    for index, label_touse in enumerate(labels_touse):
      labels_touse_index[label_touse] = index
    self.data_index = {'validation': [], 'testing': [], 'training': []}
    all_labels = {}
    # Look through all the subfolders to find sounds
    context_tics = model_settings['context_tics']
    search_path = os.path.join(self.data_dir, '*', '*.csv')
    wav_ntics = {}
    subsample = {x:int(y) for x,y in zip(subsample_label.split(','),subsample_skip.split(','))
                          if x != ''}
    partition_labels = partition_label.split(',')
    if '' in partition_labels:
      partition_labels.remove('')
    for csv_path in tf.io.gfile.glob(search_path):
      annotation_reader = csv.reader(open(csv_path))
      annotation_list = list(annotation_reader)
      if len(partition_labels)>0:
        random.shuffle(annotation_list)
      for (iannotation, annotation) in enumerate(annotation_list):
        wavfile=annotation[0]
        ticks=[int(annotation[1]),int(annotation[2])]
        kind=annotation[3]
        label=annotation[4]
        if kind not in kinds_touse:
          continue
        wav_path=os.path.join(os.path.dirname(csv_path),wavfile)
        wav_base2=os.path.join(os.path.basename(os.path.dirname(csv_path)), wavfile)
        if label in subsample and iannotation % subsample[label] != 0:
          continue
        if label in partition_labels:
          if wavfile not in partition_training_files and \
             wavfile not in partition_validation_files:
            continue
          if wavfile in partition_training_files and \
             sum([x['label']==label and x['file']==wav_base2 \
                  for x in self.data_index['training']]) >= partition_n:
            continue
        if wav_path not in wav_ntics:
          audio_tic_rate, song = spiowav.read(wav_path, mmap=True)
          if audio_tic_rate != model_settings['audio_tic_rate']:
            print('ERROR: audio_tic_rate is set to %d in configuration.sh but is actually %d in %s' % (model_settings['audio_tic_rate'], audio_tic_rate, wav_path))
          if np.ndim(song)==1:
            song = np.expand_dims(song, axis=1)
          if np.shape(song)[1] != model_settings['nchannels']:
            print('ERROR: nchannels is set to %d in configuration.sh but is actually %d in %s' % (model_settings['nchannels'], np.shape(song)[1], wav_path))
          wav_ntics[wav_path] = len(song)
        ntics = wav_ntics[wav_path]
        if ticks[0] < context_tics//2 + shiftby_tics or \
           ticks[1] > (ntics - context_tics//2 + shiftby_tics):
          continue
        all_labels[label] = True
        if wavfile in validation_files:
          set_index = 'validation'
        elif wavfile in testing_files:
          set_index = 'testing'
        elif label in partition_labels:
          if wavfile in partition_validation_files:
            set_index = 'validation'
          elif wavfile in partition_training_files:
            set_index = 'training'
          else:
            continue
        else:
          set_index = which_set(annotation[0]+annotation[1]+annotation[2],
                                validation_percentage, validation_offset_percentage, \
                                testing_percentage)
        # If it's a known class, store its detail
        if label in labels_touse_index:
          self.data_index[set_index].append({'label': label,
                                             'file': wav_base2, \
                                             'ticks': ticks,
                                             'kind': kind})
    if not all_labels:
      print('WARNING: No labels to use found in labels')
    if validation_percentage+testing_percentage<100:
      for index, label_touse in enumerate(labels_touse):
        if label_touse not in all_labels:
          print('WARNING: '+label_touse+' not in labels')
    # equalize
    for set_index in ['validation', 'testing', 'training']:
      print('num %s labels' % set_index)
      labels = [sound['label'] for sound in self.data_index[set_index]]
      if set_index != 'testing':
        for uniqlabel in sorted(set(labels)):
          print('%8d %s' % (sum([label==uniqlabel for label in labels]), uniqlabel))
      if set_index == 'validation' or len(self.data_index[set_index])==0:
        continue
      label_indices = {}
      for isound in range(len(self.data_index[set_index])):
        sound = self.data_index[set_index][isound]
        if sound['label'] in label_indices:
          label_indices[sound['label']].append(isound)
        else:
          label_indices[sound['label']]=[isound]
      if set_index == 'training':
        sounds_largest = max([len(label_indices[x]) for x in label_indices.keys()])
        for label in sorted(list(label_indices.keys())):
          sounds_have = len(label_indices[label])
          sounds_needed = sounds_largest - sounds_have
          for _ in range(sounds_needed):
            add_this = label_indices[label][random.randrange(sounds_have)]
            self.data_index[set_index].append(self.data_index[set_index][add_this])
      elif set_index == 'testing':
        if testing_equalize_ratio>0:
          sounds_smallest = min([len(label_indices[x]) for x in label_indices.keys()])
          del_these = []
          for label in sorted(list(label_indices.keys())):
            sounds_have = len(label_indices[label])
            sounds_needed = min(sounds_have, testing_equalize_ratio * sounds_smallest)
            if sounds_needed<sounds_have:
              del_these.extend(random.sample(label_indices[label], \
                               sounds_have-sounds_needed))
          for i in sorted(del_these, reverse=True):
            del self.data_index[set_index][i]
        if testing_max_sounds>0 and testing_max_sounds<len(self.data_index[set_index]):
          self.data_index[set_index] = random.sample(self.data_index[set_index], \
                                                     testing_max_sounds)
      if set_index == 'testing':
        labels = [sound['label'] for sound in self.data_index[set_index]]
        for uniqlabel in sorted(set(labels)):
          print('%7d %s' % (sum([label==uniqlabel for label in labels]), uniqlabel))
    # Make sure the ordering is random.
    for set_index in ['validation', 'testing', 'training']:
      random.shuffle(self.data_index[set_index])
    # Prepare the rest of the result data structure.
    self.labels_list = labels_touse
    self.label_to_index = {}
    for label in all_labels:
      if label in labels_touse_index:
        self.label_to_index[label] = labels_touse_index[label]

  def set_size(self, mode):
    """Calculates the number of sounds in the dataset partition.

    Args:
      mode: Which partition, must be 'training', 'validation', or 'testing'.

    Returns:
      Number of sounds in the partition.
    """
    return len(self.data_index[mode])

  def get_data(self, how_many, offset, model_settings, 
               shiftby_ms, mode):
    """Gather sounds from the data set, applying transformations as needed.

    When the mode is 'training', a random selection of sounds will be returned,
    otherwise the first N clips in the partition will be used. This ensures that
    validation always uses the same sounds, reducing noise in the metrics.

    Args:
      how_many: Desired number of sounds to return. -1 means the entire
        contents of this partition.
      offset: Where to start when fetching deterministically.
      model_settings: Information about the current model being trained.
      time_shift: How much to randomly shift the clips by in time.
      mode: Which partition to use, must be 'training', 'validation', or
        'testing'.
      sess: TensorFlow session that was active when processor was created.

    Returns:
      List of sound data for the transformed sounds, and list of label indexes
    """
    shiftby_tics = int((shiftby_ms * model_settings["audio_tic_rate"]) / 1000)
    # Pick one of the partitions to choose sounds from.
    candidates = self.data_index[mode]
    ncandidates = len(candidates)
    if how_many == -1:
      nsounds = ncandidates
    else:
      nsounds = max(0, min(how_many, ncandidates - offset))
    sounds = []
    context_tics = model_settings['context_tics']
    nchannels = model_settings['nchannels']
    pick_deterministically = (mode != 'training')
    foreground_indexed = np.zeros((nsounds, context_tics, nchannels),
                                  dtype=np.float32)
    labels = np.zeros(nsounds, dtype=np.int)
    # repeatedly to generate the final output sound data we'll use in training.
    for i in range(offset, offset + nsounds):
      # Pick which sound to use.
      if how_many == -1 or pick_deterministically:
        isound = i
      else:
        isound = np.random.randint(ncandidates)
      sound = candidates[isound]

      foreground_offset = (np.random.randint(sound['ticks'][0], 1+sound['ticks'][1]) if
            sound['ticks'][0] < sound['ticks'][1] else sound['ticks'][0])
      wavpath = os.path.join(self.data_dir, sound['file'])
      audio_tic_rate, song = spiowav.read(wavpath, mmap=True)
      if np.ndim(song)==1:
        song = np.expand_dims(song, axis=1)
      foreground_clipped = song[foreground_offset-math.floor(context_tics/2) - shiftby_tics :
                                foreground_offset+math.ceil(context_tics/2) - shiftby_tics,
                                :]
      foreground_float32 = foreground_clipped.astype(np.float32)
      foreground_indexed[i - offset,:,:] = foreground_float32 / abs(np.iinfo(np.int16).min)
      label_index = self.label_to_index[sound['label']]
      labels[i - offset] = label_index
      sounds.append(sound)
    # Run the graph to produce the output audio.
    return foreground_indexed, labels, sounds
