# Create a directory and move it there
mkcd() {
  mkdir -p "$@" && cd "$_"
}

# Check the connected localhost
lh() {
  echo $(ipconfig getifaddr en0)":${1:-3000}" | pbcopy
  echo "\nYour connected IP address is"
  echo $(ipconfig getifaddr en0)":${1:-3000}"
  echo "Copied to clipboard🧙🏿‍♂️\n"
}

# Open Localhost
oplh() {
  open "http://localhost:${1:-3000}"
}

# zsh test
ztest() {
  for i in $(seq 1 10); do time zsh -i -c exit; done
}

# Node TypeScript New - Create TypeCcript Node.js project
ntn() {
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

# Git checkout remote branch
gcr() {
  git fetch origin $1
  git checkout $1
}

nozo:n() {
  if [ "$#" -eq 0 ]; then
    echo "Error: No argument supplied. "
    echo "Usage: nozo:n <project_name>"
    return 1
  fi

  npx -y create-next-app@latest --typescript --tailwind --no-eslint --app --src-dir --import-alias '@/*' --use-pnpm $1

  cd $1

  nozo:i

  cat > next.config.js << EOF
// @ts-check

/** @type {import('next').NextConfig} */
const nextConfig = {};

export default nextConfig;
EOF
}

# generate a commit message based on the branch name
gcmsga() {
  # Get the current branch name
  local branch_name=$(git rev-parse --abbrev-ref HEAD)

  # Matches "type(scope)/message"
  local pattern_with_scope='^([a-z]+\([a-z]+\))\/(.+)$'
  # Matches "type/message"
  local pattern_without_scope='^([a-z]+)\/(.+)$'

  # Check if the branch name matches the pattern type/message
  if [[ $branch_name =~ $pattern_with_scope || $branch_name =~ $pattern_without_scope ]]; then
    local type=${match[1]}
    local message=${match[2]//-/ } # Replace hyphens with spaces

    # Create and run the commit with the generated message
    git commit -m "$type: $message"
  else
    echo "Error: Branch name '$branch_name' does not match the expected format 'type(scope)/message' or 'type/message'."
  fi
}
