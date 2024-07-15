# ReservoirsMaxBenefit
Code and data availability for the paper entitled, "Is drought protection possible without compromising flood protection? Estimating the maximum dual-use benefit of small flood reservoirs in Southern Germany" by Sarah Quynh-Giang Ho and Uwe Ehret.

The reservoir data (stored as a MATLAB cell array of objects) can be downloaded at the following link:
https://1drv.ms/u/c/4f2682a81239ef03/EdkKO_0maxJAs6dfJ-jK7IYBBweiQSr8kQrXeeI_89Tyfw?e=JenkDn
(Alternatively, try this DOI: 10.35097/bRpwFBSdUxSzPdfr)

In order to properly load the reservoir data, the classdef file hrb.m must be added to the path. This file also contains most of the functions needed for the model:
  - calcMinFlow          - calculates Q70 (and additionally Q80 and Q95)
  - floodOptModel        - runs the flood-only model, which also calculates the default penalty
  - optModel             - runs the combined flood-and-drought model at a given Qr

hrb.m also contains other functions for analysis, such as
  - calcBaseStats        - calculates the total time, volume (deficit for droughts, flooding for floods), and penalty for the optimized value
  - calcRF               - calculates the storage factor (in German: Rueckhaltefaktor) of the reservoir using the capacity and the inflow time series
  - penaltyRidgePlot     - shows the monthly distributions of penalties and deficits for each reservoir 
  - plotFloodOptModel    - plots the results of a flood-only model
  - plotVQP              - plots the discharge, volume, and penalty in the style of figures 5-9

In addition to the hrb.m, there are several other scripts / functions included in this package:
  - applyAllReservoirs.m - runs the entire workflow in the proper order (calculates Q70, then runs the flood model, then runs the optimization process, then several analysis functions) for all reservoirs in the cell array
  - multiOptModel.m      - runs the combined optimization model for a given number of test Qrs and stores the results in a new matrix
  - resultPlotting.m     - contains all the scripts for plotting figures 4 and 10-14
