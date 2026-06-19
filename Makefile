# SkicBoot Makefile
# Builds bootloader for Skic OS

VERSION = 1.0.0
ARCH = x86_64
TARGET_EFI = $(ARCH)-efi
TARGET_BIOS = i386-pc
PREFIX = /usr
BOOTDIR = /boot
EFIDIR = $(BOOTDIR)/efi/EFI/skic-os

# Source directories
THEME_DIR = themes/skic
FONT_DIR = fonts
LOCALE_DIR = locales
SCRIPT_DIR = scripts
MODULE_DIR = modules

# Output files
OUTPUT_EFI = build/efi/skic-boot.efi
OUTPUT_BIOS = build/bios/skic-boot.bin
OUTPUT_ISO = build/iso/skic-boot-$(VERSION).iso

# Tools
GRUB_MKIMAGE = grub-mkimage
GRUB_MKRESCUE = grub-mkrescue
GRUB_INSTALL = grub-install
OBJCOPY = objcopy
NASM = nasm
MKDIR = mkdir -p
CP = cp -r
RM = rm -rf

# GRUB modules for EFI
EFI_MODULES = \
	all_video \
	boot \
	btrfs \
	cat \
	chain \
	configfile \
	echo \
	efifwsetup \
	efinet \
	ext2 \
	fat \
	font \
	gettext \
	gfxmenu \
	gfxterm \
	gfxterm_background \
	gzio \
	halt \
	help \
	hfsplus \
	iso9660 \
	jpeg \
	loadenv \
	loopback \
	linux \
	lvm \
	mdraid09 \
	mdraid1x \
	memdisk \
	menu \
	minicmd \
	normal \
	ntfs \
	part_apple \
	part_gpt \
	part_msdos \
	password_pbkdf2 \
	png \
	procfs \
	reboot \
	regexp \
	search \
	search_fs_uuid \
	search_fs_file \
	search_label \
	sleep \
	smbios \
	squash4 \
	terminal \
	test \
	true \
	video \
	xfs \
	zfs \
	zstd

# BIOS modules
BIOS_MODULES = \
	$(EFI_MODULES) \
	ata \
	ahci \
	ohci \
	uhci \
	ehci \
	xhci \
	usb \
	usbms \
	usb_keyboard \
	keylayouts \
	at_keyboard \
	serial

.PHONY: all efi bios iso clean install uninstall help

all: efi bios iso

# Build EFI bootloader
efi: $(OUTPUT_EFI)

$(OUTPUT_EFI): $(MODULE_DIR)/*.mod $(THEME_DIR)/* $(FONT_DIR)/* $(SCRIPT_DIR)/*
	@echo "Building EFI bootloader..."
	$(MKDIR) build/efi
	$(GRUB_MKIMAGE) \
		-p /boot/grub \
		-o $(OUTPUT_EFI) \
		-O $(TARGET_EFI) \
		-c grub-early.cfg \
		$(EFI_MODULES)
	@echo "EFI bootloader built: $(OUTPUT_EFI)"

# Build BIOS bootloader
bios: $(OUTPUT_BIOS)

$(OUTPUT_BIOS): $(MODULE_DIR)/*.mod
	@echo "Building BIOS bootloader..."
	$(MKDIR) build/bios
	$(NASM) -f bin -o $(OUTPUT_BIOS) boot/stage1.asm
	cat boot/stage2.bin >> $(OUTPUT_BIOS)
	@echo "BIOS bootloader built: $(OUTPUT_BIOS)"

# Build bootable ISO
iso: $(OUTPUT_ISO)

$(OUTPUT_ISO): efi bios
	@echo "Building bootable ISO..."
	$(MKDIR) build/iso/boot/grub
	$(MKDIR) build/iso/EFI/BOOT
	# Copy EFI bootloader
	$(CP) $(OUTPUT_EFI) build/iso/EFI/BOOT/BOOTX64.EFI
	# Copy BIOS bootloader
	$(CP) $(OUTPUT_BIOS) build/iso/boot/grub/skic-boot.bin
	# Copy configuration
	$(CP) boot/grub/grub.cfg build/iso/boot/grub/
	$(CP) $(THEME_DIR) build/iso/boot/grub/themes/
	$(CP) $(FONT_DIR)/unicode.pf2 build/iso/boot/grub/fonts/
	$(CP) $(LOCALE_DIR)/*.mo build/iso/boot/grub/locales/
	# Create ISO
	$(GRUB_MKRESCUE) \
		-o $(OUTPUT_ISO) \
		--volid="SKIC_BOOT_$(VERSION)" \
		build/iso/
	@echo "ISO built: $(OUTPUT_ISO)"

# Install to system
install: all
	@echo "Installing SkicBoot..."
	# Install EFI
	if [ -d "/sys/firmware/efi" ]; then \
		$(MKDIR) $(EFIDIR); \
		$(CP) $(OUTPUT_EFI) $(EFIDIR)/grubx64.efi; \
	fi
	# Install BIOS
	$(CP) $(OUTPUT_BIOS) $(BOOTDIR)/grub/skic-boot.bin
	# Install configuration
	$(CP) boot/grub/grub.cfg $(BOOTDIR)/grub/
	$(CP) $(THEME_DIR) $(BOOTDIR)/grub/themes/
	$(CP) $(FONT_DIR)/unicode.pf2 $(BOOTDIR)/grub/fonts/
	$(CP) $(LOCALE_DIR)/*.mo $(BOOTDIR)/grub/locales/
	$(CP) $(SCRIPT_DIR)/*.cfg $(BOOTDIR)/grub/scripts/
	# Update GRUB
	update-grub 2>/dev/null || grub-mkconfig -o $(BOOTDIR)/grub/grub.cfg
	@echo "Installation complete!"

# Uninstall
uninstall:
	@echo "Uninstalling SkicBoot..."
	$(RM) $(EFIDIR)
	$(RM) $(BOOTDIR)/grub/themes/skic
	$(RM) $(BOOTDIR)/grub/scripts/skic-*.cfg
	$(RM) $(BOOTDIR)/grub/skic-boot.bin
	@echo "SkicBoot uninstalled"

# Clean build files
clean:
	$(RM) build
	@echo "Build files cleaned"

# Help
help:
	@echo "SkicBoot Makefile v$(VERSION)"
	@echo ""
	@echo "Targets:"
	@echo "  all      Build everything (EFI, BIOS, ISO)"
	@echo "  efi      Build EFI bootloader"
	@echo "  bios     Build BIOS bootloader"
	@echo "  iso      Build bootable ISO"
	@echo "  install  Install to system"
	@echo "  uninstall Remove from system"
	@echo "  clean    Clean build files"
	@echo "  help     Show this help"

# Dependencies
$(MODULE_DIR)/%.mod:
	@echo "Module $@ is required"
	@false

# Check for required tools
check-tools:
	@command -v $(GRUB_MKIMAGE) >/dev/null 2>&1 || { echo "GRUB tools not found"; exit 1; }
	@command -v $(NASM) >/dev/null 2>&1 || { echo "NASM not found"; exit 1; }
	@echo "All required tools found"

$(TARGET): $(KERNEL)
	mkdir -p isodir/boot/grub isodir/etc isodir/home isodir/kernel isodir/lib isodir/run isodir/sbin isodir/src isodir/sys isodir/usr isodir/var
	cp $(KERNEL) isodir/boot/
	cp grub.cfg isodir/boot/grub/
	$(GRUB) -o $@ isodir