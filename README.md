#PFC Models
This repository contains a collection of neural models for prefrontal cortical (PFC) cells and networks.

Download the repo on github or using git: `git clone https://github.com/jsherfey/PFC_models.git`

All models are implemented in the DynaSim Matlab toolbox: https://github.com/DynaSim/DynaSim

To get started with individual PFC cell models, see `PFC_cells_explicit`. To get started with PFC network models, see `PFC_1layer` and `PFC_2layers`.

The PFC network model is based on a simpler one with pyramidal cells and fast-spiking interneurons by Durstewitz et al. Matlab implementations of 2002 and 2007 versions of the original model and references can be found in the "Durstewitz" folder in `DS02_PFC_deep` and `DG07_PFC_deep`, respectively.

The model by Jason Sherfey consists of cells from the Durstewitz model as well as others. DynaSim implementations of each cell model, references, and supplemental info can be found in `PFC_cells_explicit`. `get_PFC_cell` is a function that can be used to retrieve DynaSim specifications of individual cell models. Similarly, `PFC_1layer` and `get_PFC_1layer` are script and function forms of a single-layer PFC model with pyramidal cells, PV+ FS cells, and CB+ RSNP cells. 

`PFC_2layers` is a script that constructs a two-layer PFC model representing minimal superficial and deep layers.
`PFC_competition` defines two assemblies in a single-layer PFC network and probes how they compete when they are driven by inputs with varying rhythmicity and synchrony.

------------------------------------------------------------

To install DynaSim using Git: `git clone https://github.com/dynasim/dynasim.git`
Add the dynasim toolbox to Matlab path and run model scripts from the directory containing them.

