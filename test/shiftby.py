#!/usr/bin/env python3

# see test/shiftby.sh

import sys
import os
import numpy as np

repo_path = os.path.dirname(sys.path[0])

fingerprints0 = np.load(os.path.join(repo_path,
                                     "test/scratch/shiftby/shiftby-0.0/train_1r/fingerprints.validation.ckpt-10.npz"),
                        allow_pickle=True)
fingerprints512 = np.load(os.path.join(repo_path,
                                       "test/scratch/shiftby/shiftby-51.2/train_1r/fingerprints.validation.ckpt-10.npz"),
                          allow_pickle=True)

shiftby = round(51.2/1000*2500)
for isound in range(np.shape(fingerprints0['arr_0'])[0]):
  if not all(fingerprints0['arr_0'][isound,:-shiftby,0] == fingerprints512['arr_0'][isound,shiftby:,0]):
    print("ERROR: traces are not shifted properly")
  if all(fingerprints512['arr_0'][isound,:-shiftby,0]==0):
    print("ERROR: shifted traces appear to be zero padded")
