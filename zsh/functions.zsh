# Create a directory and move it there
mkcd(){
  mkdir -p "$@" && cd "$_"
}


# Check the connected localhost
lh(){
  echo `ipconfig getifaddr en0`":${1:-3000}" | pbcopy
  echo "\nYour connected IP address is"
  echo `ipconfig getifaddr en0`":${1:-3000}" 
  echo "Copied to clipboard🧙🏿‍♂️\n"
}


# Open Localhost
oplh(){
  open "http://localhost:${1:-3000}"
}
