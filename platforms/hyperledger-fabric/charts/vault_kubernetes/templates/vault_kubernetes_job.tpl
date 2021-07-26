apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  namespace: {{ component_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ component_name }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/vault_kubernetes
  values:
    metadata:
      namespace: {{ component_ns }}    
      images:
        fabrictools: {{ fabrictools_image }}
        alpineutils: {{ alpine_image }}

    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ component_ns }}-auth
      adminsecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ component_ns }}/users/admin
      orderersecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ component_ns }}/orderer
      serviceaccountname: vault-auth
      imagesecretname: regcred
      policy: vault-crypto-{{ component_type }}-{{ component_name }}-ro
{% if item.type == 'orderer' %}     
      policy_content: ??? orderer-ro.tpl
{% else %}      
      policy_content: ??? per-ro.tpl
{% endif %}
 
    k8s:
        url: "https://C8FA1454BFC54EBEAC7D6A70501769F2.sk1.eu-west-1.eks.amazonaws.com" ?????
        context: "arn:aws:eks:eu-west-1:895052373684:cluster/demo-CLUSTER" {{ k8s.context }}
        config_file: "/home/marina/.kube/demo.yaml"  {{ k8s.config_file }}