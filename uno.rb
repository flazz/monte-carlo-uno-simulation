require 'ruby-debug'

class Array

  def take_random
    i = rand size
    self[i]
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

  def Card.deck
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

    deck
  end

end

class Player

  attr_reader :hand, :name

  def initialize name, game
    @name = name
    @game = game
    @hand = []
    @playable_cards = []
  end

  def draw_card
    @game.recycle_discard_into_draw if @game.draw.empty?
    c = @game.draw.pop
    @hand << c
  end

  def select_playable_cards

    @hand.select do |c|

      if @game.draw_amount == 0
        c.play_on? @game.top_card
      else
        [:plus2, :plus4].include? c.value
      end

    end

  end

  def can_play?
    @playable_cards = select_playable_cards
    @playable_cards.any?
  end

  def play_card
    c = @playable_cards.take_random
    @hand.delete c
    c.color = COLORS.take_random if c.wild?
    @game.discard.push c
    @game.set_next_action
    @playable_cards = []
  end

end

class Uno
  attr_reader :rounds, :winner, :recycles
  attr_reader :discard, :draw, :draw_amount

  def initialize n
    @players = Array.new(n) { |n| Player.new n, self }
    @draw = Card.deck.sort_by { rand }
    @discard = []
    7.times { @players.each { |p| p.draw_card } }
    @discard.push @draw.pop

    # action
    @action = nil
    @draw_amount = 0

    # stats
    @rounds = 0
    @recycles = 0
    @winner = nil
  end

  def report
    [@winner, @rounds, @recycles].join ','
  end

  def top_card
    @discard.last
  end

  def recycle_discard_into_draw
    @recycles += 1
    top = @discard.pop
    raise "no more cards" if @discard.empty?
    @draw = @discard.sort_by { rand }
    @discard = [top]
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
      reset_action
    end

  end

  def reset_action
    @action = nil
    @draw_amount = 0
  end

  def play_round
    @rounds += 1

    @players.each do |p|

      case @action
      when :draw

        if p.can_play?
          p.play_card
        else
          @draw_amount.times { p.draw_card }
          reset_action
        end

      when :skip
        reset_action

      when :reverse
        @players.reverse!
        reset_action

      else
        p.draw_card until p.can_play?
        p.play_card
      end

      if p.hand.empty?
        @winner = @players.index p
        break
      end

    end

  end

end

10000.times do
  uno = Uno.new 5
  uno.play_round until uno.winner
  puts uno.report
end
