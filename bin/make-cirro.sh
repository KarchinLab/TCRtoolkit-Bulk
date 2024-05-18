#!/bin/bash

# 0. Provide help message
if [[ $1 == "-h" || $1 == "--help" ]]; then
  echo "Usage: ./bin/make-cirro.sh [bulk|sc|spatial]"
  exit 0
fi

# 0. Check validity of branh
if [[ $1 != "bulk" && $1 != "sc" && $1 != "spatial" ]]; then
  echo "Invalid argument. Please use one of the following arguments: bulk, sc, spatial"
  exit 1
fi

# 1. Remove remote and local branches
branch="cirro-$1"
git push origin --delete $branch 2> /dev/null
git branch -D $branch 2> /dev/null

# 2. Switch to desired branch
git checkout -b $branch
git merge main

# 3. Modify the implicit workflow in main.nf
if [[ $1 == "bulk" ]]; then
  sed -i 's|    sc()|    //sc()|' main.nf
  sed -i 's|    spatial()|    //spatial()|' main.nf
elif [[ $1 == "sc" ]]; then
  sed -i 's|    bulk()|    //bulk()|' main.nf
  sed -i 's|    spatial()|    //spatial()|' main.nf
elif [[ $1 == "spatial" ]]; then
  sed -i 's|    bulk()|    //bulk()|' main.nf
  sed -i 's|    sc()|    //sc()|' main.nf
fi

# 4. Modify lines in subworkflows/local/input_check.nf
comment_line=$(grep -n '2. Identify pipeline entrypoint' subworkflows/local/input_check.nf | cut -f1 -d:)
# sed -i "${comment_line}a \ \ \ \ // ===== CIRRO MODE =====" subworkflows/local/input_check.nf
entry_line=$(grep -n 'def entry = entrystring\[0\]\[1\]' subworkflows/local/input_check.nf | cut -f1 -d:)
sed -i 's|    def cmdline|    //def cmdline|' subworkflows/local/input_check.nf
sed -i 's|    def entry|    //def entry|' subworkflows/local/input_check.nf
sed -i "${entry_line}a \ \ \ \ def entry = \"$1\"" subworkflows/local/input_check.nf
# new_entry_line=$(grep -n 'def entry=' subworkflows/local/input_check.nf | cut -f1 -d:)
# sed -i "${new_entry_line}a \ \ \ \ // ===== CIRRO MODE =====" subworkflows/local/input_check.nf

# 5. Copy the configuration file to nextflow.config depending on the branch
cp configs/$1.config nextflow.config

# 6. git add main.nf and nextflow.config
git add main.nf nextflow.config subworkflows/local/input_check.nf

# 7. Commit changes with the message "make cirro-$1 " plus the date and time
git commit -m "make $branch $(date +'%Y-%m-%d %H:%M:%S')"

# 8. Push changes to the remote repository
git push origin $branch

# 9. Switch back to the main branch
git checkout main