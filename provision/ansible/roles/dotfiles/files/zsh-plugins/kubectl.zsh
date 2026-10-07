## completion
source <(kubectl completion zsh)

## This command is used a LOT both below and in daily life
alias kubectl=kubecolor
alias k=kubectl

## completion v2
#compdef __start_kubectl k
compdef kubecolor=kubectl
compdef k=kubectl

## kubectx/kubens
alias kctx=kubectx
alias kns=kubens #|fzf --preview "kubectl get pods -n {}"'

# get
alias kg="kubectl get"
## prompt on/of
alias kon="kubeon"
alias koff="kubeoff"

## top
alias ktn='kubectl top nodes'
alias ktp='kubectl top pods'

## events
alias kge="kubectl get events"
alias kgew="kubectl get events --watch"
alias kgewa="kubectl get events --watch -A"

## plugins
alias kpl='kubectl plugin'

## Execute a kubectl command against all namespaces
alias kca='_kca(){ kubectl "$@" -A;  unset -f _kca; }; _kca'

## Apply a YML file
alias kaf='kubectl apply -f'

## Apply kustomization
alias kak='kubectl apply -k'

## Drop into an interactive terminal on a container
alias keti='kubectl exec -ti'


## drain nodes
alias kdrain='kubectl drain --ignore-daemonsets --delete-emptydir-data --force'

## run debug pod and shell into it
alias kpod="kubectl run debugpod --image=curlimages/curl -i --tty -- sh"
alias kalp="kubectl run alpine --image=alpine -i --tty -- sh"
alias kalp2="kubectl run utility-alpine --image=szpaczyn/utility-alpine -i --tty -- bash"
#alias kalp2="kubectl run utility-alpine --image=docker.branch.io/infra-utils/utility-alpine:1.0.0 -i --tty -- bash"

## List all contexts
alias kcgc='kubectl config get-contexts'

## General aliases
alias kdel='kubectl delete'
alias kdelf='kubectl delete -f'

## Pod management.
alias kgp='kubectl get pods'
alias kgpnr='kubectl get pods --field-selector=status.phase!=Running'
alias kgpnra='kubectl get pods -A --field-selector=status.phase!=Running'
alias kgpl="kubectl get pods -o=custom-columns='NAME:spec.containers[*].name,MEMREQ:spec.containers[*].resources.requests.memory,MEMLIM:spec.containers[*].resources.limits.memory,CPUREQ:spec.containers[*].resources.requests.cpu,CPULIM:spec.containers[*].resources.limits.cpu'"
alias kgpa='kubectl get pods --all-namespaces'
alias kgpw='kgp --watch'
alias kgpwide='kgp -o wide'
alias kep='kubectl edit pods'
alias kdp='kubectl describe pods'
alias kdelp='kubectl delete pods'

## get pod by label: kgpl "app=myapp" -n myns
alias kgplb='kgp -l'

## get pod by namespace: kgpn kube-system"
alias kgpn='kgp -n'

## Service management.
alias kgs='kubectl get svc'
alias kgsa='kubectl get svc --all-namespaces'
alias kgsw='kgs --watch'
alias kgswide='kgs -o wide'
alias kes='kubectl edit svc'
alias kds='kubectl describe svc'
alias kdels='kubectl delete svc'

## Ingress management
alias kgi='kubectl get ingress'
alias kgia='kubectl get ingress --all-namespaces'
alias kei='kubectl edit ingress'
alias kdi='kubectl describe ingress'
alias kdeli='kubectl delete ingress'

## Namespace management
alias kgns='kubectl get namespaces'
alias kens='kubectl edit namespace'
alias kdns='kubectl describe namespace'
alias kdelns='kubectl delete namespace'
alias kcn='kubectl config set-context $(kubectl config current-context) --namespace'

## ConfigMap management
alias kgcm='kubectl get configmaps'
alias kgcma='kubectl get configmaps --all-namespaces'
alias kecm='kubectl edit configmap'
alias kdcm='kubectl describe configmap'
alias kdelcm='kubectl delete configmap'

## Secret management
alias kgsec='kubectl get secret'
alias kgseca='kubectl get secret --all-namespaces'
alias kdsec='kubectl describe secret'
alias kdelsec='kubectl delete secret'

## Deployment management.
alias kgd='kubectl get deployment'
alias kgda='kubectl get deployment --all-namespaces'
alias kgdw='kgd --watch'
alias kgdwide='kgd -o wide'
alias ked='kubectl edit deployment'
alias kdd='kubectl describe deployment'
alias kdeld='kubectl delete deployment'
alias ksd='kubectl scale deployment'
alias krsd='kubectl rollout status deployment'
kres(){
    kubectl set env $@ REFRESHED_AT=$(date +%Y%m%d%H%M%S)
}

## Rollout management.
alias kgrs='kubectl get rs'
alias krh='kubectl rollout history'
alias kru='kubectl rollout undo'

## Statefulset management.
alias kgss='kubectl get statefulset'
alias kgssa='kubectl get statefulset --all-namespaces'
alias kgssw='kgss --watch'
alias kgsswide='kgss -o wide'
alias kess='kubectl edit statefulset'
alias kdss='kubectl describe statefulset'
alias kdelss='kubectl delete statefulset'
alias ksss='kubectl scale statefulset'
alias krsss='kubectl rollout status statefulset'

## daemonset management
alias kgds="kubectl get daemonset"
alias kgdsa="kubectl get daemonset --all-namespaces"
alias kgdsw="kgds --watch"
alias kgdswide="kgds -o wide"
alias kdds="kubectl describe daemonset"
alias kdelds="kubectl delete daemonset"

# Port forwarding
alias kpf="kubectl port-forward"

# Tools for accessing all information
alias kga='kubectl get all'
alias kgaa='kubectl get all --all-namespaces'

# Logs
alias kl='kubectl logs'
alias kl1h='kubectl logs --since 1h'
alias kl1m='kubectl logs --since 1m'
alias kl1s='kubectl logs --since 1s'
alias klf='kubectl logs -f'
alias klf1h='kubectl logs --since 1h -f'
alias klf1m='kubectl logs --since 1m -f'
alias klf1s='kubectl logs --since 1s -f'
alias kls='stern'
alias klsp='stern --prompt'
# File copy
alias kcp='kubectl cp'

# Node Management
alias kgno='kubectl get nodes'
alias keno='kubectl edit node'
alias kdno='kubectl describe node'
alias kdelno='kubectl delete node'

# PVC management.
alias kgpvc='kubectl get pvc'
alias kgpvca='kubectl get pvc --all-namespaces'
alias kgpvcw='kgpvc --watch'
alias kepvc='kubectl edit pvc'
alias kdpvc='kubectl describe pvc'
alias kdelpvc='kubectl delete pvc'

## autoscalers
alias kghpa='kubectl get horizontalpodautoscalers'
alias kghpaa='kubectl get horizontalpodautoscalers --all-namespaces'
alias kgvpa='kubectl get verticalpodautoscalers'
alias kgvpaa='kubectl get verticalpodautoscalers --all-namespaces'

## cronjobs/jobs
alias kgcj='kubectl get cronjobs.batch'
alias kgcja='kubectl get cronjobs.batch --all-namespaces'

alias kgj='kubectl get jobs.batch'
alias kgja='kubectl get jobs.batch --all-namespaces'

alias kshell='kubectl exec -ti $(kgp --no-headers |fzf) -- /bin/sh'

## describe
alias kdesc='kubectl describe'

## colorized get stuff
## not used since kubecolor
#function kgp() {
#    kubectl get pods -o wide "$@" \
#        | sed "s/Running/$fg_bold[green]Running$reset_color/g" \
#        | sed "s/Pending/$fg_bold[yellow]Pending$reset_color/g" \
#        | sed "s/Completed/$fg_bold[blue]Completed$reset_color/g" \
#        | sed "s/Error/$fg_bold[red]Error$reset_color/g" \
#        | sed "s/ErrImagePull/$fg_bold[red]ErrImagePull$reset_color/g" \
#        | sed "s/CrashLoopBackOff/$fg_bold[red]CrashLoopBackOff$reset_color/g" \
#        | sed "s/Terminating/$fg_bold[red]Terminating$reset_color/g"
#}

#function kgs() {
#    kubectl get svc "$@" \
#        | sed "s/ClusterIP/$fg_bold[yellow]ClusterIP$reset_color/g" \
#        | sed "s/LoadBalancer/$fg_bold[blue]LoadBalancer$reset_color/g"
#}

#function kgno() {
#    kubectl get nodes "$@" \
#        | sed "s/Ready/$fg_bold[green]Ready$reset_color/g" \
#        | sed "s/NotReady/$fg_bold[red]NotReady$reset_color/g"
#}

#function kgpvc() {
#    kubectl get pvc "$@" \
#        | sed "s/Bound/$fg_bold[green]Bound$reset_color/g" \
#        | sed "s/Pending/$fg_bold[yellow]Pending$reset_color/g"
#}

#function kga() {
#    kubectl get all "$@" \
#        | sed "s/Running/$fg_bold[green]Running$reset_color/g" \
#        | sed "s/Pending/$fg_bold[yellow]Pending$reset_color/g" \
#        | sed "s/Completed/$fg_bold[blue]Completed$reset_color/g" \
#        | sed "s/Error/$fg_bold[red]Error$reset_color/g" \
#        | sed "s/ErrImagePull/$fg_bold[red]ErrImagePull$reset_color/g" \
#        | sed "s/CrashLoopBackOff/$fg_bold[red]CrashLoopBackOff$reset_color/g" \
#        | sed "s/Terminating/$fg_bold[red]Terminating$reset_color/g" \
#        | sed "s/Bound/$fg_bold[green]Bound$reset_color/g" \
#        | sed "s/Ready/$fg_bold[green]Ready$reset_color/g" \
#        | sed "s/NotReady/$fg_bold[red]NotReady$reset_color/g" \
#        | sed "s/ClusterIP/$fg_bold[yellow]ClusterIP$reset_color/g" \
#        | sed "s/LoadBalancer/$fg_bold[blue]LoadBalancer$reset_color/g"
#}
