#!/bin/bash

# Target domain
target_domain="$1"
echo [*] Doing recon on $target_domain
# Directory structure
output_dir="$target_domain/"
urls_dir="$output_dir/urls/"
probed_dir="$output_dir/probed/"
status_dir="$probed_dir/status/"

# Ensure directories exist
mkdir -p "$output_dir" "$urls_dir" "$status_dir"

# Subfinder
echo [*] Finding subdomains
subfinder -d "$target_domain" -o "$output_dir/subdomains.txt" > /dev/null 2> /dev/null
echo [+] Found $(wc -l $output_dir/subdomains.txt | awk '{print $1}') domains


# Katana Crawl
echo [*] Crawling $target_domain
echo $target_domain | katana > "$urls_dir/crawl.txt" 2> /dev/null
echo [+] Found $(wc -l "$urls_dir/crawl.txt" | awk '{print $1}') Endpoints

# Gau
echo [*] Fetching URLs from $target_domain
gau "${target_domain}" > "${urls_dir}urls.txt"
cat $urls_dir/urls.txt $urls_dir/crawl.txt | grep -iE "\.js(\?.*)?$" > "${urls_dir}js_files.txt"
echo [+] Found $(wc -l "$urls_dir/crawl.txt" | awk '{print $1}') URLs


# HTTPX
echo [*] Probing subdomains
httpx -l "${output_dir}subdomains.txt" -o "${probed_dir}probed.txt"
echo [+] $(wc -l "$probed_dir/probed.txt" | awk '{print $1}')/$(wc -l "$output_dir/subdomains.txt" | awk '{print $1}') alive subdomains

# Sed to strip "http(s)://"
sed -r "s/^https?:\/\///" "${probed_dir}probed.txt" > "${probed_dir}probed_clean.txt"

: '
# HTTPX with title and status code
httpx -l "${probed_dir}probed.txt" -title -sc -o "${probed_dir}probed_with_status.txt"

# Organize status codes
awk "$2 ~ /^2/{print $1}" "${probed_dir}probed_with_status.txt" > "${status_dir}ok_domains.txt"
awk "$2 ~ /^3/{print $1}" "${probed_dir}probed_with_status.txt" > "${status_dir}red_domains.txt"
awk "$2 ~ /^4/{print $1}" "${probed_dir}probed_with_status.txt" > "${status_dir}err_domains.txt"
awk "$2 ~ /^5/{print $1}" "${probed_dir}probed_with_status.txt" > "${status_dir}interr_domains.txt"
rm ${probed_dir}/probed_with_status.txt

'