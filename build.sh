#!/bin/sh

# ----------------------------------------------------------------------------
# Copyright (c) 2011-2012, KOBAYASHI Daisuke
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# ----------------------------------------------------------------------------

gcc_version=4.7.2
binutils_version=2.22
newlib_version=1.20.0
gmp_version=5.0.5
mpfr_version=3.1.1
mpc_version=1.0.1

work=$PWD
build=$(cc -dumpmachine)
target=
prefix=

param_count=$#
param=$1

show_help()
{
  echo "Usage: $0 [target]"
}

configure_target()
{
  if [ $param_count -eq 1 ]; then
    target=$param
    prefix=/usr/local/$target/$gcc_version
    PATH=$PATH:$prefix/bin
  else
    show_help
    exit 0
  fi
}

download_gcc()
{
  [ -f gcc-$gcc_version.tar.bz2 ] && return
  #curl -O ftp://gcc.gnu.org/pub/gcc/releases/gcc-$gcc_version/gcc-$gcc_version.tar.bz2
  curl -L -O http://ftpmirror.gnu.org/gcc/gcc-$gcc_version/gcc-$gcc_version.tar.bz2
}
download_binutils()
{
  [ -f binutils-$binutils_version.tar.bz2 ] && return
  #curl -O ftp://ftp.gnu.org/gnu/binutils/binutils-$binutils_version.tar.bz2
  curl -L -O http://ftpmirror.gnu.org/binutils/binutils-$binutils_version.tar.bz2
}
download_newlib()
{
  [ -f newlib-$newlib_version.tar.gz ] && return
  curl -O ftp://sources.redhat.com/pub/newlib/newlib-$newlib_version.tar.gz
}
download_gmp()
{
  [ -f gmp-$gmp_version.tar.bz2 ] && return
  #curl -O ftp://ftp.gmplib.org/pub/gmp-$gmp_version/gmp-$gmp_version.tar.bz2
  curl -L -O http://ftpmirror.gnu.org/gmp/gmp-$gmp_version.tar.bz2
}
download_mpfr()
{
  [ -f mpfr-$mpfr_version.tar.bz2 ] && return
  curl -O http://www.mpfr.org/mpfr-current/mpfr-$mpfr_version.tar.bz2
}
download_mpc()
{
  [ -f mpc-$mpc_version.tar.gz ] && return
  curl -O http://www.multiprecision.org/mpc/download/mpc-$mpc_version.tar.gz
}

extract_gcc()
{
  [ -d gcc-$gcc_version ] && return
  download_gcc
  tar jxf gcc-$gcc_version.tar.bz2
}
extract_binutils()
{
  [ -d binutils-$binutils_version ] && return
  download_binutils
  tar jxf binutils-$binutils_version.tar.bz2
}
extract_newlib()
{
  [ -d newlib-$newlib_version ] && return
  download_newlib
  tar zxf newlib-$newlib_version.tar.gz
}
extract_gmp()
{
  [ -d gmp-$gmp_version ] && return
  download_gmp
  tar jxf gmp-$gmp_version.tar.bz2
}
extract_mpfr()
{
  [ -d mpfr-$mpfr_version ] && return
  download_mpfr
  tar jxf mpfr-$mpfr_version.tar.bz2
}
extract_mpc()
{
  [ -d mpc-$mpc_version ] && return
  download_mpc
  tar zxf mpc-$mpc_version.tar.gz
}

build_gmp()
{
  mkdir -p $work/gmp-$gmp_version/_build
  cd $work/gmp-$gmp_version/_build
  ../configure --prefix=$work --disable-shared
  make && make install
}
build_mpfr()
{
  mkdir -p $work/mpfr-$mpfr_version/_build
  cd $work/mpfr-$mpfr_version/_build
  ../configure --prefix=$work --with-gmp=$work --disable-shared
  make && make install
}
build_mpc()
{
  mkdir -p $work/mpc-$mpc_version/_build
  cd $work/mpc-$mpc_version/_build
  ../configure --prefix=$work --with-gmp=$work --with-mpfr=$work \
	--disable-shared
  make && make install
}
build_binutils()
{
  mkdir -p $work/binutils-$binutils_version/_build
  cd $work/binutils-$binutils_version/_build
  local opt="--prefix=$prefix --with-sysroot=$prefix \
	--target=$target --disable-shared --disable-debug"
  ../configure $opt
  make && make install
}
build_gcc_core()
{
  mkdir -p $work/gcc-$gcc_version/_build
  cd $work/gcc-$gcc_version/_build
  local opt="--prefix=$prefix --with-sysroot=$prefix --target=$target \
	--with-gmp=$work --with-mpfr=$work --with-mpc=$work \
	--enable-languages=c,c++ --with-newlib \
	--disable-shared --disable-debug"
  ../configure $opt
  make all-gcc && make install-gcc
}
build_newlib()
{
  mkdir -p $work/newlib-$newlib_version/_build
  cd $work/newlib-$newlib_version/_build
  local opt="--prefix=$prefix --target=$target"
  ../configure $opt
  make && make install
}
build_gcc()
{
  cd $work/gcc-$gcc_version/_build
  make && make install
}


configure_target

echo "--> downloading & extracting ------------------------"
extract_gcc
extract_binutils
extract_newlib
extract_gmp
extract_mpfr
extract_mpc

echo "--> building gmp ------------------------------------"
build_gmp

echo "--> building mpfr -----------------------------------"
build_mpfr

echo "--> building mpc ------------------------------------"
build_mpc

echo "--> building binutils -------------------------------"
build_binutils

echo "--> building gcc core -------------------------------"
build_gcc_core

echo "--> building newlib ---------------------------------"
build_newlib

echo "--> building gcc ------------------------------------"
build_gcc

echo "--> done --------------------------------------------"

