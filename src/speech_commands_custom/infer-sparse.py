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
r"""
run just the forward pass of model on the test set
"""
import argparse
import os.path
import sys

import numpy as np
import tensorflow as tf

import input_data
import models

import datetime as dt

import json

import importlib

FLAGS = None


def main():
  sys.path.append(os.path.dirname(FLAGS.model_architecture))
  model = importlib.import_module(os.path.basename(FLAGS.model_architecture))

  flags = vars(FLAGS)
  for key in sorted(flags.keys()):
    print('%s = %s' % (key, flags[key]))

  for physical_device in tf.config.experimental.list_physical_devices('GPU'):
    tf.config.experimental.set_memory_growth(physical_device, True)
  tf.config.set_soft_device_placement(True)

  label_file = os.path.join(os.path.dirname(FLAGS.start_checkpoint), "labels.txt")
  with open(label_file) as fid:
    labels = []
    for line in fid:
      labels.append(line.rstrip())
    nlabels = len(labels)

  model_settings = models.prepare_model_settings(
      nlabels,
      FLAGS.audio_tic_rate,
      FLAGS.nchannels,
      1,
      FLAGS.batch_size,
      FLAGS.context_ms,
      FLAGS.representation,
      FLAGS.window_ms, FLAGS.stride_ms,
      FLAGS.dct_ncoefficients, FLAGS.filterbank_nchannels,
      FLAGS.model_parameters)

  audio_processor = input_data.AudioProcessor(
      FLAGS.data_dir,
      FLAGS.shiftby_ms,
      FLAGS.labels_touse.split(','), FLAGS.kinds_touse.split(','),
      FLAGS.validation_percentage, FLAGS.validation_offset_percentage,
      FLAGS.validation_files.split(','),
      100, FLAGS.testing_files.split(','), FLAGS.subsample_skip,
      FLAGS.subsample_label,
      FLAGS.partition_label, FLAGS.partition_n, FLAGS.partition_training_files.split(','),
      FLAGS.partition_validation_files.split(','),
      -1,
      FLAGS.testing_equalize_ratio, FLAGS.testing_max_sounds,
      model_settings)

  thismodel = model.create_model(model_settings)
  thismodel.summary()

  checkpoint = tf.train.Checkpoint(thismodel=thismodel)
  checkpoint.read(FLAGS.start_checkpoint)

  time_shift_tics = int((FLAGS.shiftby_ms * FLAGS.audio_tic_rate) / 1000)

  testing_set_size = audio_processor.set_size('testing')

  def infer_step(isound):
    fingerprints, _, sounds = audio_processor.get_data(
                                 FLAGS.batch_size, isound, model_settings,
                                 time_shift_tics, 'testing')
    needed = FLAGS.batch_size - fingerprints.shape[0]
    hidden_activations, logits = thismodel(fingerprints, training=False)
    return fingerprints, sounds, needed, logits, hidden_activations

  for isound in range(0, testing_set_size, FLAGS.batch_size):
    fingerprints, sounds, needed, logits, hidden_activations = infer_step(isound)
    obtained = FLAGS.batch_size - needed
    if isound==0:
      sounds_data = [None]*testing_set_size
    sounds_data[isound:isound+obtained] = sounds
    if FLAGS.save_activations:
      if isound==0:
        activations = []
        for ihidden in range(len(hidden_activations)):
          nHWC = np.shape(hidden_activations[ihidden])[1:]
          activations.append(np.empty((testing_set_size, *nHWC)))
        activations.append(np.empty((testing_set_size, np.shape(logits)[2])))
      for ihidden in range(len(hidden_activations)):
        activations[ihidden][isound:isound+obtained,...] = \
              hidden_activations[ihidden]
      activations[-1][isound:isound+obtained,...] = logits[:,0,:]
    if FLAGS.save_fingerprints:
      if isound==0:
        nHWC = np.shape(fingerprints)[1:]
        input_layer = np.empty((testing_set_size, *nHWC))
      input_layer[isound:isound+obtained,...] = fingerprints
  if FLAGS.save_activations:
    np.savez(os.path.join(FLAGS.data_dir,'activations.npz'), \
             *activations, sounds=sounds_data, labels=labels)
  if FLAGS.save_fingerprints:
    np.save(os.path.join(FLAGS.data_dir,'fingerprints.npy'), input_layer)

def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--data_dir',
      type=str,
      default='/tmp/speech_dataset/',
      help="""\
      Where to download the speech training data to.
      """)
  parser.add_argument(
      '--shiftby_ms',
      type=float,
      default=100.0,
      help="""\
      Range to shift the training audio by in time.
      """)
  parser.add_argument(
      '--testing_files',
      type=str,
      default='',
      help='Which wav files to use as a test set.')
  parser.add_argument(
      '--subsample_label',
      type=str,
      default='',
      help='Train on only a subset of annotations for this label.')
  parser.add_argument(
      '--subsample_skip',
      type=str,
      default='',
      help='Take only every Nth annotation for the specified label.')
  parser.add_argument(
      '--partition_label',
      type=str,
      default='',
      help='Train on only a fixed number of annotations for this label.')
  parser.add_argument(
      '--partition_n',
      type=int,
      default=0,
      help='Train on only this number of annotations from each file for the specified label.')
  parser.add_argument(
      '--partition_training_files',
      type=str,
      default='',
      help='Train on only these files for the specified label.')
  parser.add_argument(
      '--partition_validation_files',
      type=str,
      default='',
      help='Validate on only these files for the specified label.')
  parser.add_argument(
      '--validation_files',
      type=str,
      default='',
      help='Which wav files to use as a validation set.')
  parser.add_argument(
      '--validation_percentage',
      type=float,
      default=10,
      help='What percentage of wavs to use as a validation set.')
  parser.add_argument(
      '--validation_offset_percentage',
      type=float,
      default=0,
      help='Which wavs to use as a cross-validation set.')
  parser.add_argument(
      '--audio_tic_rate',
      type=int,
      default=16000,
      help='Expected tic rate of the wavs',)
  parser.add_argument(
      '--nchannels',
      type=int,
      default=1,
      help='Expected number of channels in the wavs',)
  parser.add_argument(
      '--context_ms',
      type=float,
      default=1000,
      help='Expected duration in milliseconds of the wavs',)
  parser.add_argument(
      '--window_ms',
      type=float,
      default=30.0,
      help='How long each spectrogram timeslice is.',)
  parser.add_argument(
      '--stride_ms',
      type=float,
      default=10.0,
      help='How far to move in time between spectogram timeslices.',)
  parser.add_argument(
      '--filterbank_nchannels',
      type=int,
      default=40,
      help='How many internal bins to use for the MFCC fingerprint',)
  parser.add_argument(
      '--dct_ncoefficients',
      type=int,
      default=40,
      help='How many output bins to use for the MFCC fingerprint',)
  parser.add_argument(
      '--batch_size',
      type=int,
      default=100,
      help='How many items to train with at once',)
  parser.add_argument(
      '--labels_touse',
      type=str,
      default='yes,no,up,down,left,right,on,off,stop,go',
      help='Words to use (others will be added to an unknown label)',)
  parser.add_argument(
      '--kinds_touse',
      type=str,
      default='annotated,classified',
      help='A comma-separted list of "annotated", "detected" , or "classified"',)
  parser.add_argument(
      '--start_checkpoint',
      type=str,
      default='',
      help='If specified, restore this pretrained model before any training.')
  parser.add_argument(
      '--testing_equalize_ratio',
      type=int,
      default=0,
      help='Limit most common label to be no more than this times more than the least common label for testing.')
  parser.add_argument(
      '--testing_max_sounds',
      type=int,
      default=0,
      help='Limit number of test sounds to this number.')
  parser.add_argument(
      '--representation',
      type=str,
      default='waveform',
      help='What input representation to use.  One of waveform, spectrogram, or mel-cepstrum.')
  parser.add_argument(
      '--optimizer',
      type=str,
      default='sgd',
      help='What optimizer to use.  One of Adadelta, Adagrad, Adam, Adamax, Ftrl, Nadam, RMSProp, or SGD.')
  parser.add_argument(
      '--model_architecture',
      type=str,
      default='conv',
      help='What model architecture to use')
  parser.add_argument(
      '--model_parameters',
      type=json.loads,
      default='{}',
      help='What model parameters to use')
  parser.add_argument(
      '--save_activations',
      type=str2bool,
      default=False,
      help='Whether to save hidden layer activations during processing')
  parser.add_argument(
      '--save_fingerprints',
      type=str2bool,
      default=False,
      help='Whether to save fingerprint input layer during processing')

  FLAGS, unparsed = parser.parse_known_args()
  main()
