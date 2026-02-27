#!/bin/bash

# usage ./recon_domain.sh target.com


if [ -z "$1" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

domain=$1


mkdir -p recon/$domain
cd recon/$domain || exit

echo "[+] Starting PASSIVE RECON.."
echo "[+] subdomain enumeration .... "
echo "[+] running subfinder.."
subfinder -silent -d $domain -all -recursive  -o subfinder.txt

echo "[+] running assetfinder.."
assetfinder --subs-only $domain > assetfinder.txt


echo "[+] running crt sources..."
curl -s "https://crt.sh/?q=%25.$domain&output=json" \
| jq -r '.[].name_value' 2>/dev/null \
| sed 's/\*\.//g' \
| sort -u > crt_subs.txt

curl -s "https://api.certspotter.com/v1/issuances?domain=${domain}&include_subdomains=true&expand=dns_names" \
| jq -r '.[].dns_names[]' 2>/dev/null \
| sed 's/\*\.//g' \
| grep -E "\.?$domain$" \
| sort -u > certspotter.txt

echo "[+] running github-subdomains.."
github-subdomains -d $domain -t $GITHUB_TOKEN -q -o github_subs.txt

#amass 4.2 --> upgrade to lastest version
echo "[+] running amass.."
#amass enum -passive -d $domain -silent -norecursive | grep -E "^[a-zA-Z0-9._-]+\.$domain$" > amass_passive.txt


echo "[+] merging result.."
cat subfinder.txt assetfinder.txt  crt_subs.txt certspotter.txt github-subdomains.txt amass_passive.txt | sort -u > subdomain_$domain.txt

#use alterx with pattern use advance wordlist -w wordlists.txt for advance
echo "[+] running alterx..."
alterx -l subdomain_$domain.txt -o mutated_$domain.txt

echo "[+] ACTIVE RECON..."
echo "[+] running dsnx resolver..."
dnsx -l subdomain_$domain.txt -silent -o resolved.txt

echo "[+] resolving live hosts.."
httpx -silent -l resolved.txt   -o httpx_live_$domain.txt

echo "[+] shuffledns running.."
shuffledns -d $domain -l mutated_$domain.txt -r /home/fmask/regulator/resolvers.txt -mode resolve -silent -t 1000  -sw -o resolved_mutated_$domain.txt

cat subdomain_$domain.txt resolved_mutated_$domain.txt | sort -u > final_subdomains.txt

echo "[+] running port scan on top 100 ports.. and detect title info"
cat final_subdomains.txt | naabu -tp 1000 -ep 22 | httpx -sc -cl -location -fr  -title -td -o  web_recon_$domain.txt

echo "[+] Recon completed!"
echo "Results saved in recon/$domain/"
