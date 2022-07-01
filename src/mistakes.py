#!/usr/bin/env python3

# record whether annotations where correctly or mistakenly classified
 
# mistakes.py <path-to-annotations-npz-file>

# e.g.
# mistakes.py `pwd`/groundtruth-data

import os
import numpy as np
import sys
from sys import argv
from natsort import natsorted
import csv
from datetime import datetime
import socket

repodir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

print(str(datetime.now())+": start time")
with open(os.path.join(repodir, "VERSION.txt"), 'r') as fid:
  print('SongExplorer version = '+fid.read().strip().replace('\n',', '))
print("hostname = "+socket.gethostname())

try:

  _, groundtruth_directory = argv
  print('groundtruth_directory: '+groundtruth_directory)

  npzfile = np.load(os.path.join(groundtruth_directory, 'activations.npz'),
                    allow_pickle=True)
  sounds = npzfile['sounds']
  arr_ = natsorted(filter(lambda x: x.startswith('arr_'), npzfile.files))
  logits = npzfile[arr_[-1]]
  labels = list(npzfile['labels'])

  isort = [x for x,y in sorted(enumerate(sounds), key = lambda x: x[1]['ticks'][0])]

  fids = []
  csvwriters = {}
  for idx in isort:
    wavroot,_ = os.path.splitext(sounds[idx]['file'])
    if wavroot not in csvwriters:
      fids.append(open(os.path.join(groundtruth_directory, wavroot+'-mistakes.csv'),
                       'w', newline=''))
      csvwriters[wavroot] = csv.writer(fids[-1])
    classified_as = np.argmax(logits[idx])
    annotated_as = labels.index(sounds[idx]['label'])
    csvwriters[wavroot].writerow([os.path.basename(sounds[idx]['file']),
          sounds[idx]['ticks'][0], sounds[idx]['ticks'][1],
          'correct' if classified_as == annotated_as else 'mistaken',
          labels[classified_as],
          sounds[idx]['label']])

  for fid in fids:
    fid.close()

except Exception as e:
  print(e)

finally:
  os.sync()
  print(str(datetime.now())+": finish time")
