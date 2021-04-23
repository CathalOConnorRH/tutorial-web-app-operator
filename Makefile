SHELL=/bin/bash
REG=quay.io
ORG=cathaloconnor
IMAGE=tutorial-web-app-operator
TAG=v0.0.63
KUBE_CMD=oc apply -f
DEPLOY_DIR=deploy
OUT_STATIC_DIR=tmp/_output
OUTPUT_BIN_NAME=./tmp/_output/bin/tutorial-web-app-operator
TARGET_BIN=cmd/tutorial-web-app-operator/main.go
OPERATOR_IMAGE=$(REG)/$(ORG)/$(IMAGE):$(TAG)
.PHONY: setup/travis
setup/travis:
	@echo Installing Operator SDK
	@curl -Lo operator-sdk https://github.com/operator-framework/operator-sdk/releases/download/v1.2.0/operator-sdk-v1.2.0-x86_64-linux-gnu && chmod +x operator-sdk && sudo mv operator-sdk /usr/local/bin/

.PHONY: code/compile
code/compile:
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ${OUTPUT_BIN_NAME} ${TARGET_BIN}

.PHONY: code/gen
code/gen:
	$(CONTROLLER_GEN) rbac:roleName=manager-role webhook paths="./..."
	@go generate ./...

.PHONY: code/check
code/check:
	@diff -u <(echo -n) <(gofmt -d `find . -type f -name '*.go' -not -path "./vendor/*"`)
	golint ./pkg/... | grep -v  "comment on" | grep -v "or be unexported"
	go vet ./...

.PHONY: code/fix
code/fix:
	@gofmt -w `find . -type f -name '*.go' -not -path "./vendor/*"`

.PHONY: image/build
image/build: code/compile
	echo "build image $(OPERATOR_IMAGE)"
	docker build . -t ${OPERATOR_IMAGE}

.PHONY: image/build/push
image/build/push: image/build
	@docker push ${REG}/${ORG}/${IMAGE}:${TAG}

.PHONY: test/unit
test/unit:
	go test -v -race -cover ./pkg/...

.PHONY: cluster/prepare
cluster/prepare:
	${KUBE_CMD} ${DEPLOY_DIR}/rbac.yaml
	${KUBE_CMD} ${DEPLOY_DIR}/sa.yaml
	${KUBE_CMD} ${DEPLOY_DIR}/crd.yaml
	${KUBE_CMD} ${DEPLOY_DIR}/cr.yaml

.PHONY: cluster/deploy
cluster/deploy:
	${KUBE_CMD} ${DEPLOY_DIR}/operator.yaml


# find or download controller-gen
# download controller-gen if necessary
controller-gen:
ifeq (, $(shell which controller-gen))
	@{ \
	set -e ;\
	CONTROLLER_GEN_TMP_DIR=$$(mktemp -d) ;\
	cd $$CONTROLLER_GEN_TMP_DIR ;\
	go mod init tmp ;\
	go get sigs.k8s.io/controller-tools/cmd/controller-gen@v0.3.0 ;\
	rm -rf $$CONTROLLER_GEN_TMP_DIR ;\
	}
CONTROLLER_GEN=$(GOBIN)/controller-gen
else
CONTROLLER_GEN=$(shell which controller-gen)
endif



#oc apply -f deploy/rbac.yaml
#W0422 17:06:51.636952  112282 warnings.go:67] rbac.authorization.k8s.io/v1beta1 Role is deprecated in v1.17+, unavailable in v1.22+; use rbac.authorization.k8s.io/v1 Role
#W0422 17:06:51.892365  112282 warnings.go:67] rbac.authorization.k8s.io/v1beta1 Role is deprecated in v1.17+, unavailable in v1.22+; use rbac.authorization.k8s.io/v1 Role
#role.rbac.authorization.k8s.io/tutorial-web-app-operator created
#W0422 17:06:52.017896  112282 warnings.go:67] rbac.authorization.k8s.io/v1beta1 RoleBinding is deprecated in v1.17+, unavailable in v1.22+; use rbac.authorization.k8s.io/v1 RoleBinding
#W0422 17:06:52.296450  112282 warnings.go:67] rbac.authorization.k8s.io/v1beta1 RoleBinding is deprecated in v1.17+, unavailable in v1.22+; use rbac.authorization.k8s.io/v1 RoleBinding
#rolebinding.rbac.authorization.k8s.io/tutorial-web-app-operator created
#oc apply -f deploy/sa.yaml
#serviceaccount/tutorial-web-app-operator created
#oc apply -f deploy/crd.yaml
#W0422 17:06:54.616495  112360 warnings.go:67] apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
#W0422 17:06:54.748528  112360 warnings.go:67] apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
#customresourcedefinition.apiextensions.k8s.io/webapps.integreatly.org created
#oc apply -f deploy/cr.yaml
#webapp.integreatly.org/tutorial-web-app-operator created


#npm info it worked if it ends with ok
#npm info using npm@6.9.0
#npm info using node@v10.16.3
#npm info lifecycle integreatly-web-app@2.28.1~prestart: integreatly-web-app@2.28.1
#npm info lifecycle integreatly-web-app@2.28.1~start: integreatly-web-app@2.28.1
#
#> integreatly-web-app@2.28.1 start /opt/app-root/src
#> node server.js
#
#user database is /opt/user-walkthroughs/webapp.db
#Unhandled rejection SequelizeConnectionError: SQLITE_CANTOPEN: unable to open database file
#    at Database.connections.(anonymous function).lib.Database.err (/opt/app-root/src/node_modules/sequelize/lib/dialects/sqlite/connection-manager.js:61:34)
#npm info lifecycle integreatly-web-app@2.28.1~poststart: integreatly-web-app@2.28.1
#npm timing npm Completed in 813ms
#npm info ok