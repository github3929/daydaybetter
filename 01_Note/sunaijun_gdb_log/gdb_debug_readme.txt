gdb 调试qemu，需要注意几点：
1.qemu 编译的时候要打开调试开关。



2.那个qemu_start.sh文件中删掉记录guest的log日志的那行脚本，因为它会导致gdb老是不停的断在guest的串口输出上。
  这么做的影响，就是不会记录下来qemu.log日志文件。

3.多学学gdb调试吧，这样就可以调试kernel上的qemu程序，还有其他程序。

4.也多学习一下linux的调试的技巧。

5.然后ren.geng写过一个调试android程序的文章，在wiki上。

刚从网页 http://www.linuxidc.com/Linux/2014-08/105510.htm 得到信息，
调试kernel，常规方法是使用printk和jtag，此外还可以使用qemu来做。因为qemu有gdb server。

此外，这个网页也介绍了linux内核调试的方法
http://my.oschina.net/fgq611/blog/113249

=============================

详细的调试步骤:

step1：
按照Dual-OS Development Guide.pdf文档指示的方法，修改/vendor/sprd/open-source/ vendorsetup.sh，编译出调试版本的qemu

step2：
a.在手机sudo adb shell之前，sudo adb remount
b.stop firmos --->注意不是kill -9 process_id命令
c.将生成的qemu-system-arm文件 push到手机上的 ./firmboot/qemu/bin/qemu-system-arm 目录下，替换原先的版本。

---->另外，发现我们的rc文件是 init.board.rc，开启qemu服务的脚本就在这个里边。
---->代码中，host端开启服务的地方是(/home/apuser/multi-os/device/sprd/scx35l_sp9630ea/init.board.rc)
---->代码中，guest端开启服务的地方是/home/apuser/multi-os/device/sprd/vshark/init.board.rc

目标程序的位置在：
/home/apuser/multi-os/vendor/sprd/qemu/arm-softmmu/qemu-system-arm

step3：	
修改qemu的start文件，首先修改该文件的名称，目的是为了让下次手机启动的时候，qemu暂时不启动，然后手工执行该文件启动。目录如下：

./firmboot/qemu_start_d.sh  将文件内容修改为：---->这个文件的位置在 /home/apuser/github3929/daydaybetter/01_Note/sunaijun_gdb_log目录下

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

step4：
然后一定要先在手机shell下运行启动该脚本文件 ./firmboot/qemu_start_d.sh

然后在PC上做adb映射：
~/a.multi-os/vendor/sprd/qemu$ sudo adb forward tcp:1238 tcp:1238


然后在手机上导入path如下这些环境变量(可能只有最后一组是我们要用的)：
export PATH=/usr/java/jdk1.6.0_29/bin:/home/apuser/multi-os/out/host/linux-x86/bin:/home/apuser/multi-os/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.7/bin:/home/apuser/multi-os/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin:/home/apuser/multi-os/prebuilts/gcc/linux-x86/mips/mipsel-linux-android-4.7/bin:/home/apuser/multi-os/development/emulator/qtools:/home/apuser/multi-os/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.7/bin:/home/apuser/multi-os/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin:/home/apuser/multi-os/development/scripts:/home/apuser/multi-os/prebuilts/devtools/tools:/usr/java/jdk1.6.0_29/bin:/usr/java/jdk1.6.0_29/jre/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games::/home/apuser/multi-os/prebuilts/gcc/linux-x86/arm/gcc-linaro-arm-linux-gnueabihf-4.8/bin/

然后再在PC上如下目录运行如下命令：
~/a.multi-os/vendor/sprd/qemu$ arm-linux-gnueabihf-gdb arm-softmmu/qemu-system-arm

最后在gdb的环境下，通过如下命令连向手机上的gdb server。
target remote :1238

===============
cd vendor/sprd/qemu/
arm-linux-gnueabihf-gdb arm-softmmu/qemu-system-arm  ---》arm-linux-gnueabihf-gdb命令在source和lunch后就添加到系统路径里了
