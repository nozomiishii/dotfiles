# Create a directory and move it there
mkcd() {
  mkdir -p "$@" && cd "$_"
}

# Copy current directory as `cd <path>` to clipboard
jf() {
  local payload="cd $(printf '%q' "$PWD")"
  printf '%s' "$payload" | pbcopy
  printf '\033[32m✓\033[0m Copied to clipboard\n  \033[2m%s\033[0m\n' "$payload"
}
