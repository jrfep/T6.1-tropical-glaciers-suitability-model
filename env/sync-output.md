source ~/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.sh
cd $WORKDIR

# for terra.ad.unsw.edu.au
REMOTEDM=kdm.restech.unsw.edu.au
REMOTESCRATCH=/srv/scratch/$zID/output/$PROJECTNAME
rsync -gloptrunv ${zID}@${REMOTEDM}:${REMOTESCRATCH}/* $GISOUT/$PROJECTNAME

# for roraima
REMOTEDM=kdm.restech.unsw.edu.au
REMOTESCRATCH=/srv/scratch/$zID/output/$PROJECTNAME
rsync -gloptrunv ${zID}@${REMOTEDM}:${REMOTESCRATCH}/OUTPUT/*gpkg $WORKDIR
rsync -gloptrunv ${zID}@${REMOTEDM}:${REMOTESCRATCH}/OUTPUT/*csv $WORKDIR
rsync -gloptrunv ${zID}@${REMOTEDM}:${REMOTESCRATCH}/OUTPUT/*txt $WORKDIR
