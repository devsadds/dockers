####=======LB------ - внутри kubernetes
---
kind: Service
apiVersion: v1
metadata:
  name: service-ingress # по этому имени обращаемся из сервисов -- curl http://service-ingress
  namespace: prod-01
  labels:
    app: worker-node
  annotations:
    service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
    service.beta.kubernetes.io/do-loadbalancer-size-slug: "lb-large"
    service.beta.kubernetes.io/do-loadbalancer-protocol: "tcp"
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  selector:
    app: worker-node
    tier: frontend
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80 



###------###
#######LB
####apiVersion: v1
####kind: Service
####metadata:
  ####name: ngnix-lb
  ####namespace: prod-01
  ####labels:
    ####app: worker-node
  ####annotations:
    ####service.beta.kubernetes.io/do-loadbalancer-protocol: "http"
    ####service.beta.kubernetes.io/do-loadbalancer-size-slug: "lb-large"
####spec:
  ####type: LoadBalancer
  ####selector:
    ####app: nginx-example
  ####ports:
    ####- name: http
      ####protocol: TCP
      ####port: 80
      ####targetPort: 80


#######EXPOSE
###---
###kind: Service
###apiVersion: v1
###metadata:
  ###name: service-ingress
  ###namespace: prod-01
  ###labels:
    ###app: worker-node
   ####tier: frontend
  ###annotations:
    ###service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
###spec:
  ###type: LoadBalancer
  ###externalTrafficPolicy: Local
  ###selector:
    ###app: worker-node
    ###tier: frontend
  ###ports:
  ###- name: http
    ###protocol: TCP
    ###port: 81
    ###targetPort: 80
  ###externalIPs:
    ###- 192.168.122.152
    ####- 192.168.122.153
