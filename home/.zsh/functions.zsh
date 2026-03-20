# Create a directory and move it there
mkcd() {
  mkdir -p "$@" && cd "$_"
}
