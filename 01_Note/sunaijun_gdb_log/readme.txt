gdb 调试qemu，需要注意几点：
1.qemu 编译的时候要打开调试开关。

2.那个qemu_start.sh文件中删掉记录guest的log日志的那行脚本，因为它会导致gdb老是不停的断在guest的串口输出上。
  这么做的影响，就是不会记录下来qemu.log日志文件。

3.多学学gdb调试吧，这样就可以调试kernel上的qemu程序，还有其他程序。

4.也多学习一下linux的调试的技巧。


刚从网页 http://www.linuxidc.com/Linux/2014-08/105510.htm 得到信息，
调试kernel，常规方法是使用printk和jtag，此外还可以使用qemu来做。因为qemu有gdb server。

此外，这个网页也介绍了linux内核调试的方法
http://my.oschina.net/fgq611/blog/113249
