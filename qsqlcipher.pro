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
# about that). See README.md for more details.

TARGET = qsqlcipher
SHARED_FLAGS =

# ------------------------------------------------------------------------------
# OPTIONS - change values in the respective file. COPY IT FIRST !!!
# ------------------------------------------------------------------------------
win32 {
    include($$PWD/options_win.pri)
} else:linux {
#    include($$PWD/options_lnx.pri)  # TODO
}

QTBASE_SRC = $$shell_quote($$shell_path($$QTBASE_SRC))
DRIVER_SRCDIR = $$shell_quote($$shell_path($$QTBASE_SRC/src/sql/drivers/sqlite))
PLUGIN_SRCDIR = $$shell_quote($$shell_path($$QTBASE_SRC/src/plugins/sqldrivers))
SQLCIPHER_SRCDIR = $$shell_quote($$shell_path($$_PRO_FILE_PWD_/sqlcipher-src))

CONFIG(debug, debug|release) {
    OPENSSL_PATH = $$shell_quote($$shell_path($$(CUSTOM_LIBPATH)/openssl/1.0.2h/msvc2013-x86-asm-shared-debug))  # for now this is set by hand
} else {
    OPENSSL_PATH = $$shell_quote($$shell_path($$(CUSTOM_LIBPATH)/openssl/1.0.2h/msvc2013-x86-asm-shared-release))  # for now this is set by hand
}

################################################################################
# things should not be changed from here on (*I THINK*)

CONFIG(debug, debug|release) {
    SQLCIPHER_OBJECT = $$shell_quote($$shell_path($$OBJECTS_DIR/debug/$$SQLCIPHER_OBJ))
} else {
    SQLCIPHER_OBJECT = $$shell_quote($$shell_path($$OBJECTS_DIR/release/$$SQLCIPHER_OBJ))
}

INCLUDEPATH += $$shell_quote($$shell_path($$DRIVER_SRCDIR))
INCLUDEPATH += $$SQLCIPHER_SRCDIR

!exists($$SQLCIPHER_SRCDIR):{
    error("SQLCIPHER_SRCDIR is not valid. Please, run environment prepare scripts. See README.md for more details.")
}

SOURCES += $$PWD/smain.cpp

HEADERS += $$SQLCIPHER_SRCDIR/sqlite3.h

OTHER_FILES += $$PWD/qsqlcipher.json

# Use Qt's SQLite driver for most of the implementation
HEADERS += $$DRIVER_SRCDIR/qsql_sqlite_p.h
SOURCES += $$DRIVER_SRCDIR/qsql_sqlite.cpp

# Don't install in the system-wide plugins directory
CONFIG += force_independent

linux {  # TODO
#    !system-sqlite:!contains(LIBS, .*sqlite3.*) {
    #    CONFIG(release, debug|release):DEFINES *= NDEBUG
#        DEFINES += $$SQLITE_DEFINES
#        !contains(CONFIG, largefile):DEFINES += SQLITE_DISABLE_LFS
#        INCLUDEPATH += $$OUT_PWD/include
#        LIBS        += -L$$OUT_PWD/lib -lsqlcipher -lcrypto
#        QMAKE_RPATHDIR += $$OUT_PWD/lib
#    } else {
#        LIBS *= $$QT_LFLAGS_SQLITE
#        QMAKE_CXXFLAGS *= $$QT_CFLAGS_SQLITE
#    }
} else:win32 {
    OBJECTS += $$SQLCIPHER_OBJECT
    QMAKE_CFLAGS += /D_USING_V110_SDK71_
    QMAKE_CFLAGS += -fp:precise
    QMAKE_CXXFLAGS += /D_USING_V110_SDK71_

    equals(WINXP_COMPAT, 1):{
        QMAKE_LFLAGS_WINDOWS += /SUBSYSTEM:WINDOWS,5.01
        QMAKE_LFLAGS_CONSOLE += /SUBSYSTEM:CONSOLE,5.01
    }

    QMAKE_LFLAGS += $$shell_quote($$shell_path($$OPENSSL_PATH/lib/libeay32.lib))
    CONFIG(debug, debug|release) {
        QMAKE_LFLAGS += /NODEFAULTLIB:MSVCRT
    } else {
        QMAKE_LFLAGS += /NODEFAULTLIB:MSVCRTD
    }
}

PLUGIN_CLASS_NAME = QSQLCipherDriverPlugin
include($$PLUGIN_SRCDIR/qsqldriverbase.pri)

#linux {  # TODO
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

    SQLCIPHER_DEFINES *= -D_USING_V110_SDK71_
    SQLCIPHER_DEFINES += -D_CRT_SECURE_NO_WARNINGS
    SQLCIPHER_DEFINES += -DNO_TCL=1
    SQLCIPHER_DEFINES += -DSQLITE_OS_WIN=1
    SQLCIPHER_DEFINES += -DSQLITE_HAS_CODEC
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_API_ARMOR=1
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_COLUMN_METADATA=1
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_RTREE=1
    SQLCIPHER_DEFINES += -DSQLITE_DEFAULT_FOREIGN_KEYS=1
    SQLCIPHER_DEFINES += -DSQLITE_ENABLE_FTS3=1
    SQLCIPHER_DEFINES += -DSQLITE_THREADSAFE=1
    SQLCIPHER_DEFINES += -DSQLITE_THREAD_OVERRIDE_LOCK=-1

    isEmpty(MAX_ARCH):{
        MAX_ARCH = SSE2
    }

    SQLCIPHER_EXTRA_FLAGS *= -nologo
    SQLCIPHER_EXTRA_FLAGS += /arch:$$MAX_ARCH

    CONFIG(debug, debug|release) {
        # Some compile flags (debug)
        SQLCIPHER_DEFINES += -DSQLITE_DEBUG=1
        SQLCIPHER_DEFINES += -DSQLITE_FORCE_OS_TRACE=1
        SQLCIPHER_DEFINES += -DSQLITE_DEBUG_OS_TRACE=1
        SQLCIPHER_DEFINES += -DSQLITE_MEMDEBUG=1
        SQLCIPHER_DEFINES += -DSQLITE_TEMP_STORE=1
        SQLCIPHER_DEFINES += -DSQLITE_MAX_TRIGGER_DEPTH=100

        SQLCIPHER_EXTRA_FLAGS += -MDd
        SQLCIPHER_EXTRA_FLAGS += -fp:precise
        SQLCIPHER_EXTRA_FLAGS += -W4
        SQLCIPHER_EXTRA_FLAGS += -Od
    } else {
        # RELEASE (THE KRAKEN!!)
        SQLCIPHER_DEFINES += -DNDEBUG
        SQLCIPHER_DEFINES += -DHAVE_LOCALTIME_S
        SQLCIPHER_DEFINES += -DSQLITE_TEMP_STORE=2
        SQLCIPHER_DEFINES += -DSQLITE_DEFAULT_SYNCHRONOUS=0
        SQLCIPHER_DEFINES += -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=0
        SQLCIPHER_DEFINES += -DSQLITE_ENABLE_EXTFUNC=1
        SQLCIPHER_DEFINES += -DSQLITE_OMIT_TCL_VARIABLE=1
        SQLCIPHER_DEFINES += -DSQLITE_ENABLE_FTS3_TOKENIZER=1
#        SQLCIPHER_DEFINES += -DSQLITE_ENABLE_FTS4=1
        SQLCIPHER_DEFINES += -DSQLITE_OMIT_PROGRESS_CALLBACK=1
        SQLCIPHER_DEFINES += -DSQLITE_OMIT_COMPILEOPTION_DIAGS=1
        SQLCIPHER_DEFINES += -DSQLITE_DEFAULT_WORKER_THREADS=1
        SQLCIPHER_DEFINES += -DSQLITE_MAX_WORKER_THREADS=3
        SQLCIPHER_DEFINES += -DSQLITE_POWERSAFE_OVERWRITE=1
        SQLCIPHER_DEFINES += -DSQLITE_DIRECT_OVERFLOW_READ=1
        SQLCIPHER_DEFINES += -DSQLITE_SECURE_DELETE=1
        SQLCIPHER_DEFINES += -DSQLITE_ENABLE_UNLOCK_NOTIFY=1
        SQLCIPHER_DEFINES += -DSQLITE_DISABLE_LFS=1
        SQLCIPHER_DEFINES += -DSQLITE_WIN32_MALLOC=1
        SQLCIPHER_DEFINES += -DSQLITE_WIN32_HEAP_CREATE=1
        SQLCIPHER_DEFINES += -DSQLITE_WIN32_MALLOC_VALIDATE=0

        SQLCIPHER_EXTRA_FLAGS += -MD
        SQLCIPHER_EXTRA_FLAGS += -fp:precise
        SQLCIPHER_EXTRA_FLAGS += -W3
        SQLCIPHER_EXTRA_FLAGS += -O2
    }

    SQLCIPHER_DEFINES += -DSQLITE_API=__declspec(dllexport)

    # Misc Flags
    SQLCIPHER_INCLUDES *= -I$$SQLCIPHER_SRCDIR
    SQLCIPHER_INCLUDES += -I$$shell_quote($$shell_path($$OPENSSL_PATH/include))

    # Don't touch flags
    SQLCIPHER_C *= /c $$shell_quote($$shell_path($$SQLCIPHER_SRCDIR/sqlite3.c))
    SQLCIPHER_C += $$SQLCIPHER_EXTRA_FLAGS -Fo$$SQLCIPHER_OBJECT

    # Creating command ...
    sqlcipher.target = $$SQLCIPHER_OBJECT
    sqlcipher.depends = FORCE
    sqlcipher.commands = $(CC) $$SQLCIPHER_C $$SQLCIPHER_DEFINES $$SQLCIPHER_INCLUDES

    # Configure and build sqlcipher before building the plugin
    QMAKE_EXTRA_TARGETS += sqlcipher
    PRE_TARGETDEPS += $$sqlcipher.target
}
