#!/bin/bash

# Fonction pour charger les variables d'environnement depuis un fichier .env
load_env() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    export $(grep -v '^#' "$env_file" | xargs)
  else
    echo "Erreur : Fichier .env non trouvé à $env_file !" >&2
    exit 1
  fi
}

# Fonction pour détecter l'IP (IPv4 ou IPv6) et retourner le type et l'adresse IP
detect_ip() {
  # Tenter de récupérer l'IPv6
  IPV6=$(curl -s6 ifconfig.me)
  if [[ -n "$IPV6" && "$IPV6" != "curl: (6) Could not resolve host" && "$IPV6" != "curl: (7) Failed to connect" ]]; then
    echo "IPv6" "$IPV6"
    return
  fi

  # Si IPv6 échoue, essayer de récupérer l'IPv4
  IPV4=$(curl -s4 ifconfig.me)
  if [[ -n "$IPV4" && "$IPV4" != "curl: (6) Could not resolve host" && "$IPV4" != "curl: (7) Failed to connect" ]]; then
    echo "IPv4" "$IPV4"
    return
  fi

  # Si aucune IP n'est détectée
  echo "Aucune IP détectée" ""
  exit 1
}

# Fonction pour mettre à jour DuckDNS pour un domaine donné
update_duckdns() {
  local domain="$1"
  local token="$2"
  local ip_type="$3"
  local ip_address="$4"
  local log_file="$5"

  local url="https://www.duckdns.org/update?domains=${domain}&token=${token}"
  
  if [[ "$ip_type" == "IPv6" ]]; then
    url="${url}&ipv6=${ip_address}"
  fi

  # Effectuer la requête et enregistrer la réponse dans le log avec un timestamp
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Mise à jour pour le domaine ${domain}" >> "$log_file"
  curl -s "$url" >> "$log_file" 2>&1
  echo "" >> "$log_file"  # Ligne vide pour séparer les entrées
}

# Déterminer le répertoire où se trouve le script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Chemin vers le fichier .env basé sur le répertoire du script
ENV_FILE="$SCRIPT_DIR/.env"

# Charger les variables d'environnement
load_env "$ENV_FILE"

# Vérifier que DUCKDNS_DOMAINS est défini
if [[ -z "$DUCKDNS_DOMAINS" ]]; then
  echo "Erreur : La variable DUCKDNS_DOMAINS n'est pas définie dans .env !" >&2
  exit 1
fi

# Fichier de log
LOG_FILE="$SCRIPT_DIR/autorefresh-dns.log"

# Détecter le type d'IP et l'adresse
read IP_TYPE IP_ADDRESS < <(detect_ip)

echo "Type d'IP détecté : $IP_TYPE"
echo "Adresse IP : $IP_ADDRESS"

# Convertir la liste de domaines en tableau (séparateur : virgule)
IFS=',' read -ra DOMAINS_ARRAY <<< "$DUCKDNS_DOMAINS"

# Mettre à jour chaque domaine DuckDNS
for domain in "${DOMAINS_ARRAY[@]}"; do
  domain_trimmed=$(echo "$domain" | xargs)  # Supprimer les espaces éventuels
  update_duckdns "$domain_trimmed" "$DUCKDNS_TOKEN" "$IP_TYPE" "$IP_ADDRESS" "$LOG_FILE"
done

echo "Mise à jour DuckDNS terminée. Voir le log à $LOG_FILE"
