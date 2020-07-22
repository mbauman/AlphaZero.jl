#####
##### Interface to Pascal Pons' Connect 4 Solver
##### https://github.com/PascalPons/connect4
#####

# Problem: no Connect4 module. We can change this:

module Solver

import ..Game, ..history, ..WHITE, ..NUM_CELLS
import AlphaZero: GI, GameInterface, Benchmark, AbstractPlayer, think
@info "Solver: after imports"

const DEFAULT_SOLVER_DIR = joinpath(@__DIR__, "solver", "connect4")

@info "1.0"
struct Player0 <: AbstractPlayer{Game}
end
@info "1.1"
struct Player1 <: AbstractPlayer{Game}
  process :: Base.Process
end
@info "1.2"
struct Player2 <: AbstractPlayer{Game}
  process :: Base.Process
  function Player2(;
      solver_dir=DEFAULT_SOLVER_DIR,
      solver_name="c4solver",
      disable_stderr=true)
    return new()
  end
end
@info "1.25"
struct Player25 <: AbstractPlayer{Game}
  process :: Base.Process
  function Player25(;
      solver_dir=DEFAULT_SOLVER_DIR,
      solver_name="c4solver",
      disable_stderr=true)
    return new(open(`echo`))
  end
end
@info "1.3"
struct Player3 <: AbstractPlayer{Game}
  process :: Base.Process
  function Player3(;
      solver_dir=DEFAULT_SOLVER_DIR,
      solver_name="c4solver",
      disable_stderr=true)
    cmd = Cmd(`echo`, dir=solver_dir)
    if disable_stderr
      cmd = pipeline(cmd, stderr=devnull)
    end
    p = open(cmd, "r+")
    return new(p)
  end
end
@info "1.4"
struct Player4 <: AbstractPlayer{Game}
  process :: Base.Process
  function Player4(;
      solver_dir=DEFAULT_SOLVER_DIR,
      solver_name="c4solver",
      disable_stderr=true)
    cmd = Cmd(`./c4solver`, dir=solver_dir)
    if disable_stderr
      cmd = pipeline(cmd, stderr=devnull)
    end
    p = open(cmd, "r+")
    return new(p)
  end
end
@info "1.5"
struct Player <: AbstractPlayer{Game}
  process :: Base.Process
  function Player(;
      solver_dir=DEFAULT_SOLVER_DIR,
      solver_name="c4solver",
      disable_stderr=true)
    cmd = Cmd(`./$solver_name`, dir=solver_dir)
    if disable_stderr
      cmd = pipeline(cmd, stderr=devnull)
    end
    p = open(cmd, "r+")
    return new(p)
  end
end

# Solver protocol
# - Standard input: one position per line
# - Standard output: space separated
#     position, score, number of explored node, computation time in μs

@info "2"
struct SolverOutput
  score :: Int
  num_explored_nodes :: Int64
  time :: Int64 # in μs
end
@info "3"

history_string(game) = reduce(*, map(string, history(game)))

@info "4"
function query_solver(p::Player, g)
  hstr = history_string(g)
  println(p.process, hstr)
  l = readline(p.process)
  args = map(split(l)[2:end]) do x
    parse(Int64, x)
  end
  return SolverOutput(args...)
end
@info "5"

function remaining_stones(game, player)
  @assert !isnothing(game.history)
  n = length(game.history)
  p = n ÷ 2
  (n % 2 == 1 && player == WHITE) && (p += 1)
  return NUM_CELLS ÷ 2 - p
end
@info "6"

function value(player, game)
  if !GI.game_terminated(game)
    return query_solver(player, game).score
  elseif game.winner == 0x00
    return 0
  else
    v = remaining_stones(game, game.winner) + 1
    if (game.winner == WHITE) != GI.white_playing(game)
      v = -v
    end
    return v
  end
end
@info "7"

function qvalue(player, game, action)
  @assert !GI.game_terminated(game)
  next = copy(game)
  GI.play!(next, action)
  qnext = value(player, next)
  if GI.white_playing(game) != GI.white_playing(next)
    qnext = -qnext
  end
  return qnext
end
@info "8"

function think(p::Player, g)
  as = GI.available_actions(g)
  qs = [qvalue(p, g, a) for a in as]
  maxq = maximum(qs)
  opt = findall(>=(maxq), qs)
  π = zeros(length(as))
  π[opt] .= 1 / length(opt)
  return as, π
end
@info "9"

Benchmark.PerfectPlayer(::Type{Game}) = Player
@info "10"

end
