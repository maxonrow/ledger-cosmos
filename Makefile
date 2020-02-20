#*******************************************************************************
#*   (c) 2019 ZondaX GmbH
#*
#*  Licensed under the Apache License, Version 2.0 (the "License");
#*  you may not use this file except in compliance with the License.
#*  You may obtain a copy of the License at
#*
#*      http://www.apache.org/licenses/LICENSE-2.0
#*
#*  Unless required by applicable law or agreed to in writing, software
#*  distributed under the License is distributed on an "AS IS" BASIS,
#*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#*  See the License for the specific language governing permissions and
#*  limitations under the License.
#********************************************************************************

.PHONY: all deps build clean load delete

LEDGER_COSMOS_SRC=$(CURDIR)/src/ledger-user
LEDGER_TENDERMINT_SRC=$(CURDIR)/src/ledger-val

DOCKER_IMAGE=skywills87/ledger-docker-bolos
DOCKER_BOLOS_SDK=/project/deps/nanos-secure-sdk

DOCKER_IMAGE=skywills87/ledger-docker-bolos
DOCKER_BOLOS_SDK=/project/deps/nanos-secure-sdk
DOCKER_IMAGE2=zondax/ledger_bolos2
DOCKER_BOLOS_SDK2=/project/deps/nano2-sdk

SCP_PUBKEY=049bc79d139c70c83a4b19e8922e5ee3e0080bb14a2e8b0752aa42cda90a1463f689b0fa68c1c0246845c2074787b649d0d8a6c0b97d4607065eee3057bdf16b83
SCP_PRIVKEY=ff701d781f43ce106f72dc26a46b6a83e053b5d07bb3d4ceab79c91ca822a66b

all: build

deps:
	@echo "Install dependencies"
	$(CURDIR)/src/install_deps.sh

build_cosmos:
	docker run -i --rm \
	-e BOLOS_SDK=$(DOCKER_BOLOS_SDK) -e BOLOS_ENV=/opt/bolos \
	-u $(shell id -u) -v $(shell pwd):/project \
	$(DOCKER_IMAGE) \
	make -C /project/src/ledger-user

build_cosmos2:
	docker run -i --rm \
	-e BOLOS_SDK=$(DOCKER_BOLOS_SDK2) -e BOLOS_ENV=/opt/bolos \
	-u $(shell id -u) -v $(shell pwd):/project \
	$(DOCKER_IMAGE2) \
	make -C /project/src/ledger-user

build_tendermint:
	docker run -i --rm \
	-e BOLOS_SDK=$(DOCKER_BOLOS_SDK) -e BOLOS_ENV=/opt/bolos \
	-u $(shell id -u) -v $(shell pwd):/project \
	$(DOCKER_IMAGE) \
	make -C /project/src/ledger-val

build_tendermint2:
	docker run -i --rm \
	-e BOLOS_SDK=$(DOCKER_BOLOS_SDK2) -e BOLOS_ENV=/opt/bolos \
	-u $(shell id -u) -v $(shell pwd):/project \
	$(DOCKER_IMAGE2) \
	make -C /project/src/ledger-val

clean_cosmos:
	BOLOS_SDK=$(CURDIR)/deps/nanos-secure-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_COSMOS_SRC) clean

clean_tendermint:
	BOLOS_SDK=$(CURDIR)/deps/nanos-secure-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_TENDERMINT_SRC) clean

load_cosmos: build_cosmos
	SCP_PRIVKEY=$(SCP_PRIVKEY) \
	BOLOS_SDK=$(CURDIR)/deps/nanos-secure-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_COSMOS_SRC) load

load_cosmos2: build_cosmos2
	SCP_PRIVKEY=$(SCP_PRIVKEY) \
	BOLOS_SDK=$(CURDIR)/deps/nano2-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_COSMOS_SRC) load

load_tendermint: build_tendermint
	SCP_PRIVKEY=$(SCP_PRIVKEY) \
	BOLOS_SDK=$(CURDIR)/deps/nanos-secure-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_TENDERMINT_SRC) load

load_tendermint2: build_tendermint2
	SCP_PRIVKEY=$(SCP_PRIVKEY) \
	BOLOS_SDK=$(CURDIR)/deps/nano2-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_TENDERMINT_SRC) load

delete_cosmos:
	SCP_PRIVKEY=$(SCP_PRIVKEY) \
	BOLOS_SDK=$(CURDIR)/deps/nanos-secure-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_COSMOS_SRC) delete

delete_tendermint:
	SCP_PRIVKEY=$(SCP_PRIVKEY) \
	BOLOS_SDK=$(CURDIR)/deps/nanos-secure-sdk BOLOS_ENV=/opt/bolos \
	make -C $(LEDGER_TENDERMINT_SRC) delete

# This target will initialize the device with the integration testing mnemonic
dev_init:
	@echo "Initializing device with test mnemonic! WARNING TAKES 2 MINUTES AND REQUIRES RECOVERY MODE"
	@python -m ledgerblue.hostOnboard --apdu --id 0 --prefix "" --passphrase "" --pin 5555 --words "equip will roof matter pink blind book anxiety banner elbow sun young"

# This target will setup a custom developer certificate
dev_ca:
	@python -m ledgerblue.setupCustomCA --targetId 0x31100004 --public $(SCP_PUBKEY) --name zondax

dev_ca_delete:
	@python -m ledgerblue.resetCustomCA --targetId 0x31100004

clean: clean_cosmos clean_tendermint
build: build_cosmos build_tendermint
load: build load_cosmos load_tendermint
delete: delete_cosmos delete_tendermint
