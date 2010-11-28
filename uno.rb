require 'ruby-debug'

class Array

  def shuffle!
    size.downto(1) { |n| push delete_at(rand(n)) }
    self
  end

end

class Win < StandardError; end

COLORS = [ :red, :green, :blue, :yellow ]
ACTIONS = [ :skip, :reverse, :plus2 ]

class Card

  attr_reader :color, :value

  def initialize color, value=nil
    @color, @value = color, value
  end

  def to_s

    if @value
      "#{@color.to_s[0..0]}/#{@value}"
    else
      @color.to_s[0..0]
    end

  end

  def play_on? c

    if kind_of? WildCard
      true
    elsif @color == c.color
      true
    elsif @value == c.value
      true
    else
      false
    end

  end


end

class WildCard < Card

  attr_writer :color

  def initialize value=nil
    @value = value
    @color = nil
  end

  def to_s
    n = @value ?  "w+4" : "w"

    if @color
      "#{n}(#{@color.to_s[0..0]})"
    else
      n
    end

  end

end

class Player

  attr_reader :hand, :name

  def initialize name, game
    @name = name
    @game = game
    @hand = []
  end

  def draw_card
    @hand << @game.draw_card
  end

  def can_play?
    playable_cards.any?
  end

  def playable_cards
    @hand.select { |c| c.play_on? @game.top_card }
  end

  def play_card
    c = playable_cards.first
    @hand.delete c
    c.color = pick_color if c.kind_of? WildCard
    @game.play_card c
  end

  def pick_color
    :blue
  end

end

class Uno
  attr_reader :round, :winner

  def initialize n
    @players = Array.new(n) { |n| Player.new n.to_s, self }
    @draw = new_deck
    @discard = []
    @round = 0
    7.times { @players.each { |p| p.draw_card } }
    @discard.push @draw.pop
  end

  def new_deck
    deck = []

    # 4 of each wild type
    4.times {
      deck << WildCard.new
      deck << WildCard.new(:plus4)
    }

    # one 0 for each color
    COLORS.each { |c| deck << Card.new(c, 0) }

    # two of each action and number per color
    2.times do

      COLORS.each do |c|
        ACTIONS.each { |a| deck << Card.new(c, a) }
        (1..9).each { |n| deck << Card.new(c, n) }
      end

    end

    deck.shuffle!
  end

  def top_card
    @discard.last
  end

  def play_card c
    @discard.push c
  end

  def draw_card

    if @draw.empty?
      top = @discard.pop
      raise "no more cards" if @discard.empty?
      @draw = @discard
      @discard = [top]
      @draw.shuffle!
    end

    @draw.pop
  end

  def play_round
    @round += 1

    @players.each do |p|

      case @penalty
      when :plus4
        4.times { p.draw_card }

      when :plus2
        2.times { p.draw_card }

      when :skip
        # do nothing this turn

      when :reverse
        @players.reverse!

      else
        p.draw_card until p.can_play?
        p.play_card
      end

      if p.hand.empty?
        @winner = p
        break
      end

    end

  end

end

1000.times do
  uno = Uno.new 5
  uno.play_round until uno.winner
  puts "p#{uno.winner.name} r#{uno.round}"
end
