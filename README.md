Qt SQL driver plugin for SQLCipher
==================================

This is a [QSqlDriverPlugin](http://doc.qt.io/qt-5/qsqldriverplugin.html) for
[SQLCipher](https://www.zetetic.net/sqlcipher/open-source/). It is quite
simple - it uses Qt's own SQLite driver code but links against SQLCipher
instead of SQLite.

The upper statement was made by the original author, [sijk](https://github.com/sijk), but the rest of this README will be completelly rewritten. It is still a WIP, for now (Jun 17, 2016).

## Dependencies

- Qt 5[.6, .7]
- SQLCipher
- more to come ...

## Tested platforms

- MS Windows XP (compat), 7 onwards (dev)
- Posix
- Mac OSX?

## Deployment

Follow [Qt's plugin deployment guide](http://doc.qt.io/qt-5/deployment-plugins.html).
In short, put the plugin at ``sqldrivers/libqsqlcipher.so`` relative to your
executable.
