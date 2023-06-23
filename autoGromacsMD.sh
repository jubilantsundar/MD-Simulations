source /usr/local/gromacs/bin/GMXRC

if [ $# -lt 7 ]; then
   echo "###############################################################################################################"
   echo "No arguments supplied"
   echo "Usage: ./SETUP.sh apo/complex input.pdb ligand_gro_file ligand_itp_file simulation_length_in_ps prep/prod Protein/DNA/RNA"
   echo " prep: runs em, nvt, npt runs and generates md.tpr for SLURM"
   echo " prod: runs em, nvt, npt and md production run for given time in ns"
   echo "  Example for complex system: ./SETUP.sh complex input.pdb lig.gro lig.itp 5000000 prod RNA_LIG"
   echo "  Example for apo system: ./SETUP.sh apo input.pdb . . 5000000 prod RNA"
   echo "Make sure the name of the ligand is LIG inside LIG.sdf or LIG.mol2 while prepping parameter files using acpype"
   echo "***Author: Sundar Jubilant***"
   echo "***email: jubilantsundar(at)gmail(dot)com***"
   echo "###############################################################################################################"

else

   if [ $1 == "complex" ]; then

      echo "*************************"
      echo "Preparing a $7 complex system!"
      cp /data/work/projects/*.mdp .
      cp /data/work/projects/combineGro_prot_lig.py .
      sed -i s/50000000/$5/g md.mdp
      sed -i s/SYSTEM_NAME/$7/g *.mdp
      echo "Copied and modified mdp files"
      echo "*************************"

      #echo -e "1\n1" | gmx pdb2gmx -f $2 -o sys_processed.gro -ignh
      gmx pdb2gmx -f $2 -o sys_processed.gro -ignh
      python3 combineGro_prot_lig.py sys_processed.gro $3 > complex.gro
      cp $4 LIG.itp

#Solvate
      gmx editconf -f complex.gro -o complex_box.gro -c -d 1.0 -bt cubic
      gmx solvate -cp complex_box.gro -p topol.top -o complex_solv.gro

      sed -i '/^#include "amber03.ff\/forcefield.itp"*/a #include "LIG.itp"' topol.top
      if [ $7 == "Protein_LIG" ]; then
         sed -i "/^Protein             1/a LIG         1" topol.top
	elif [ $7 == DNA_LIG ]; then
         sed -i "/^DNA                 1/a LIG         1" topol.top
	elif [ $7 == RNA_LIG ]; then
         sed -i "/^RNA                 1/a LIG         1" topol.top
 	else
	 echo "###########################################################"
	 echo "System name is not one of these Protein_LIG DNA_LIG RNA_LIG"
	 echo "Please check!"
	 echo "###########################################################"
      fi
      echo "*************************************"
      echo "Topology file updated with ligand itp"
      echo "*************************************"

# Neutralize
      gmx grompp -f ions.mdp -c complex_solv.gro -p topol.top -o ions.tpr -maxwarn 1
      echo -e "SOL" | gmx genion -s ions.tpr -o complex_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15
      echo "*********************************"
      echo "System neutralized!"
      echo "*********************************"

# EM
      gmx grompp -f em.mdp -c complex_ions.gro -p topol.top -o em.tpr
      gmx mdrun -deffnm em &
      #sleep 120
      PID=$!
      wait $PID
      echo "*********************************"
      echo "EM submitted and Waiting on EM: $PID"
      echo "*********************************"

      #echo "LIG" | gmx make_ndx -f LIG.gro -o index_lig.ndx ;# select LIG
      #gmx genrestr -f LIG.gro -n index_lig.ndx -o posre_lig.itp -fc 1000 1000 1000
      # Update the posre_lig.itp in topol.top file
echo -e "1 | 2 \n name 10 $7 \n
q" | gmx make_ndx -f em.gro -o index.ndx
      echo "************************"
      echo "Index file was created!"
      echo "************************"

      #NVT
      gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -n index.ndx -o nvt.tpr
      gmx mdrun -deffnm nvt &
      #sleep 300
      PID=$!
      wait $PID
      echo "***********************************************************"
      echo "NVT run was submitted and waiting on $PID"
      echo "***********************************************************"

      # NPT
      gmx grompp -f npt.mdp -c nvt.gro -t nvt.cpt -r nvt.gro -p topol.top -n index.ndx -o npt.tpr -maxwarn 1
      gmx mdrun -deffnm npt &
      #sleep 300
      PID=$!
      wait $PID
      echo "***********************************************************"
      echo "NPT run was submitted and waiting on $PID"
      echo "***********************************************************"

      if [ $6 == "prod" ]; then
      # Production
         gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md.tpr
         nohup gmx mdrun -deffnm md &
         echo "******************************************"
         echo "MD production run was submitted!"
         echo "******************************************"
      else
         gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md.tpr
         echo "******************************************"
	 echo "Asked for prep only. Generated md.tpr file."
	 echo "Didn't submit MD production run. Use this to submit jobs on SLURM cluster."
         echo "******************************************"
      fi
   
   else
      echo "*************************"
      echo "Preparing an Apo system!"
      cp /data/work/projects/*.mdp .
      sed -i s/50000000/$5/g md.mdp
      sed -i s/SYSTEM_NAME/$7/g *.mdp
      echo "Copied and modified mdp files"
      echo "*************************"
      echo -e "1\n1" | gmx pdb2gmx -f $2 -o sys_processed.gro -ignh

#Solvate
      gmx editconf -f sys_processed.gro -o apo_box.gro -c -d 1.0 -bt cubic
      gmx solvate -cp apo_box.gro -p topol.top -o apo_solv.gro

# Neutralize
      gmx grompp -f ions.mdp -c apo_solv.gro -p topol.top -o ions.tpr -maxwarn 1
      echo -e "SOL" | gmx genion -s ions.tpr -o apo_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15
      echo "*********************************"
      echo "System neutralized!"
      echo "*********************************"

# EM
      gmx grompp -f em.mdp -c apo_ions.gro -p topol.top -o em.tpr
      gmx mdrun -deffnm em &
      #sleep 120
      PID=$!
      wait $PID
      echo "*********************************"
      echo "EM submitted and Waiting on EM: $PID"
      echo "*********************************"
      

      #echo "LIG" | gmx make_ndx -f LIG.gro -o index_lig.ndx ;# select LIG
      #gmx genrestr -f LIG.gro -n index_lig.ndx -o posre_lig.itp -fc 1000 1000 1000
      # Update the posre_lig.itp in topol.top file
echo -e "1 | 2 \n name 10 $7 \n
q" | gmx make_ndx -f em.gro -o index.ndx
     echo "************************"
     echo "Index file was created!"
     echo "************************"

#NVT
     gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -n index.ndx -o nvt.tpr
     gmx mdrun -deffnm nvt &
     #sleep 300
     PID=$!
     wait $PID
     echo "***********************************************************"
     echo "NVT run was submitted and waiting on $PID"
     echo "***********************************************************"

# NPT
     gmx grompp -f npt.mdp -c nvt.gro -t nvt.cpt -r nvt.gro -p topol.top -n index.ndx -o npt.tpr -maxwarn 1
     gmx mdrun -deffnm npt &
     #sleep 300
     PID=$!
     wait $PID
     echo "***********************************************************"
     echo "NPT run was submitted and waiting on $PID"
     echo "***********************************************************"

# Production
     if [ $6 == "prod" ]; then
        gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md.tpr
        nohup gmx mdrun -deffnm md &
        echo "******************************************"
        echo "MD production run was submitted!"
        echo "******************************************"
     else
        gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md.tpr
        echo "******************************************"
	echo "Asked for prep only. Generated md.tpr file."
	echo "Didn't submit MD production run. Use this to submit jobs on SLURM cluster."
        echo "******************************************"
     fi

   fi
fi
