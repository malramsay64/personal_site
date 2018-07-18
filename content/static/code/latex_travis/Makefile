# Makefile
#
# Malcolm Ramsay 2018
#

# directory to put build files
build_dir := output

.PHONY: all

all: document.pdf

%.pdf: %.tex | $(build_dir)
	tectonic -o $(build_dir) --keep-intermediates -r0 $<
	if [ -f $(build_dir)/$(notdir $(<:.tex=.bcf)) ]; then biber2.5 --input-directory $(build_dir) $(notdir $(<:.tex=)); fi
	tectonic -o $(build_dir) --keep-intermediates $<
	cp $(build_dir)/$(notdir $@) .

$(build_dir):
	mkdir -p $@
