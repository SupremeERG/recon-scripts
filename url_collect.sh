#!/usr/bin/sh


bold="\e[1m"
underlined="\e[4m"
red="\e[31m"
green="\e[32m"
blue="\e[34m"
end="\e[0m"

Main() {

    # target domain
    target_domain="$1"
    output_dir=recon-$(echo $target_domain | sha256sum | awk '{print $1}' | cut -c 1-12)/url_collector

    mkdir -p ./$output_dir

    # fetching URLs using gau
    echo -e $blue"Fetching URLs using gau"$end
    echo -e $target_domain | gau --threads 3 --providers wayback > $output_dir/gau # remove the providors option later
    echo -e "Found $green$bold"$(wc -l "$output_dir/gau"| awk '{print $1}')"$end URLs"
    echo
    

    # fetching URLs using katana
    echo -e  $blue"Fetching URLs and endpoints using katana"$end
    echo -e  $target_domain | katana > $output_dir/katana 2> /dev/null
    echo -e  "Found $green$bold"$(wc -l "$output_dir/katana" | awk '{print $1}')"$end URLs"
    echo

    # filter URLs using uro
    echo  -e $blue"Filtering gathered URLs and endpoints using uro"$end
    cat "$output_dir/gau" "$output_dir/katana" | uro > $output_dir/uro
    echo  -e Filtered-URLs/Total-URLs: $green$bold$(wc -l "$output_dir/uro" | awk '{print $1}')/$(cat "$output_dir/katana" "$output_dir/gau" | wc -l | awk '{print $1}')$end
    echo

    cat "$output_dir/katana" "$output_dir/gau" | sort | uniq > "$output_dir/urls" && rm "$output_dir/katana" "$output_dir/gau"

    echo -e $blue$bold"Done. Output to $underlined$output_dir"$end
    echo 
}

# Check for the presence of the -p option
while getopts ":p" opt; do
  case $opt in
    p)
      extract_params=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Remove the parsed options from the positional parameters
shift $((OPTIND-1))

Main "$@"

# Extract URL parameters by using -p
if [ "$extract_params" = true ]; then
    urls_file="$output_dir/urls" # Replace with your actual file path
    if [ -f "$urls_file" ]; then
        echo "Extracting URL parameters..."
        cat "$urls_file" | grep -oP "\?.*?" | sed 's/&/\n/g' | cut -d '?' -f 2 | sort | uniq > "$output_dir/parameters"
        echo "Extracted parameters are saved to $output_dir/parameters"
    else
        echo "URLs file not found: $urls_file"
    fi
fi


echo -e $blue$bold """
 ___  ___  ________  ___                                                                      
|\  \|\  \|\   __  \|\  \                                                                     
\ \  \\\  \ \  \|\  \ \  \                                                                    
 \ \  \\\  \ \   _  _\ \  \                                                                   
  \ \  \\\  \ \  \\  \\ \  \____                                                              
   \ \_______\ \__\\ _\\ \_______\                                                            
 __________________\|___\|________       _______   ________ _________  ________  ________     
|\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____|\___   ___|\   __  \|\   __  \    
\ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \|\  \ \  \|\  \   
 \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \\\  \ \   _  _\  
  \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \\\  \ \  \\  \| 
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \_______\ \__\\ _\ 
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|_______|\|__|\|__|

    -p: Extract URL Parameters.
                                                                                                 
"""$end

Main $1
