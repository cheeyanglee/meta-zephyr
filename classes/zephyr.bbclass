

inherit terminal

OE_TERMINAL_EXPORTS += "HOST_EXTRACFLAGS HOSTLDFLAGS TERMINFO CROSS_CURSES_LIB CROSS_CURSES_INC"
HOST_EXTRACFLAGS = "${BUILD_CFLAGS} ${BUILD_LDFLAGS}"
HOSTLDFLAGS = "${BUILD_LDFLAGS}"
CROSS_CURSES_LIB = "-lncurses -ltinfo"
CROSS_CURSES_INC = '-DCURSES_LOC="<curses.h>"'
TERMINFO = "${STAGING_DATADIR_NATIVE}/terminfo"

KCONFIG_CONFIG_COMMAND ??= "menuconfig"

python () {
    # Translate MACHINE into Zephyr BOARD
    # Zephyr BOARD is basically our MACHINE, except we must use "-" instead of "_"
    board = d.getVar('MACHINE',True)
    board = board.replace('-', '_')
    d.setVar('BOARD',board)
}

python do_menuconfig() {
    os.chdir(d.getVar('ZEPHYR_SRC_DIR', True))
    configdir = d.getVar('ZEPHYR_SRC_DIR', True) + '/outdir/' + d.getVar('BOARD', True)
    try:
        mtime = os.path.getmtime(configdir +"/.config")
    except OSError:
        mtime = 0

    oe_terminal("${SHELL} -c \"ZEPHYR_BASE=%s make BOARD=%s %s; if [ \$? -ne 0 ]; then echo 'Command failed.'; \
                printf 'Press any key to continue... '; \
                read r; fi\"" % (d.getVar('ZEPHYR_BASE', True), d.getVar('BOARD', True),d.getVar('KCONFIG_CONFIG_COMMAND', True)),
                d.getVar('PN', True) + ' Configuration', d)

    try:
        newmtime = os.path.getmtime(configdir +"/.config")
    except OSError:
        newmtime = 0

    if newmtime > mtime:
        bb.warn("Configuration changed, recompile will be forced")
        bb.build.write_taint('do_compile', d)
}
do_menuconfig[depends] += "ncurses-native:do_populate_sysroot"
do_menuconfig[nostamp] = "1"
do_menuconfig[dirs] = "${B}"
addtask menuconfig after do_configure

python do_devshell_prepend () {
    # Most likely we need to manually edit prj.conf...
    os.chdir(d.getVar('ZEPHYR_SRC_DIR', True))
}

