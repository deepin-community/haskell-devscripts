# -*- mode: makefile -*-
#
# Copyright 2022 Felix Lechner <felix.lechner@lease-up.com>
# Copyright 2008 Kari Pahula <kaol@debian.org>
# Description: A class for Haskell library packages
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.

export GREP_OPTIONS :=

# DH_haskell.sh uses shell features
export SHELL = /bin/bash

# Set a dummy HOME variable upon build. Some build daemons do not set HOME, but
# cabal expects it to be available.
export HOME = /homedoesnotexistatbuildtime

# If we can't figure out which compiler to use from the library
# package names, and DEB_DEFAULT_COMPILER isn't set in debian/rules,
# we can safely assume the desired compiler is ghc.
DEB_DEFAULT_COMPILER ?= ghc

DEB_GHC_DATABASE = debian/tmp-db

DEB_CABAL_PACKAGE ?= $(shell cat *.cabal |\
 perl -ne \
 'if (/^name\s*:\s*(.*?)\s*$$/i) {$$_ = $$1; tr/A-Z/a-z/; print; exit 0;}')
CABAL_PACKAGE=$(DEB_CABAL_PACKAGE)
CABAL_VERSION=$(shell runhaskell /usr/share/haskell-devscripts/GetCabalVersion.hs *.cabal || true)

DEB_ENABLE_TESTS ?= no
DEB_ENABLE_HOOGLE ?= yes

DEB_DH_GENCONTROL_ARGS_libghc-$(CABAL_PACKAGE)-dev += -- '-DGHC-Package=$${haskell:ghc-package}'

ifneq (,$(filter libghc-$(CABAL_PACKAGE)-prof,$(DEB_PACKAGES)))
ENABLE_PROFILING = --enable-library-profiling
endif

ifeq (0,$(shell ghc --info | grep -q 'Have interpreter.*YES' ; echo $$?))
GHC_HAS_INTERPRETER = yes
else
GHC_HAS_INTERPRETER = no
endif

ifeq (0,$(shell ghc --info | grep -q 'Support SMP.*YES' ; echo $$?))
GHC_HAS_SMP = yes
else
GHC_HAS_SMP = no
endif


NO_GHCI_FLAG = $(shell test -e /usr/bin/ghci || echo --ghc-option=-DDEBIAN_NO_GHCI; exit 0)

DEB_COMPRESS_EXCLUDE += .haddock .hs .txt

# (because we do not (yet) have shlibs files for libHS libraries)
DEB_DH_SHLIBDEPS_ARGS_ALL += -- --ignore-missing-info
DEB_DH_MAKESHLIBS_ARGS_ALL += -XlibHS

# Starting from debhelper v9.20151219, dh_strip automatically generats debug
# symbol packages. GHC cannot produce debugging symbols so the dbgsym
# package ends up being empty. Disable dbgsym generation.
DEB_DH_STRIP_ARGS += --no-automatic-dbgsym

# TODO:
# - some of this would probably be useful for generic Haskell programs,
#   not just libraries
# - provide more hooks
# - get this included in the cdbs package once this gets mature enough (maybe?)

DEB_SETUP_BIN_NAME ?= debian/hlibrary.setup

# most likely you don't need to touch this one
GHC6_VERSION = $(shell ghc --numeric-version)
GHC_VERSION = $(shell ghc --numeric-version)

DEB_HADDOCK_OPTS += --html --hoogle \
	--haddock-options="--mathjax=file:///usr/share/javascript/mathjax/MathJax.js"
ifndef DEB_NO_IMPLICIT_HADDOCK_HYPERLINK
DEB_HADDOCK_OPTS += --hyperlink-source
endif

MAKEFILE := debian/hlibrary.Makefile

#ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
#    NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
#    MAKEFLAGS := -j$(NUMJOBS)
#    BUILD_GHC := $(DEB_SETUP_BIN_NAME) makefile -f $(MAKEFILE) && $(MAKE) $(MAKEFLAGS) -f $(MAKEFILE) && $(BUILD_GHC)
#endif

ifneq (,$(findstring noopt,$(DEB_BUILD_OPTIONS)))
   OPTIMIZATION = --disable-optimization
endif

ifeq ($(DEB_ENABLE_TESTS),yes)
ifeq (,$(filter nocheck,$(DEB_BUILD_OPTIONS)))
   TESTS = --enable-tests
endif
endif

# We call the shell for most things, so make our variables available to it
export DEB_SETUP_BIN_NAME
export CABAL_PACKAGE
export CABAL_VERSION
export ENABLE_PROFILING
export NO_GHCI_FLAG
export DEB_SETUP_GHC6_CONFIGURE_ARGS
export DEB_SETUP_GHC_CONFIGURE_ARGS
export OPTIMIZATION
export TESTS
export DEB_DEFAULT_COMPILER
export DEB_GHC_DATABASE
export DEB_PACKAGES
export DEB_HADDOCK_OPTS
export HASKELL_HIDE_PACKAGES
export DEB_GHC_EXTRA_PACKAGES
export DEB_ENABLE_HOOGLE
export DEB_ENABLE_TESTS
export MAKEFILE
export GHC_HAS_SMP 

clean::
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'clean_recipe'
	rm -f configure-ghc-stamp
	rm -f build-ghc-stamp build-hugs-stamp build-haddock-stamp
	rm -f check-ghc-stamp
	rm -f debian/tmp
	rm -rf debian/tmp-inst-ghc debian/tmp-inst-ghcjs
	rm -rf $(DEB_GHC_DATABASE)
	rm -f $(MAKEFILE)


$(DEB_SETUP_BIN_NAME):
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'make_setup_recipe'

configure-ghc-stamp: $(DEB_SETUP_BIN_NAME)
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'configure_recipe'
	touch $@

build-ghc-stamp: configure-ghc-stamp
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'build_recipe'
	touch $@

check-ghc-stamp: build-ghc-stamp
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'check_recipe'
	touch $@

build/%-dev build/%-prof:: check-ghc-stamp

build-haddock-stamp: configure-ghc-stamp
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'haddock_recipe'
	touch $@

build/%-doc:: build-haddock-stamp

install-%-base::
	perl -d:Confess -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
		-E 'install_recipe($$ARGV[0])' "$(patsubst install-%-base,debian/tmp-inst-%,$@)"
	ln --symbolic --force "$(patsubst install-%-base,debian/tmp-inst-%,$@)" debian/tmp

install-%-arch: $(DEB_SETUP_BIN_NAME) check-ghc-stamp install-%-base
	:

# FIXME: the install_recipe doesn't work for indep-only builds, so our
# indep target depends on the arch target for now.
install-%-indep: $(DEB_SETUP_BIN_NAME) check-ghc-stamp build-haddock-stamp install-%-base
	:

debian/tmp-inst-%: $(DEB_SETUP_BIN_NAME) check-ghc-stamp build-haddock-stamp install-%-base
	:

dist-hugs: $(DEB_SETUP_BIN_NAME)
	$(DEB_SETUP_BIN_NAME) configure --hugs --prefix=/usr -v2 \
		--builddir=dist-hugs $(DEB_SETUP_HUGS_CONFIGURE_ARGS)

build/libhugs-$(CABAL_PACKAGE):: dist-hugs
	$(DEB_SETUP_BIN_NAME) build --builddir=dist-hugs

install/libghc-$(CABAL_PACKAGE)-dev:: install-ghc-arch
	dh_haskell_install_ghc_registration --package=$(notdir $@)
	dh_haskell_install_development_libs --package=$(notdir $@) --source-dir="debian/tmp-inst-ghc"
	dh_haskell_provides_ghc --package=$(notdir $@)
	dh_haskell_depends_cabal --package=$(notdir $@)
	dh_haskell_extra_depends_ghc --package=$(notdir $@) --type=dev
	dh_haskell_shlibdeps --package=$(notdir $@)
	dh_haskell_blurbs --package=$(notdir $@) --type=dev

install/libghc-$(CABAL_PACKAGE)-prof:: install-ghc-arch
	dh_haskell_install_profiling_libs --package=$(notdir $@) --source-dir="debian/tmp-inst-ghc"
	dh_haskell_provides_ghc --package=$(notdir $@) --config-shipper="libghc-$(CABAL_PACKAGE)-dev"
	dh_haskell_depends_cabal --package=$(notdir $@) --config-shipper="libghc-$(CABAL_PACKAGE)-dev"
	dh_haskell_blurbs --package=$(notdir $@) --type=prof

install/libghc-$(CABAL_PACKAGE)-doc:: install-ghc-indep
	dh_haskell_install_htmldocs --package=$(notdir $@) --source-dir="debian/tmp-inst-ghc"
	dh_haskell_install_haddock --package=$(notdir $@) --source-dir="debian/tmp-inst-ghc"
	dh_haskell_depends_haddock --package=$(notdir $@)
	dh_haskell_recommends_documentation_references --package=$(notdir $@)
	dh_haskell_suggests --package=$(notdir $@)
	dh_haskell_blurbs --package=$(notdir $@) --type=doc

install/libghcjs-$(CABAL_PACKAGE)-dev:: install-ghcjs-arch
	dh_haskell_install_ghc_registration --package=$(notdir $@)
	dh_haskell_install_development_libs --package=$(notdir $@) --source-dir="debian/tmp-inst-ghcjs"
	dh_haskell_provides_ghc --package=$(notdir $@)
	dh_haskell_depends_cabal --package=$(notdir $@)
	dh_haskell_extra_depends_ghc --package=$(notdir $@) --type=dev
	dh_haskell_shlibdeps --package=$(notdir $@)
	dh_haskell_blurbs --package=$(notdir $@) --type=dev

install/libghcjs-$(CABAL_PACKAGE)-prof:: install-ghcjs-arch
	dh_haskell_install_profiling_libs --package=$(notdir $@) --source-dir="debian/tmp-inst-ghcjs"
	dh_haskell_provides_ghc --package=$(notdir $@) --config-shipper="libghcjs-$(CABAL_PACKAGE)-dev"
	dh_haskell_depends_cabal --package=$(notdir $@) --config-shipper="libghc-$(CABAL_PACKAGE)-dev"
	dh_haskell_blurbs --package=$(notdir $@) --type=prof

install/libghcjs-$(CABAL_PACKAGE)-doc:: install-ghcjs-indep
	dh_haskell_install_htmldocs --package=$(notdir $@) --source-dir="debian/tmp-inst-ghcjs"
	dh_haskell_install_haddock --package=$(notdir $@) --source-dir="debian/tmp-inst-ghcjs"
	dh_haskell_depends_haddock --package=$(notdir $@)
	dh_haskell_recommends_documentation_references --package=$(notdir $@)
	dh_haskell_suggests --package=$(notdir $@)
	dh_haskell_blurbs --package=$(notdir $@) --type=doc

install/libhugs-$(CABAL_PACKAGE):: $(DEB_SETUP_BIN_NAME) dist-hugs
	$(DEB_SETUP_BIN_NAME) copy --builddir=dist-hugs --destdir=debian/libhugs-$(CABAL_PACKAGE)
	rm -rf debian/libhugs-$(CABAL_PACKAGE)/usr/share/doc/*
	dh_haskell_depends_hugs --package=$(notdir $@)

$(patsubst %,install/%,$(DEB_PACKAGES)) :: install/%:
	dh_haskell_description --package=$(cdbs_curpkg)
	dh_haskell_compiler --package=$(cdbs_curpkg)


# Support for installing executables
define newline


endef
$(patsubst debian/%.haskell-binaries,build/%,$(wildcard debian/*.haskell-binaries)):: check-ghc-stamp

$(patsubst debian/%.haskell-binaries,install/%,$(wildcard debian/*.haskell-binaries)):: debian/tmp-inst-ghc
	$(foreach binary,$(shell cat debian/$(cdbs_curpkg).haskell-binaries),dh_install -p$(cdbs_curpkg) dist-ghc/build/$(binary)/$(binary) usr/bin $(newline))
