FROM ubuntu:20.04

ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get upgrade -y
RUN apt-get install -y vim tmux git make build-essential csh pkg-config parallel lsb-core wget ffmpeg

RUN echo "deb http://dk.archive.ubuntu.com/ubuntu/ `lsb_release -cs` main" >> /etc/apt/sources.list
RUN echo "deb http://dk.archive.ubuntu.com/ubuntu/ `lsb_release -cs` universe" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y gcc-7 bison flex 
RUN apt-get install -y libblas3 libblas-dev 
RUN apt-get install -y libpugixml-dev

RUN echo "deb https://build.openmodelica.org/apt `lsb_release -cs` release" | tee /etc/apt/sources.list.d/openmodelica.list
RUN apt-get install -y python3 python3-dev python3-venv python-is-python3
RUN wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | apt-key add - 
RUN apt-get update
RUN apt-get install -y openmodelica
RUN for PKG in `apt-cache search "omlib-.*" | cut -d" " -f1`; do apt-get install -y "$PKG"; done 

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt install -y emacs-nox
RUN apt-get install sudo
RUN useradd -ms /bin/bash -G sudo hotgauge
USER hotgauge
WORKDIR /home/hotgauge/

# !!avose: Don't copy from local dir, clone fresh from repo.
#COPY --chown=hotgauge:hotgauge ./ ./HotGauge
RUN git clone 'https://github.com/avose/HotGauge'

WORKDIR /home/hotgauge/HotGauge/
RUN python -m venv env
RUN source env/bin/activate && pip install -r requirements.txt
RUN ./get_and_patch_3DICE.sh

WORKDIR /home/hotgauge/HotGauge/3d-ice/
RUN ./install-superlu.sh
RUN make CC=gcc-7

RUN sed -ie 's:parameter String args:parameter String args = "":g' heatsink_plugin/common/HeatsinkBlocks.mo
RUN sed -ie 's:^$:installPackage(Modelica, "3.2.3", exactMatch=false);:' heatsink_plugin/templates/NonlinearExample/buildfmi.mos
RUN sed -ie 's:NonlinearExample.NonlinearHeatsink_Interface3DICE:NonlinearHeatsink_Interface3DICE:' heatsink_plugin/templates/NonlinearExample/Makefile
RUN sed -ie 's:Heatsink.TestHeatsink_Interface3DICE:TestHeatsink_Interface3DICE:' heatsink_plugin/templates/Modelica/Makefile
RUN sed -ie 's:HS483.HS483_P14752_ConstantFanSpeed_Interface3DICE:HS483_P14752_ConstantFanSpeed_Interface3DICE:' heatsink_plugin/heatsinks/HS483/Makefile
RUN sed -ie 's:HS483.HS483_P14752_VariableFanSpeed_Interface3DICE:HS483_P14752_VariableFanSpeed_Interface3DICE:' heatsink_plugin/heatsinks/HS483/Makefile
RUN sed -ie 's:Cuplex.Cuplex21606_ConstantFlowRate_Interface3DICE:Cuplex21606_ConstantFlowRate_Interface3DICE:' heatsink_plugin/heatsinks/cuplex_kryos_21606/Makefile
RUN sed -ie 's:Cuplex.Cuplex21606_VariableFlowRate_Interface3DICE:Cuplex21606_VariableFlowRate_Interface3DICE:' heatsink_plugin/heatsinks/cuplex_kryos_21606/Makefile
RUN make plugin CC=gcc-7

RUN ln -s /home/hotgauge/HotGauge/3d-ice/heatsink_plugin/heatsinks/HS483/HS483_P14752_ConstantFanSpeed_Interface3DICE /home/hotgauge/HotGauge/3d-ice/heatsink_plugin/heatsinks/HS483/HS483.HS483_P14752_ConstantFanSpeed_Interface3DICE

RUN sed -ie 's:Test.TestHeatsink_Interface3DICE:TestHeatsink_Interface3DICE:' test/plugin/Makefile
#RUN make test CC=gcc-7

WORKDIR /home/hotgauge/HotGauge/examples
RUN ./run_simulation.sh

#RUN source /home/hotgauge/HotGauge/env/bin/activate && python floorplans.py
#RUN ln -s -T /home/hotgauge/HotGauge/3d-ice/heatsink_plugin/heatsinks/HS483/HS483_P14752_ConstantFanSpeed_Interface3DICE HS483_P14752_ConstantFanSpeed_Interface3DICE
#RUN source /home/hotgauge/HotGauge/env/bin/activate && python only_warmup.py
#RUN sed -ie 's:HS483\.::g' ./simulation_with_warmup/outputs/warmup/IC.stk
#RUN sed -ie 's:IC\.flp:/home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/warmup/IC\.flp:g' ./simulation_with_warmup/outputs/warmup/IC.stk
#RUN /home/hotgauge/HotGauge/3d-ice/bin/3D-ICE-Emulator /home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/warmup/IC.stk

#RUN source /home/hotgauge/HotGauge/env/bin/activate && python only_simulation.py
#RUN sed -ie 's:HS483\.::g' ./simulation_with_warmup/outputs/sim/IC.stk
#RUN sed -ie 's:IC\.flp:/home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/sim/IC\.flp:g' ./simulation_with_warmup/outputs/sim/IC.stk
#RUN sed -ie 's:/home/hotgauge/HotGauge/examples/only_simulation/outputs/warmup/final\.tstack:final\.tstack:g' ./simulation_with_warmup/outputs/sim/IC.stk
#RUN /home/hotgauge/HotGauge/3d-ice/bin/3D-ICE-Emulator /home/hotgauge/HotGauge/examples/simulation_with_warmup/outputs/sim/IC.stk

#WORKDIR /home/hotgauge/HotGauge/examples/simulation_with_warmup
#RUN cp ../die_* outputs/sim/
#RUN source /home/hotgauge/HotGauge/env/bin/activate && ./compute_local_maxima_stats.sh
#RUN source /home/hotgauge/HotGauge/env/bin/activate && ./plot_vs_time.sh
#RUN source /home/hotgauge/HotGauge/env/bin/activate && ./visualize_hotspots.sh
#RUN source /home/hotgauge/HotGauge/env/bin/activate && ./visualize_power.sh

WORKDIR /home/hotgauge/HotGauge/
RUN echo "source /home/hotgauge/HotGauge/env/bin/activate" >> ~/.bashrc
USER root
RUN mkdir /data
RUN chown hotgauge:hotgauge /data
VOLUME /data
USER hotgauge

CMD ["/bin/bash"]
