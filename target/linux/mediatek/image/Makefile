include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

include $(SUBTARGET).mk

define Image/Build/SDImage
	./make_bundle_image.sh $(KDIR)/mtk-bpi-r2-SD.img \
			       mtk-bpi-r2-preloader-sd.bin \
			       mtk-bpi-r2-uboot.bin \
			       $(KDIR)/uImage-mt7623n-bananapi-bpi-r2 \
			       $(KDIR)/root.squashfs
endef

define Image/Build/EMMCImage
	./make_bundle_image.sh $(KDIR)/mtk-bpi-r2-EMMC.img \
			       mtk-bpi-r2-preloader-emmc.bin \
			       mtk-bpi-r2-uboot.bin \
			       $(KDIR)/uImage-mt7623n-bananapi-bpi-r2 \
			       $(KDIR)/root.squashfs
endef

define Image/Build
	$(call Image/Build/$(1),$(1))
	$(call Image/Build/SDImage,$(1))
	$(call Image/Build/EMMCImage,$(1))
endef

$(eval $(call BuildImage))
