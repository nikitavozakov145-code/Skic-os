# Skic OS Master Makefile
.PHONY: all clean run iso install kernel apps docs tests

VERSION = 2.0.0
ARCH = x86_64
BUILD_DIR = build
ISO_NAME = skic-os-$(VERSION).iso

all: kernel apps $(BUILD_DIR)/$(ISO_NAME)

kernel:
	$(MAKE) -C kernel

apps:
	$(MAKE) -C apps

$(BUILD_DIR)/$(ISO_NAME): kernel apps
	mkdir -p $(BUILD_DIR)
	$(MAKE) -C boot iso

clean:
	$(MAKE) -C kernel clean
	$(MAKE) -C apps clean
	$(MAKE) -C boot clean
	rm -rf $(BUILD_DIR)

run: $(BUILD_DIR)/$(ISO_NAME)
	qemu-system-x86_64 -cdrom $(BUILD_DIR)/$(ISO_NAME) -m 4G -smp 4 -vga virtio -enable-kvm

install:
	sudo $(MAKE) -C boot install

docs:
	$(MAKE) -C docs

tests:
	$(MAKE) -C tests

check: tests

.PHONY: all clean run iso install kernel apps docs tests check
