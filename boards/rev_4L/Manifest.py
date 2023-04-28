target = "xilinx"
action = "synthesis"

syn_device = "xc6slx16"
syn_grade = "-2"
syn_package = "ftg256"
syn_top = "top"
syn_project = "vicii.xise"
syn_tool = "ise"

syn_pre_bitstream_cmd = "cp ./config.vh.MAINLD ../../hdl/config.vh"

modules = {"local" :
              [ "../../hdl",
                "../../hdl/xilinx_spartan6",
                "../../hdl/xilinx_spartan6/dvi",
                "../../hdl/rev_4L",
              ]
          }

