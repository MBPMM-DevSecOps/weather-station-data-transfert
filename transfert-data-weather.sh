## ------------- RASPBERRY

# Stop le script à la première erreur
set -e

# Vérifie que le script n'est pas déjà en cours
if pidof -x "`basename $0`" -o $$ >/dev/null; then
    echo "Process already running"
    exit 1;
fi

CREATION_TIME=$(date +%Y-%m-%d__%H-%M-%S)
DATA_FOLDER='/data/weather-station'
CSV_NAME='data-weather-station.csv'
SERVEUR_WEB_USER='serveurweb'
SERVEUR_WEB_IP='20.19.210.201'

# Création du dossier de travail
mkdir $DATA_FOLDER/$CREATION_TIME

# Copie du csv initiale
cp $DATA_FOLDER/$CSV_NAME $DATA_FOLDER/$CREATION_TIME/$CSV_NAME

# Suppression de toutes les lignes du fichier (sauf de la première => labels)
first_line=$(head -n 1 $DATA_FOLDER/$CSV_NAME)

# Création du hash du fichier
sha256sum $DATA_FOLDER/$CREATION_TIME/$CSV_NAME > $DATA_FOLDER/$CREATION_TIME/$CSV_NAME.hash

# Création du .tar.gz
cd $DATA_FOLDER
tar -zcvf $CREATION_TIME.tar.gz $CREATION_TIME

# Supression du dossier de base
rm -rf $DATA_FOLDER/$CREATION_TIME

# Chiffrement du fichier :
gpg --encrypt --sign --armor -r serveurweb $DATA_FOLDER/$CREATION_TIME.tar.gz

# Supression du .tar.gz
rm -f $DATA_FOLDER/$CREATION_TIME.tar.gz

# Scp du fichier vers le serveur web
scp $DATA_FOLDER/$CREATION_TIME.tar.gz.asc $SERVEUR_WEB_USER@$SERVEUR_WEB_IP:$DATA_FOLDER/to-check

# Suppression du .tar.gz chiffré
rm -f $DATA_FOLDER/$CREATION_TIME.tar.gz.asc