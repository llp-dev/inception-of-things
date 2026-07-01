# Bootstrap image builder — Alpine + Docker + k3d + kubectl + Vagrant (QEMU/KVM)
# Uses alpine-make-vm-image (official Alpine script, no Packer required).

OUTPUT    := output/alpine-bootstrap.qcow2
BUILDER   := alpine-make-vm-image
BUILDER_URL := https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/master/alpine-make-vm-image

MEMORY   := 8192
CPUS     := 8
SSH_PORT := 2222   # host port → VM :22
UI_PORT  := 8080   # host port → VM :8080  (Argo CD)
APP_PORT := 8888   # host port → VM :8888  (wil-playground)

.PHONY: build run ssh clean

# Download the builder script if missing, then build the image.
build: $(BUILDER)
	mkdir -p output
	sudo ./$(BUILDER) \
	  --image-format qcow2 \
	  --image-size 20G \
	  --repositories-file repositories \
	  --packages "$(shell tr '\n' ' ' < packages.txt)" \
	  --script-chroot provision.sh \
	  $(OUTPUT)

$(BUILDER):
	curl -sLo $(BUILDER) $(BUILDER_URL)
	chmod +x $(BUILDER)

# Boot the image (-cpu host passes VMX/SVM flags for nested Vagrant VMs).
run: $(OUTPUT)
	qemu-system-x86_64 \
	  -enable-kvm \
	  -cpu host \
	  -m $(MEMORY) \
	  -smp $(CPUS) \
	  -drive file=$(OUTPUT),format=qcow2,if=virtio \
	  -netdev user,id=net0,\
	hostfwd=tcp::$(SSH_PORT)-:22,\
	hostfwd=tcp::$(UI_PORT)-:8080,\
	hostfwd=tcp::$(APP_PORT)-:8888 \
	  -device virtio-net-pci,netdev=net0 \
	  -nographic

# SSH into the running VM.
ssh:
	ssh -p $(SSH_PORT) -o StrictHostKeyChecking=no root@127.0.0.1

# Remove build output and the downloaded builder script.
clean:
	rm -rf output/ $(BUILDER)
