#
# Build SqlCipher as a SQL driver plugin for Qt 5
#
# Based on the work of Simon Knopp:
# - https://github.com/sijk/qt5-sqlcipher/tree/old
#
# Simon Knopp, Feb 2014
# Richard Kuesters, Jun 2016
#
#
# NOTE: using amalgamated version of SQLite3 + SQLCipher to use in regular
# desktops, so a bunch of options will not be listed here. I have also splitted
# the compiling process in Windows for the sake of my sanity (many would doubt
# about that).

# ------------------------------------------------------------------------------
# OPTIONS - change values in the respective file. COPY IT FIRST !!!
# ------------------------------------------------------------------------------
win32 {
#    include($$PWD/options_win.pri)
} else:linux {
#    include($$PWD/options_lnx.pri)
}

# ------------------------------------------------------------------------------
# OPTIONS - change values in the respective file. COPY IT FIRST !!!
# ------------------------------------------------------------------------------
win32 {
#    include($$PWD/rules_win.pri)
} else:linux {
#    include($$PWD/rules_lnx.pri)
}

#SQLCIPHER_CONFIGURE = --enable-tempstore=yes \
#                      --disable-tcl \
#                      CFLAGS="-DSQLITE_HAS_CODEC" \
#                      LDFLAGS="-lcrypto"

TARGET = qsqlcipher

win32: MY_QT_SRCDIR = $$shell_quote($$shell_path(E:/bin/qt/5.6.1-msvc2013-x86/5.6/Src/qtbase))
linux: MY_QT_SRCDIR = $$shell_path(/home/richard/tmp/qt5/qt-everywhere-opensource-src-5.7.0/qtbase)

CONFIG(debug, debug|release) {
    SQLCIPHER_OBJECT = $$shell_quote($$shell_path($$OBJECTS_DIR/debug/sqlite3.obj))
} else {
    SQLCIPHER_OBJECT = $$shell_quote($$shell_path($$OBJECTS_DIR/release/sqlite3.obj))
}

#DEFINES += _USING_V120_SDK71_
#DEFINES += SQLITE_HAS_CODEC

#isEmpty(QT_SRCDIR):QT_SRCDIR = qtbase

DRIVER_SRCDIR = $$shell_quote($$shell_path($$MY_QT_SRCDIR/src/sql/drivers/sqlite))
PLUGIN_SRCDIR = $$shell_quote($$shell_path($$MY_QT_SRCDIR/src/plugins/sqldrivers))

SQLCIPHER_SRCDIR = $$shell_quote($$shell_path(E:/includes/sqlite3))
OPENSSL_ROOT = $$shell_quote($$shell_path(E:/lib/openssl-1.0.2h-msvc2013-x86-release-nasm))

INCLUDEPATH += $$shell_quote($$shell_path($$DRIVER_SRCDIR))
INCLUDEPATH += $$SQLCIPHER_SRCDIR

SOURCES += $$PWD/smain.cpp

HEADERS += $$SQLCIPHER_SRCDIR/sqlite3.h

OTHER_FILES += $$PWD/qsqlcipher.json

# Use Qt's SQLite driver for most of the implementation
HEADERS += $$DRIVER_SRCDIR/qsql_sqlite_p.h
SOURCES += $$DRIVER_SRCDIR/qsql_sqlite.cpp

# Don't install in the system-wide plugins directory
CONFIG += force_independent

linux {
    !system-sqlite:!contains(LIBS, .*sqlite3.*) {
    #    CONFIG(release, debug|release):DEFINES *= NDEBUG
        DEFINES += $$SQLITE_DEFINES
        !contains(CONFIG, largefile):DEFINES += SQLITE_DISABLE_LFS
        INCLUDEPATH += $$OUT_PWD/include
        LIBS        += -L$$OUT_PWD/lib -lsqlcipher -lcrypto
        QMAKE_RPATHDIR += $$OUT_PWD/lib
    } else {
#        LIBS *= $$QT_LFLAGS_SQLITE
#        QMAKE_CXXFLAGS *= $$QT_CFLAGS_SQLITE
    }
} else:win32 {
    OBJECTS += $$SQLCIPHER_OBJECT
    QMAKE_CFLAGS += /D_USING_V120_SDK71_
    QMAKE_CXXFLAGS += /D_USING_V120_SDK71_
    QMAKE_CFLAGS += -fp:precise

    QMAKE_LFLAGS += /SUBSYSTEM:WINDOWS,5.01
    QMAKE_LFLAGS += $$shell_quote($$shell_path($$OPENSSL_ROOT/lib/libeay32.lib))
#    QMAKE_LFLAGS += /NODEFAULTLIB:MSVCRTD
#    QMAKE_LFLAGS += /NODEFAULTLIB:MSVCRT

}

PLUGIN_CLASS_NAME = QSQLCipherDriverPlugin
include($$PLUGIN_SRCDIR/qsqldriverbase.pri)

#linux {
#    # Configure sqlcipher
#    config_sqlcipher.target = $$PWD/sqlcipher/Makefile
#    config_sqlcipher.commands = cd $$PWD/sqlcipher && \
#                                ./configure $$SQLCIPHER_CONFIGURE \
#                                    --prefix=$$OUT_PWD

#    ## Build sqlcipher
#    sqlcipher.target = $$OUT_PWD/lib
#    sqlcipher.commands = $(MAKE) -C $$PWD/sqlcipher install
#    sqlcipher.depends = config_sqlcipher

#    ## Configure and build sqlcipher before building the plugin
#    QMAKE_EXTRA_TARGETS += config_sqlcipher sqlcipher
#    PRE_TARGETDEPS += $$sqlcipher.target
#}

win32:{
    # Compile SQLCipher as object (if anyone have a better idea ...)
    # Some compile flags (debug)
    SQLCIPHER_DEFINES *= -D_USING_V120_SDK71_
    SQLCIPHER_DEFINES += -DSQLITE_HAS_CODEC
    SQLCIPHER_DEFINES += -D_CRT_SECURE_NO_WARNINGS
    SQLCIPHER_DEFINES += -DSQLITE_OS_WIN=1
    SQLCIPHER_DEFINES += -DSQLITE_TEMP_STORE=2
    SQLCIPHER_DEFINES += -DSQLITE_API=__declspec(dllexport)
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_API_ARMOR=1
    SQLCIPHER_DEFINES += -DSQLITE_DEBUG=1
    SQLCIPHER_DEFINES += -DSQLITE_FORCE_OS_TRACE=1
    SQLCIPHER_DEFINES += -DSQLITE_DEBUG_OS_TRACE=1
    SQLCIPHER_DEFINES += -DSQLITE_MEMDEBUG=1
    SQLCIPHER_DEFINES += -DSQLITE_THREADSAFE=1
    SQLCIPHER_DEFINES += -DSQLITE_THREAD_OVERRIDE_LOCK=-1
    SQLCIPHER_DEFINES += -DSQLITE_TEMP_STORE=1
    SQLCIPHER_DEFINES += -DSQLITE_MAX_TRIGGER_DEPTH=100
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_FTS3=1
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_RTREE=1
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_COLUMN_METADATA=1

    # Misc Flags
    SQLCIPHER_INCLUDES *= -I$$shell_quote($$shell_path(E:/includes/sqlite3))
    SQLCIPHER_INCLUDES += -I$$shell_quote($$shell_path($$OPENSSL_ROOT/include))

    # Don't touch flags
    SQLCIPHER_C *= /c $$shell_quote($$shell_path(E:/includes/sqlite3/sqlite3.c))
    SQLCIPHER_C += -nologo -MDd -fp:precise -W4 -Fo$$SQLCIPHER_OBJECT

    # Creating command ...
    sqlcipher.target = $$SQLCIPHER_OBJECT
    sqlcipher.depends = FORCE
    sqlcipher.commands = $(CC) $$SQLCIPHER_C $$SQLCIPHER_DEFINES $$SQLCIPHER_INCLUDES

    # Configure and build sqlcipher before building the plugin
    QMAKE_EXTRA_TARGETS += sqlcipher
    PRE_TARGETDEPS += $$sqlcipher.target

}
