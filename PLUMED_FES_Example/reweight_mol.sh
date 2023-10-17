#!/bin/bash
#SBATCH --partition=interactive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --mem=64GB
#SBATCH --time=96:00:00

module load gromacs/2021.1

# Create index file with molecule numbers for the desired species, e.g., CO2
spec="CO2"
start=785
end=884

echo -e "[ $spec ]" > "$spec"_mol_index.ndx
seq -s" " $start 1 $end >> "$spec"_mol_index.ndx
echo -e "" >> "$spec"_mol_index.ndx

# Output the z positions of the centers of mass of each molecule using the -mol flag and the special index file above
# gmx traj segfaults after analyzing the last frame for unknown reasons, but it produces the correct output

gmx traj -f prod.xtc -n "$spec"_mol_index.ndx -ox "$spec"_molz.xvg -mol -nox -noy -s prod.tpr -xvg none -b 500000

# Convert the columns into rows and format as a plumed data file

echo -e "#! FIELDS time z" > "$spec"_molz.dat
awk '{for (i=2;i<=NF;i++) print NR"\t"$i}' "$spec"_molz.xvg >> "$spec"_molz.dat

module load plumed/git-gcc8

plumed driver --plumed plumed_reweight_multiple.dat --noatoms
