#!/bin/bash

# Fichier CSV
CSV_FILE="/contact.csv"
SPOOL_DIR="/var/spool/asterisk/outgoing"
TEMP_DIR="/tmp/autodial"

# Contexte Asterisk qui recevra l'appel (dans extensions.conf)
CONTEXT="appel-prospection"
EXTENSION="s"

# Création du dossier temporaire
mkdir -p $TEMP_DIR

# 1. Lecture du CSV, mélange (shuf = randomize) et boucle
# On saute la première ligne (header) avec tail -n +2
tail -n +2 "$CSV_FILE" | shuf | while IFS=, read -r NOM PRENOM NUMERO
do
    echo "Appel de $PRENOM $NOM au $NUMERO..."

    # 2. Création du fichier .call
    # Le nom du fichier doit être unique
    CALL_FILE="$TEMP_DIR/call_${RANDOM}.call"
    
    cat <<EOF > "$CALL_FILE"
Channel: PJSIP/compte-phone
CallerID: "Prospection" <555555>
Context: internal
Extension: $EXTENSION
Priority: 1
MaxRetries: 1
RetryTime: 60
WaitTime: 30
Set: CONTACT_NOM=$NOM
Set: CONTACT_PRENOM=$PRENOM
EOF

    # 3. Déplacement vers le spool Asterisk (nécessite les droits root/asterisk)
    # On change le propriétaire pour asterisk sinon Asterisk refusera de le lire
    mv "$CALL_FILE" "$SPOOL_DIR/"

    # Pause pour ne pas saturer le trunk (ex: 1 appel toutes les 5 secondes)
    sleep 5
done

echo "Campagne terminée."
