## Setup Gromacs simulations for any system (currently Protein, DNA, RNA systems are supported in apo or in complex forms)
This repository contains my scripts to submit molecular dynamics simulations for Gromacs  
All scripts assume a version of Gromacs is installed and callable using 'gmx'  
For complex (ligand-bound) systems, the scripts assume the LIG.gro and LIG.itp files were prepared using other tools  
Recommended: antechamber from AmberTools (explained below using acpype)

### Install acpype (python wrapper of antechamber) using conda
  conda create -n acpype-env  
  conda activate acpype-env  
  conda install -c conda-forge acpype  
