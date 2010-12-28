require 'ruby-debug'

class Array

  def shuffle!
    size.downto(1) { |n| push delete_at(rand(n)) }
    self
  end

end

COLORS = [ :red, :green, :blue, :yellow ]
ACTIONS = [ :skip, :reverse, :plus2 ]

class Card

  attr_reader :color, :value
  attr_writer :color

  def initialize color, value=nil, wild=false
    @color, @value, @wild = color, value, wild
  end

  def to_s

    if @value
      "#{@color.to_s[0..0]}/#{@value}"
    else
      @color.to_s[0..0]
    end

  end

  def play_on? c

    if @wild
      true
    elsif @color == c.color
      true
    elsif @value == c.value
      true
    else
      false
    end

  end

  def wild?
    @wild
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

    @hand.select do |c|

      if @game.draw_amount == 0
        c.play_on? @game.top_card
      else

        case c.value
        when :plus2, :plus4 then true
        else false
        end

      end

    end

  end

  def play_card
    c = playable_cards.first
    @hand.delete c
    c.color = pick_color if c.wild?
    @game.play_card c
  end

  def pick_color
    :blue
  end

end

class Uno
  attr_reader :round, :winner, :draw_amount

  def initialize n
    @players = Array.new(n) { |n| Player.new n.to_s, self }
    @draw = new_deck
    @discard = []
    @round = 0
    7.times { @players.each { |p| p.draw_card } }
    @discard.push @draw.pop
    @action = nil
    @draw_amount = 0
  end

  def new_deck
    deck = []

    # 4 of each wild type
    4.times {
      deck << Card.new(nil, nil, true)
      deck << Card.new(nil, nil, :plus4)
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

  def set_next_action

    case top_card.value
    when :plus4
      @action = :draw
      @draw_amount += 4

    when :plus2
      @action = :draw
      @draw_amount += 2

    when :skip
      @action = :skip

    when :reverse
      @action = :reverse

    else
      @action = nil
      @draw_amount = 0
    end

  end

  def play_round
    @round += 1

    @players.each do |p|

      case @action
      when :draw

        if p.can_play?
          p.play_card
          set_next_action
        else
          @draw_amount.times { p.draw_card }
          @draw_amount = 0
          @action = nil
        end

      when :skip
        @action = nil

      when :reverse
        @players.reverse!
        @action = nil

      else
        p.draw_card until p.can_play?
        p.play_card
        set_next_action
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
