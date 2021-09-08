PWD=$(shell pwd)

all: package

convert:
	wat2wasm resources/debug.wat -o resources/debug.wasm
	wat2wasm resources/debug.wat -v > resources/debug.text
	tools/bin2coe.py --input resources/debug.wasm --output resources/debug.coe

prepare:
	@mkdir -p work

project: prepare hxs fetch-definitions
	@vivado -mode batch -source scripts/create_project.tcl -notrace -nojournal -tempDir work -log work/vivado.log

package: hxs fetch-definitions
	python3 setup.py sdist bdist_wheel

clean:
	@find ip ! -iname *.xci -type f -exec rm {} +
	@rm -rf .Xil vivado*.log vivado*.str vivado*.jou
	@rm -rf work \
		src-gen \
		hxs_gen \
		*.egg-info \
		dist \
	@rm -rf ip/**/hdl \
		ip/**/synth \
		ip/**/example_design \
		ip/**/sim \
		ip/**/simulation \
		ip/**/misc \
		ip/**/doc

hxs:
	docker run -t \
               -v ${PWD}/hxs/wasm_fpga_loader.hxs:/work/src/wasm_fpga_loader.hxs \
               -v ${PWD}/hxs_gen:/work/gen \
               registry.build.aug:5000/docker/hxs_generator:latest
	cp hxs_gen/simstm_gen/indirect/wasm_fpga_loader_indirect.stm resources/wasm_fpga_loader_indirect.stm
	cp hxs_gen/vhd_gen/header/wasm_fpga_loader_header.vhd resources/wasm_fpga_loader_header.vhd
	cp hxs_gen/vhd_gen/wishbone/wasm_fpga_loader_wishbone.vhd resources/wasm_fpga_loader_wishbone.vhd
	docker run -t \
               -v ${PWD}/hxs/wasm_fpga_loader_debug.hxs:/work/src/wasm_fpga_loader_debug.hxs \
               -v ${PWD}/hxs_gen:/work/gen \
               registry.build.aug:5000/docker/hxs_generator:latest
	cp hxs_gen/simstm_gen/indirect/wasm_fpga_loader_debug_indirect.stm resources/wasm_fpga_loader_debug_indirect.stm
	cp hxs_gen/vhd_gen/header/wasm_fpga_loader_debug_header.vhd resources/wasm_fpga_loader_debug_header.vhd
	cp hxs_gen/vhd_gen/wishbone/wasm_fpga_loader_debug_wishbone.vhd resources/wasm_fpga_loader_debug_wishbone.vhd

fetch-definitions:
	cp ../wasm-fpga-store/hxs_gen/vhd_gen/header/* resources
	cp ../wasm-fpga-store/hxs_gen/vhd_gen/wishbone/* resources

install-from-test-pypi:
	pip3 install --upgrade -i https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple wasm-fpga-loader

upload-to-test-pypi: package
	python3 -m twine upload --repository-url https://test.pypi.org/legacy/ dist/*

upload-to-pypi: package
	python3 -m twine upload --repository pypi dist/*

.PHONY: all prepare project package clean hxs fetch-definitions
