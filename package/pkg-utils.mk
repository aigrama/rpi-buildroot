################################################################################
#
# This file contains various utility functions used by the package
# infrastructure, or by the packages themselves.
#
################################################################################

# UPPERCASE Macro -- transform its argument to uppercase and replace dots and
# hyphens to underscores

# Heavily inspired by the up macro from gmsl (http://gmsl.sf.net)
# This is approx 5 times faster than forking a shell and tr, and
# as this macro is used a lot it matters
# This works by creating translation character pairs (E.G. a:A b:B)
# and then looping though all of them running $(subst from,to,text)
[FROM] := a b c d e f g h i j k l m n o p q r s t u v w x y z - .
[TO]   := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z _ _

define caseconvert-helper
$(1) = $$(strip \
	$$(eval __tmp := $$(1))\
	$(foreach c, $(2),\
		$$(eval __tmp := $$(subst $(word 1,$(subst :, ,$c)),$(word 2,$(subst :, ,$c)),$$(__tmp))))\
	$$(__tmp))
endef

$(eval $(call caseconvert-helper,UPPERCASE,$(join $(addsuffix :,$([FROM])),$([TO]))))
$(eval $(call caseconvert-helper,LOWERCASE,$(join $(addsuffix :,$([TO])),$([FROM]))))

#
# Manipulation of .config files based on the Kconfig
# infrastructure. Used by the BusyBox package, the Linux kernel
# package, and more.
#

define KCONFIG_ENABLE_OPT # (option, file)
	$(SED) "/\\<$(1)\\>/d" $(2)
	echo '$(1)=y' >> $(2)
endef

define KCONFIG_SET_OPT # (option, value, file)
	$(SED) "/\\<$(1)\\>/d" $(3)
	echo '$(1)=$(2)' >> $(3)
endef

define KCONFIG_DISABLE_OPT # (option, file)
	$(SED) "/\\<$(1)\\>/d" $(2)
	echo '# $(1) is not set' >> $(2)
endef

# Helper functions to determine the name of a package and its
# directory from its makefile directory, using the $(MAKEFILE_LIST)
# variable provided by make. This is used by the *TARGETS macros to
# automagically find where the package is located.
pkgdir       = $(dir $(lastword $(MAKEFILE_LIST)))
pkgname      = $(lastword $(subst /, ,$(pkgdir)))

# Define extractors for different archive suffixes
INFLATE.bz2  = $(BZCAT)
INFLATE.gz   = $(ZCAT)
INFLATE.tbz  = $(BZCAT)
INFLATE.tbz2 = $(BZCAT)
INFLATE.tgz  = $(ZCAT)
INFLATE.xz   = $(XZCAT)
INFLATE.tar  = cat
# suitable-extractor(filename): returns extractor based on suffix
suitable-extractor = $(INFLATE$(suffix $(1)))

# MESSAGE Macro -- display a message in bold type
MESSAGE     = echo "$(TERM_BOLD)>>> $($(PKG)_NAME) $($(PKG)_VERSION) $(1)$(TERM_RESET)"
TERM_BOLD  := $(shell tput smso)
TERM_RESET := $(shell tput rmso)

# Utility functions for 'find'
# findfileclauses(filelist) => -name 'X' -o -name 'Y'
findfileclauses = $(call notfirstword,$(patsubst %,-o -name '%',$(1)))
# finddirclauses(base, dirlist) => -path 'base/dirX' -o -path 'base/dirY'
finddirclauses  = $(call notfirstword,$(patsubst %,-o -path '$(1)/%',$(2)))

# Miscellaneous utility functions
# notfirstword(wordlist): returns all but the first word in wordlist
notfirstword = $(wordlist 2,$(words $(1)),$(1))

# Needed for the foreach loops to loop over the list of hooks, so that
# each hook call is properly separated by a newline.
define sep


endef

#
# legal-info helper functions
#
LEGAL_INFO_SEPARATOR="::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

define legal-warning # text
	echo "WARNING: $(1)" >>$(LEGAL_WARNINGS)
endef

define legal-warning-pkg # pkg, text
	echo "WARNING: $(1): $(2)" >>$(LEGAL_WARNINGS)
endef

define legal-warning-nosource # pkg, {local|override}
	$(call legal-warning-pkg,$(1),sources not saved ($(2) packages not handled))
endef

define legal-manifest # pkg, version, license, license-files, source, url, {HOST|TARGET}
	echo '"$(1)","$(2)","$(3)","$(4)","$(5)","$(6)"' >>$(LEGAL_MANIFEST_CSV_$(7))
endef

define legal-license-header # pkg, license-file, {HOST|TARGET}
	printf "$(LEGAL_INFO_SEPARATOR)\n\t$(1):\
		$(2)\n$(LEGAL_INFO_SEPARATOR)\n\n\n" >>$(LEGAL_LICENSES_TXT_$(3))
endef

define legal-license-nofiles # pkg, {HOST|TARGET}
	$(call legal-license-header,$(1),unknown license file(s),$(2))
endef

define legal-license-file # pkg, filename, file-fullpath, {HOST|TARGET}
	$(call legal-license-header,$(1),$(2) file,$(4)) && \
	cat $(3) >>$(LEGAL_LICENSES_TXT_$(4)) && \
	echo >>$(LEGAL_LICENSES_TXT_$(4)) && \
	mkdir -p $(LICENSE_FILES_DIR_$(4))/$(1)/$(dir $(2)) && \
	cp $(3) $(LICENSE_FILES_DIR_$(4))/$(1)/$(2)
endef
