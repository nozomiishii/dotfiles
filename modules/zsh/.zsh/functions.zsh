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


# zsh test
ztest(){
  for i in $(seq 1 10); do time zsh -i -c exit; done
}


# Node TypeScript New - Create TypeCcript Node.js project
ntn(){
  git clone git@github.com:nozomiishii/node.ts.git ${1:-new-project} && cd $_
}

# Restart Duet
rsdt() {
  pgrep -f duet | xargs kill $1
  open "/Applications/duet.app"
}

# Kill Port
killp() {
  kill -9 $(lsof -ti:$1) && echo "killed Port $1"
}
