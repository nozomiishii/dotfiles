#!/bin/bash
set -Ceu

# Requests administrator privileges upfront and temporarily increases sudo's timeout
# until the current process has finished.
#
request_admin_privileges() {
  # Ask for the administrator password upfront
  sudo -v

  # Temporarily increase sudo's timeout until the process has finished
  (
    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" || exit
    done
  ) 2> /dev/null &
}
