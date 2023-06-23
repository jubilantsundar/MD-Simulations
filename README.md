## Setup Gromacs simulations for any system (currently Protein, DNA, RNA systems are supported in apo or in complex forms)
This repository contains my scripts to submit molecular dynamics simulations for Gromacs  
***MD job submission script provided here assumes a recent version of Gromacs is installed and it is callable using 'gmx'***  

For complex (ligand-bound) systems, the scripts assume the LIG.gro and LIG.itp files were prepared using other tools  
***Recommended: antechamber from AmberTools (explained below using acpype)***

## Step 1. System preparation
  1. Preparing protein or DNA or RNA as a pdb file (without ligand). We will assemble them later.
     Every system is different which needs some tweaking in the mdp files provided. Understand your system first.
  3. Prepare the extracted ligand as LIG.sdf or LIG.mol2  
     This also may require some additional options to match your ligand. Eg. charged ligands need some special care.

## Step 2. Obtain ligand parameters
### Install acpype (python wrapper of antechamber) using conda
  ```conda create -n acpype-env```  
  ```conda activate acpype-env```  
  ```conda install -c conda-forge acpype```  

### Obtain ligand parameters using acpype
  ```acpype -i LIG.sdf (LIG.mol2)```  ## Make sure your ligand file is named LIG.sdf or LIG.mol2 and the name inside the file is LIG as well

## Step 3. Run MD simulation
  Install Gromacs if not installed already following instructions here https://manual.gromacs.org/current/install-guide/index.html  
  Download all mdp files and keep them in local folder where MD_SETUP_AUTO.sh is located.  
  ```./MD_SETUP_AUTO.sh complex input.pdb LIG.acpype/LIG_GMX.gro LIG.acpype/LIG_GMX.itp 5000000 prod RNA_LIG```  

  Usage: ```./SETUP.sh apo/complex input.pdb ligand_gro_file ligand_itp_file simulation_length_in_ps prep/prod Protein/DNA/RNA```  
  &nbsp;&nbsp;&nbsp;prep: runs em, nvt, npt runs and prepares an md.tpr for SLURM  
  &nbsp;&nbsp;&nbsp;prod: runs em, nvt, npt and md production run for given time in ns  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Eg. for complex system: ```./SETUP.sh complex input.pdb LIG.acpype/LIG_GMX.gro LIG.acpype/LIG_GMX.itp 5000000 prod RNA_LIG```  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Eg. for apo system: ```./SETUP.sh apo input.pdb . . 5000000 prod RNA```  

## Caveats
***Error handling:*** In its current form, the whole script goes through agnostic to where the first error occurred. User need to trace the errors and address it. Future versions may address this with better error handling.

## Thanks
