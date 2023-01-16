# Transfert data weather

## Description 

Ce repository `git` regroupe les deux scripts de transfert de données sécurisés : 

- `transfert-data-weather.sh` (script sur le Raspberry): 
    - Ce script est en charge 
        - Récupérer les données fournis par les drivers dans un fichier .csv
        - Créer un hash de celui-ci et de compresser le tout. 
        - Une fois compressé dans un fichier, celui-ci est chiffré pour garantir la confidentialité lors du transfert gràace à l'utilitaire gpg. 
        - En plus de cette couche de sécurité, le transfert est effctué en ssh qui lui aussi embarque une sécurité basé sur un échange de clés sécurisés.
- `data-processing-weather.sh` (script sur le serveur de stockage): 
    - Ce script permet de : 
        - Décrypter le fichier reçu
        - Décompresser le dossier reçu
        - Vérifier l'intégrité du .csv par comparaison avec hash initiale
        - Notification en cas d'anomalie de sécurité
        - Préparation pour insertion dans la base de données
        
 ## Taches planifiées
        
Ces scripts sont lancés à intervalle réguliers à l'aide de cron qui permettent de planifier une tâche récurrente. 
 
Les lignes suivantes permettent de configurer l'éxecution des scripts : 
 
Raspberry crontab : 
```bash
10 * * * * /bin/bash /bin/transfert-data-weather.sh
```

Serveur de stockage crontab : 
```bash
10 * * * * /bin/bash /bin/data-processing-weather.sh
```
