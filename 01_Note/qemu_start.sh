#!/bin/sh

VAR_MAX_CPUS=4

###  FOR DEBUG USE ###
#VAR_KERNEL_DEBUG="-S -gdb tcp::1238"
#VAR_KGDB_CFG="kgdboc=ttyAMA1,115200 kgdbwait"

/system/usr/local/bin/qemu-system-arm >/data/slog/qemu.log 2>&1 \
	$VAR_KERNEL_DEBUG \
	-monitor telnet::1234,server,nowait  \
	-serial telnet::1235,server,nowait  \
	-serial telnet::1236,server,nowait  \
	-serial telnet::1237,server,nowait  \
	-nographic        \
	-k en-us       \
	-enable-kvm    \
	-kernel /storage/sdcard0/vImage  \
	-m 384          \
	-M vexpress-a15 \
	-cpu cortex-a15 \
	-smp $VAR_MAX_CPUS \
	-d guest_errors  \
	-D /data/slog/qemu.log  \
	-drive file=/dev/block/mmcblk1p1,id=virtio-blk,if=none \
	-device virtio-blk-device,drive=virtio-blk \
	-netdev user,id=net0,net=10.0.10.0/24,tftp=/data/local/tmp \
	-device virtio-net-device,netdev=net0,mac=52:54:00:12:34:62 \
	-redir tcp:2323:10.0.10.15:23 \
	-device virtio-serial-device \
	-chardev socket,path=/dev/socket/switchos,server,nowait,id=switchos \
	-device virtserialport,chardev=switchos,name=sprd.vport.1 \
	-chardev socket,path=/dev/socket/rilproxy,server,nowait,id=rilproxy \
	-device virtserialport,chardev=rilproxy,name=sprd.vport.2 \
	-chardev socket,path=/dev/socket/audioctl,server,nowait,id=audioctl \
	-device virtserialport,chardev=audioctl,name=sprd.vport.3 \
	-chardev socket,path=/dev/socket/audiocap,server,nowait,id=audiocap \
	-device virtserialport,chardev=audiocap,name=sprd.vport.4 \
	-chardev socket,path=/dev/socket/audiopb,server,nowait,id=audiopb \
	-device virtserialport,chardev=audiopb,name=sprd.vport.5 \
	-append "virtio_mmio.device=0x200@0x1c130200:73:0 \
             virtio_mmio.device=0x200@0x1c130400:74:1 \
             virtio_mmio.device=0x200@0x1c130600:75:2 \
             init=/init console=ttyAMA0 mem=384M root=/dev/vda rw \
             earlyprintk=serial androidboot.hardware=vshark"
