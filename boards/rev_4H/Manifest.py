target = "efinix"
action = "synthesis"

syn_family = "Trion"
syn_device = "T20"
syn_grade = "C4"
syn_package = "F256"
syn_top = "top"
syn_project = "vicii"
syn_tool = "efinity"

syn_pre_bitstream_cmd = "cp ./config.vh.MAINLH ../../hdl/config.vh"

modules = {"local" :
              [ "../../hdl",
                "../../hdl/efinix_trion/dvi",
                "../../hdl/rev_4H",
              ]
          }

files = [ "vicii.sdc" ]
