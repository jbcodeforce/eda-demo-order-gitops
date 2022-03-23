cat $1.yaml | kubeseal --controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller --format yaml > $1-sealedsecret.yaml
