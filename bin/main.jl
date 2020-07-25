#####
##### Main script for the JuliaCon 2020 demo
#####

ENV["JULIA_CUDA_MEMORY_POOL"] = "split" # "binned" / "split"

# Enables running the script on a distant machine without an X server
ENV["GKSwstype"]="nul"

@everywhere using AlphaZero

const DUMMY_RUN = false
include("../scripts/lib/dummy_run.jl")

include("../games/connect-four/main.jl")
using .ConnectFour: Game, Training

params, benchmark = Training.params, Training.benchmark
if DUMMY_RUN
  params, benchmark = dummy_run_params(params, benchmark)
end

session = Session(
  Game,
  Training.Network{Game},
  Params(params, num_iters=3),
  Training.netparams,
  benchmark=benchmark,
  dir="sessions/connect-four",
  autosave=true,
  save_intermediate=false)

@info "training!"
resume!(session)

# -- output
import Tar
import TranscodingStreams: TranscodingStream
import CodecZlib: GzipCompressor

open("sessions.tar.gz", "w") do io
  Tar.create("sessions", TranscodingStream(GzipCompressor(), io))
end
ENV["RESULTS_FILE_TO_UPLOAD"] = "sessions.tar.gz"
