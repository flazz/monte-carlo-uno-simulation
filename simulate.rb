require 'ruby-debug'
require 'uno'
require 'pp'

def simulate runs, *player_klasses
  hist = []
  uno = nil
  runouts = 0
  rounds = 0

  runs.times do
    uno = Uno.new
    player_klasses.each { |klass| uno.players << klass.new }
    uno.deal

    uno.play_round until uno.done?

    if uno.winner
      hist[uno.winner] ||= 0
      hist[uno.winner] += 1
    end

    runouts += 1 if uno.runout
    rounds += uno.rounds
  end

  hist.each_with_index do |n, ix|
    share = runs / uno.players.size
    delta = n - share
    deltap = (delta.to_f / runs) * 100
    puts "%+0.2f%% %s" % [deltap, uno.players[ix].class]
  end

  puts "runouts: #{(runouts.to_f / runs.to_f) * 100.0}%"
  puts "avg rounds: #{ rounds.to_f / runs.to_f }"
  puts
end

simulate 10000, Player, Player, Player, Player, Player
simulate 10000, Player, Player, Player, Player, AbundantColor
simulate 10000, Player, Player, Player, Player, EagerDraw
simulate 10000, Player, Player, Player, Player, LazyDraw
