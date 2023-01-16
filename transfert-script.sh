# ETAPE 1 : Captation des données (Malo)
# L'objectif est de stocker les données temporairement dans des csv
# Un script python vient questionner les drivers toutes les x secondes pour récupérer les 4 valeurs
# Le script insère ces 3 données dans un fichier csv (accompagné de l'heure) de récupération : data-weather-station.csv
# Les fichiers sont stockés dans le dossier /data/weather-station

# ETAPE 2 : Récupération et transfert des données vers le serveur de BDD (Mathieu)
# Une fois toutes les 10 minutes un script bash vient faire une copie de ce fichier data-weather-station-2023-01-02__14-48-34.csv (date-`date +%Y-%m-%d__%H-%M-%S`.csv) (+ le vider)
# La copie est inséré dans un dossier
# On fait ensuite un hash de ce fichier dans le même dossier
# On compresse le dossier dans un .tar.gz
# On chiffre le fichier pour que seul le serveurweb puisse le déchiffrer (avec GPG)
# On transfère le fichier chiffré par l'intermédaire du protocole SSH vers le serveurweb /data/weather-station/to-check
# Une fois le transfère effectué on supprime le .tar.gz + le dossier de départ

# ETAPE 3 : Reception/Decompression/Déchiffrement & vérification d'intégrité & préparation à l'insertion en BDD (Mathieu)
# Une fois toutes les 10 minutes sur le serveur de reception dans le dossier /data/weather-station/to-check
# Pour tous les fichiers du dossier /data/weather-station/to-check
# On déchiffre le fichier + on le décompresse
# On créer un hash (sha256sum) du fichier csv et on compare le hash fait sur le raspeberry et celui qui vient d'être créer
# En cas de non-égalité :
#   - on notifie le responsable
#   - on déplace le .tar.gz dans /data/weather-station/integrity-error
#   - on supprime le dossier décompressé & le fichier de base crypté
#   - et on ne va pas plus loin
# Si les 2 hashs sont égaux :
#   - on copie le CSV vers /data/weather-station/to-insert
#   - on supprime le .tar.gz + le dossier décompressé + le fichier de base crypté



## ------------- SUR LE RASPBERRY (cron 10)

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



## ------------- SUR LE SERVEURWEB

# Stop le script à la première erreur
set -e

# Vérifie que le script n'est pas déjà en cours
if pidof -x "`basename $0`" -o $$ >/dev/null; then
    echo "Process already running"
    exit 1;
fi


DATA_FOLDER='/data/weather-station'
DATA_FOLDER_TO_CHECK=$DATA_FOLDER'/to-check'
DATA_FOLDER_TO_INSERT=$DATA_FOLDER'/to-insert'
DATA_FOLDER_INTEGRITY_ERROR=$DATA_FOLDER'/integrity-error'
DATA_FOLDER_TMP=$DATA_FOLDER'/tmp'
CSV_NAME='data-weather-station.csv'

cryptFileList=$(ls "$DATA_FOLDER_TO_CHECK"/)

for cryptFile in $cryptFileList; do
    # Déchiffre le fichier
    fileNameWithoutCryptExt=$(basename $cryptFile .asc)
    gpg --decrypt $DATA_FOLDER_TO_CHECK/$cryptFile > $DATA_FOLDER_TMP/$fileNameWithoutCryptExt

    # Décompression du fichier
    tar -xvf $DATA_FOLDER_TMP/$fileNameWithoutCryptExt --directory $DATA_FOLDER_TMP
    folderNameWithoutCompressExt=$(basename $fileNameWithoutCryptExt .tar.gz)


    if [ $(sha256sum $DATA_FOLDER_TMP/$folderNameWithoutCompressExt/$CSV_NAME | awk '{print $1}') = $(cat $DATA_FOLDER_TMP/$folderNameWithoutCompressExt/$CSV_NAME.hash | awk '{print $1}') ]; then
        # Copie vers le dossier regroupant les données à insérer en BDD
        mv $DATA_FOLDER_TMP/$folderNameWithoutCompressExt/$CSV_NAME $DATA_FOLDER_TO_INSERT/${folderNameWithoutCompressExt}-${CSV_NAME}
    else
        # Notification du responsable des anomalies 
        # ...

        # Stockage du fichier contenant l'erreur d'intégrité
        cp $DATA_FOLDER_TMP/$fileNameWithoutCryptExt $DATA_FOLDER_INTEGRITY_ERROR/
    fi

    # Supprime le fichier crypté de base
    rm $DATA_FOLDER_TO_CHECK/$cryptFile

    # Supprimer le contenu du dossier temporaire
    rm -rf $DATA_FOLDER_TMP/*
done
