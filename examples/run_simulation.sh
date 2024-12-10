#!/usr/bin/env bash
set -x

# Set working directory.
pushd /home/hotgauge/HotGauge/examples

# Generate floorplans.
python floorplans.py

#
# Warmup.
#
ln -s -T /home/hotgauge/HotGauge/3d-ice/heatsink_plugin/heatsinks/HS483/HS483_P14752_ConstantFanSpeed_Interface3DICE HS483_P14752_ConstantFanSpeed_Interface3DICE
python only_warmup.py
# Patch warmup output files.
sed -ie 's:HS483\.::g' ./simulation_with_warmup/outputs/warmup/IC.stk
sed -ie 's:IC\.flp:/home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/warmup/IC\.flp:g' ./simulation_with_warmup/outputs/warmup/IC.stk
# Run simulator on warmup files.
/home/hotgauge/HotGauge/3d-ice/bin/3D-ICE-Emulator /home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/warmup/IC.stk

#
# Simulation.
#
python only_simulation.py
# Watch simulation output files.
sed -ie 's:HS483\.::g' ./simulation_with_warmup/outputs/sim/IC.stk
sed -ie 's:IC\.flp:/home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/sim/IC\.flp:g' ./simulation_with_warmup/outputs/sim/IC.stk
sed -ie 's:/home/hotgauge/HotGauge/examples/only_simulation/outputs/warmup/final\.tstack:final\.tstack:g' ./simulation_with_warmup/outputs/sim/IC.stk
# Run simulator on simulation output files.
/home/hotgauge/HotGauge/3d-ice/bin/3D-ICE-Emulator /home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/sim/IC.stk

#
# Generate plots
#
popd
pushd /home/hotgauge/HotGauge/examples/simulation_with_warmup
cp ../die_* outputs/sim/
./compute_local_maxima_stats.sh
./plot_vs_time.sh
./visualize_hotspots.sh
./visualize_power.sh
popd
