mrisc32-elf-readelf -sW out/mc1quake | grep FUNC | awk '{print $2,$8}' > /tmp/mc1quake-symbols
mr32sim -g -ga 1073744608 -gp 1073743556 -gd 8 -gw 320 -gh 180 -P /tmp/mc1quake-symbols "$@" out/mc1quake.bin

