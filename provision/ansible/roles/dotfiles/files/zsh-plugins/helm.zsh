# Autocompletion for helm.

if [ $commands[helm] ]; then
  source <(helm completion zsh)
fi
