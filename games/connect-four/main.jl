module ConnectFour
  export Game, Board
  @info """include("game.jl")"""
  include("game.jl")
  module Training
    using AlphaZero
    @info """include("params.jl")"""
    include("params.jl")
  end
  @info """include("solver.jl")"""
  include("solver.jl")
end
