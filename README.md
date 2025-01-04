# Traefik, the API Gateway

This project starts an API Gateway (Traefik) on your local server.  
It is configured to:
- Use Docker as a service provider.  
- Expose and listen on **port 443 (HTTPS)**.  
- Redirect incoming traffic on **port 80** to **443**.  
- Automatically handle SSL certificates and DNS via [DuckDNS](https://duckdns.org).  

DuckDNS offers **5 free subdomains**, which you can use to set up your apps.

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)  
- [Docker Compose](https://docs.docker.com/compose/install/)  

---

## Installation

### 1. Port Forwarding on Your Router

1. Access your router settings (often at `http://192.168.1.1`).  
2. Forward **port 443 (HTTPS)** to the local server running Traefik.

### 2. Free DNS & HTTPS with DuckDNS

1. Create a free account on [DuckDNS](https://duckdns.org).  
2. Link your public IP address to one or more DuckDNS subdomains of your choice.  
3. Initialize the `.env` file:
   ```bash
   cp .env.sample .env
   ```
4. Edit the `.env` file to include your **email address**, **DuckDNS token**, and **subdomains**. For example:
   ```bash
   DUCKDNS_EMAIL=myuser@example.com
   DUCKDNS_TOKEN=4f51...
   DUCKDNS_DOMAINS=domain1,domain2
   ```
   - **DUCKDNS_EMAIL**: Your email address.  
   - **DUCKDNS_TOKEN**: The token from the DuckDNS dashboard.  
   - **DUCKDNS_DOMAINS**: A comma-separated list of the subdomain names you created on DuckDNS (e.g., if your DuckDNS subdomain is `domain1.duckdns.org`, just put `domain1` here).  

   > **Note:** Each domain listed in `DUCKDNS_DOMAINS` corresponds to `domain-name.duckdns.org`.  
5. Create an empty `homeserver-https-cert.json` file and secure it by setting permissions to `600`:
   ```bash
   touch homeserver-https-cert.json
   chmod 600 homeserver-https-cert.json
   ```
6. **Traefik** will automatically renew certificates before they expire.  
7. Start Traefik:
   ```bash
   docker network create homeserver
   docker compose up -d
   firefox http://localhost:8080
   ```

---

## Key Points

1. **Traefik Dashboard**  
   - By default, the Traefik dashboard is exposed (insecure) at [http://your-server:8080](http://your-server:8080).  
   - You can secure or disable the dashboard by removing `--api.insecure=true` from the Traefik configuration.

2. **Certificate Renewal**  
   - Traefik automatically renews Let’s Encrypt certificates before they expire.

3. **Additional Applications**  
   - You can add other Docker services by labeling them for Traefik with a different `Host()` or `PathPrefix()` rule.

---

## Automating IP Updates on DuckDNS

If your public IP changes frequently (e.g., residential internet service), you can keep your DuckDNS subdomains updated automatically:

1. **Auto-Refresh Script**  
   - Create a script (e.g., `autorefresh-dns.sh`) that detects your IPv4/IPv6 and updates DuckDNS for each subdomain in `DUCKDNS_DOMAINS`.
   - Make sure it reads your **DuckDNS token** and **subdomains** from the `.env` file.

2. **Cron Scheduling**  
   - Give execution permission:
     ```bash
     chmod +x autorefresh-dns.sh
     ```
   - Schedule it in cron (e.g., every 5 minutes):
     ```bash
     crontab -e
     */5 * * * * /path/to/autorefresh-dns.sh
     ```

This ensures that your DuckDNS subdomains always match your current public IP, keeping your SSL certificates valid and your services accessible.