#!/bin/bash

set -e

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
END="\e[0m"

echo -e "${GREEN}[+] GF Patterns Setup Started${END}"

# ===== CHECK GO =====
if ! command -v go &>/dev/null; then
    echo -e "${RED}[!] Go is not installed. Install Go first.${END}"
    exit 1
fi

# ===== INSTALL GF =====
if ! command -v gf &>/dev/null; then
    echo -e "${YELLOW}[+] Installing gf...${END}"
    go install github.com/tomnomnom/gf@latest
else
    echo -e "${GREEN}[✓] gf already installed${END}"
fi

# ===== GF CONFIG DIR =====
GF_DIR="$HOME/.gf"
mkdir -p "$GF_DIR"

# ===== OFFICIAL PATTERNS =====
if [ ! -d "$GF_DIR/examples" ]; then
    echo -e "${YELLOW}[+] Installing official gf patterns...${END}"
    git clone https://github.com/tomnomnom/gf "$GF_DIR/tmp-gf"
    cp "$GF_DIR/tmp-gf/examples/"*.json "$GF_DIR/"
    rm -rf "$GF_DIR/tmp-gf"
else
    echo -e "${GREEN}[✓] Official gf patterns already exist${END}"
fi

# ===== COMMUNITY PATTERNS =====
declare -A PATTERNS
PATTERNS=(
  ["gf-patterns"]="https://github.com/1ndianl33t/Gf-Patterns"
  ["gf-patterns-real"]="https://github.com/cujanovic/ggf"
  ["gf-sec"]="https://github.com/emadshanab/Gf-Patterns-Collection"
)

for NAME in "${!PATTERNS[@]}"; do
    if [ ! -d "$GF_DIR/$NAME" ]; then
        echo -e "${YELLOW}[+] Installing $NAME...${END}"
        git clone "${PATTERNS[$NAME]}" "$GF_DIR/$NAME"
        find "$GF_DIR/$NAME" -name "*.json" -exec cp {} "$GF_DIR/" \;
    else
        echo -e "${GREEN}[✓] $NAME already installed${END}"
    fi
done

# ===== CLEAN DUPLICATES =====
echo -e "${YELLOW}[+] Cleaning duplicate patterns...${END}"
cd "$GF_DIR"
ls *.json 2>/dev/null | sort | uniq > /tmp/gf_patterns.txt

echo -e "${GREEN}[✓] GF setup completed${END}"
echo -e "${GREEN}[✓] Total patterns installed: $(ls *.json 2>/dev/null | wc -l)${END}"
