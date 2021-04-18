#!/bin/bash
## gitea data
export PV=pvc-2bd43473-3f49-4849-9624-167fc7815323
export NAMESPACE1=dev
export NAMESPACE2=apps
export PVC=gitea-data

## gitea postgres
#export PV=pvc-46371a6e-a641-4b5f-bab0-10e571cdc11f
#export NAMESPACE1=dev
#export NAMESPACE2=apps
#export PVC=gitea-postgres

kubectl get pvc -n $NAMESPACE1 $PVC -o yaml | tee /tmp/pvc.yaml
kubectl get pv  $PV -o yaml | tee /tmp/pv.yaml
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl describe pv "$PV" | grep -e Reclaim
kubectl delete pvc -n "$NAMESPACE1" "$PVC"
kubectl patch pv "$PV" -p '{"spec":{"claimRef":{"namespace":"'$NAMESPACE2'","name":"'$PVC'","uid":null}}}'
kubectl get pv "$PV" -o yaml | grep -e Reclaim -e namespace -e uid: -e name: -e claimRef | grep -v " f:"
grep -v -e "uid:" -e "resourceVersion:" -e "namespace:" -e "selfLink:"  /tmp/pvc.yaml | kubectl -n "$NAMESPACE2" apply -f -
PVCUID=$( kubectl get -n "$NAMESPACE2" pvc "$PVC" -o custom-columns=UID:.metadata.uid --no-headers )
kubectl patch pv "$PV" -p '{"spec":{"claimRef":{"uid":"'$PVCUID'","name":null}}}'
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
kubectl get pv $PV -o yaml | grep -e Reclaim -e namespace



