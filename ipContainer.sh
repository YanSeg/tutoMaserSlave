#!/bin/bash

# Vérifier si le nom du conteneur est fourni en argument
if [ -z "$1" ]; then
    echo "Usage: $0 <nom_du_conteneur>"
    exit 1
fi

# Récupérer l'adresse IP du conteneur
container_name=$1
container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name")

# Vérifier si le conteneur existe
if [ -z "$container_ip" ]; then
    echo "Le conteneur avec le nom '$container_name' n'existe pas ou n'a pas d'adresse IP."
    exit 1
fi

# Afficher l'adresse IP du conteneur
echo "L'adresse IP du conteneur '$container_name' est : $container_ip"
