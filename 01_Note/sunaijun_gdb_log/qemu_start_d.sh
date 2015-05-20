#!/bin/sh

VAR_MAX_CPUS=4
BOOT_PARAM=ramdisk.img

if [ "$1" = "boot" ]; then
	BOOT_PARAM=ramdisk.img
fi

if [ "$1" = "recovery" ]; then
        BOOT_PARAM=ramdisk-recovery.img
fi

###  FOR DEBUG USE ###
#VAR_KERNEL_DEBUG="-S -gdb tcp::1238"
#VAR_KGDB_CFG="kgdboc=ttyAMA1,115200 kgdbwait"

gdbserver :1238 \
/firmboot/qemu/bin/qemu-system-arm >/data/slog/qemu.log 2>&1 \
	$VAR_KERNEL_DEBUG \
	-monitor telnet::1234,server,nowait \
	-serial telnet::1235,server,nowait  \
	-serial telnet::1236,server,nowait  \
	-serial telnet::1237,server,nowait  \
	-nographic        \
	-k en-us       \
	-enable-kvm    \
	-kernel /firmboot/vImage  \
	-initrd /firmboot/"$BOOT_PARAM" \
	-inputevtconf /firmboot/qemu/etc/qemu/input_event.conf \
	-m 384          \
	-M vexpress-a15 \
	-cpu cortex-a15 \
	-smp $VAR_MAX_CPUS \
	-d guest_errors  \
	-D /data/slog/qemu.log  \
	-drive file=/dev/block/mmcblk0p21,id=virtio-data,if=none \
	-device virtio-blk-device,drive=virtio-data \
	-drive file=/dev/block/mmcblk0p20,id=virtio-sys,if=none \
	-device virtio-blk-device,drive=virtio-sys \
	-netdev user,id=net0,net=10.0.10.0/24,tftp=/data/local/tmp \
	-device virtio-net-device,netdev=net0,mac=52:54:00:12:34:62 \
	-redir tcp:2323:10.0.10.15:23 \
	-device virtio-serial-device \
	-chardev socket,path=/dev/multios/switchos,server,nowait,id=switchos \
	-device virtserialport,chardev=switchos,name=sprd.vport.1 \
	-chardev socket,path=/dev/multios/modemd,server,nowait,id=modemd \
	-device virtserialport,chardev=modemd,name=sprd.vport.2 \
	-chardev tty,path=/dev/stty_lte3,id=chn3 \
	-device virtserialport,chardev=chn3,name=sprd.vport.3 \
	-chardev tty,path=/dev/stty_lte4,id=chn4 \
	-device virtserialport,chardev=chn4,name=sprd.vport.4 \
	-chardev tty,path=/dev/stty_lte5,id=chn5 \
	-device virtserialport,chardev=chn5,name=sprd.vport.5 \
	-chardev socket,path=/dev/multios/audioctl,server,nowait,id=audioctl \
	-device virtserialport,chardev=audioctl,name=sprd.vport.6 \
	-chardev socket,path=/dev/multios/audiocap,server,nowait,id=audiocap \
	-device virtserialport,chardev=audiocap,name=sprd.vport.7 \
	-chardev socket,path=/dev/multios/audiopb,server,nowait,id=audiopb \
	-device virtserialport,chardev=audiopb,name=sprd.vport.8 \
	-append "virtio_mmio.device=0x200@0x1c130200:73:0 \
             virtio_mmio.device=0x200@0x1c130400:74:1 \
             virtio_mmio.device=0x200@0x1c130600:75:2 \
             virtio_mmio.device=0x200@0x1c130000:72:3 \
             init=/init console=ttyAMA0 mem=384M \
             earlyprintk=serial androidboot.hardware=vshark"
