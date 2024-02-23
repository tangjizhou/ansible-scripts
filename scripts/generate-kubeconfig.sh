usage() {
  echo "usage: ./kubeconfig-generator.sh <namespace>"
}
namespace=$1
serviceAccount=${namespace}-admin
clusterName=kubernetes
if [ -z $namespace ]; then
    echo "Error: namespace is required"
    usage
    exit 1
fi

server=$(kubectl config view --minify --raw -o jsonpath='{.clusters[].cluster.server}' | sed 's/"//')
ca=$(kubectl --namespace $namespace get secret/${serviceAccount} -o jsonpath='{.data.ca\.crt}')
if [ $? != 0 ]; then
    exit 1
fi
token=$(kubectl --namespace $namespace get secret/${serviceAccount} -o jsonpath='{.data.token}' | base64 --decode)

echo $?

echo "
apiVersion: v1
kind: Config
clusters:
  - name: ${clusterName}
    cluster:
      certificate-authority-data: ${ca}
      server: ${server}
contexts:
  - name: ${serviceAccount}@${clusterName}
    context:
      cluster: ${clusterName}
      namespace: ${namespace}
      user: ${serviceAccount}
users:
  - name: ${serviceAccount}
    user:
      token: ${token}
current-context: ${serviceAccount}@${clusterName}
" > ${serviceAccount}.kubeconfig