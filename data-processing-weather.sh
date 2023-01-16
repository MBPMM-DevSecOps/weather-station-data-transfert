## ------------- SERVEURWEB

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
