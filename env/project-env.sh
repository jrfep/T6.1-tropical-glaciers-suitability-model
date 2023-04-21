export MIHOST=$(hostname -s)

export PROJECTNAME=T6.1-tropical-glaciers-data
export SCRIPTDIR=$HOME/proyectos/Tropical-Glaciers/$PROJECTNAME

case $MIHOST in
terra)
  export GISDATA=/opt/gisdata
  export GISOUT=/opt/gisout/output
  export WORKDIR=$HOME/tmp/$PROJECTNAME
  export REFDIR=$HOME/Cloudstor/Shared/EFTglobalmaps/
  ;;
roraima)
  export GISDATA=$HOME/gisdata
  export GISOUT=$HOME/gisout
  export WORKDIR=$HOME/tmp/$PROJECTNAME
  export REFDIR=$HOME/Cloudstor/Shared/EFTglobalmaps/
  ;;
*)
 if [ -e /srv/scratch/cesdata ]
 then
    export SHAREDSCRATCH=/srv/scratch/cesdata
    export PRIVATESCRATCH=/srv/scratch/$USER

    export GISDATA=$SHAREDSCRATCH/gisdata
    export GISOUT=$PRIVATESCRATCH/output/
    source $HOME/.secrets
    export WORKDIR=$PRIVATESCRATCH/tmp/$PROJECTNAME
    export REFDIR=$PRIVATESCRATCH/DKeith-data/
 else
    echo "I DON'T KNOW WHERE I AM, please customize project-env.sh file"
 fi
 ;;
esac

export LOCATION=earth

mkdir -p $WORKDIR

if [ -e $HOME/.database.ini ]
then
  grep -A4 psqlaws $HOME/.database.ini | tail -n +2 > tmpfile
  while IFS="=" read -r key value; do
    case "$key" in
      "host") export DBHOST="$value" ;;
      "port") export DBPORT="$value" ;;
      "database") export DBNAME="$value" ;;
      "user") export DBUSER="$value" ;;
    esac
  done < tmpfile
  rm tmpfile
fi
