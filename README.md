# Transfert data weather

Ce repository `git` regroupe les deux scripts de transfert de données sécurisés : 

- `transfert-data-weather.sh` : 
    - Ce script est en charge 
        - Récupérer les données fournis par les drivers dans un fichier .csv
        - Créer un hash de celui-ci et de compresser le tout. 
        - Une fois compressé dans un fichier, celui-ci est chiffré pour garantir la confidentialité lors du transfert gràace à l'utilitaire gpg. 
        - En plus de cette couche de sécurité, le transfert est effctué en ssh qui lui aussi embarque une sécurité basé sur un échange de clés sécurisés.
- `data-processing-weather.sh` : 
    - Ce script permet de : 
        - Décrypter le fichier reçu
        - Décompresser le dossier reçu
        - Vérifier l'intégrité du .csv par comparaison avec hash initiale
        - Notification en cas d'anomalie de sécurité
        - Préparation pour insertion dans la base de données