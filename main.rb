require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def calculate_total(cards)
    array = cards.map{|element| element[1]}

    total = 0
    array.each do |a|
    	if a == "A"
    		total += 11
    	elsif a == "J"
    		total += 10
    	elsif a == "Q"
    		total += 10
    	elsif a == "K"
    		total += 10
    	else
    		total += a.to_i
    	end
    end

    array.select{|element| element == "A"}.count.times do
    	break if total <= 21
    	total -= 10
    end

    total
  end

  def card_display(card)
    suit = case card[0]
      when "H" then "hearts"
      when "D" then "diamonds"
      when "C" then "clubs"
      when "S" then "spades"
    end

    value = card[1]
    if ["J", "Q", "K", "A"].include?(value)
      value = case card[1]
        when "J" then "jack"
      	when "Q" then "queen"
      	when "K" then "king"
      	when "A" then "ace"
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def money_on_hand_win(last_round_bet)
    session[:player_money] = session[:player_money] + last_round_bet 
  end

  def money_on_hand_loss(last_round_bet)
    session[:player_money] = session[:player_money] - last_round_bet
  end
end

before do
  @show_hit_or_stay_buttons = true
  @gameoff = false 
end

get "/" do
  redirect "/new_player"
end

get "/new_player" do
  session[:player_money] = 2015
  erb :new_player
end

post "/new_player" do
  session[:player_name] = params[:player_name]
  redirect "/betting"
end

get "/betting" do
  #session[:player_money] = 2015
  #session[:round_bet] = nil
  erb :betting
end

get "/betting_dos" do
  erb :betting
end

post "/bettingthehouse" do
  #session[:player_money] = 2000
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0 || params[:bet_amount].to_i < 0
  @error = "You must enter an appropriate bet amount."
  halt erb(:betting)
  elsif params[:bet_amount].to_i > session[:player_money]
  @error = "You must enter an appropriate bet amount. You do not have that much money."
  halt erb(:betting)
  else
  session[:round_bet] = params[:bet_amount].to_i
  redirect '/game'
  #erb :betting 
  end
  redirect '/game'
  #redirect "/game/computerturn"
end

get "/game" do
	suits = ["H", "D", "C", "S"]
	values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_hand] = []
  session[:player_hand] = []
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  erb :game
end

post "/game/player/stay" do
  @success = "You have chosen to stay"
  @show_hit_or_stay_buttons = false
  redirect "/game/computerturn"
end

post "/game/player/hit" do
  session[:player_hand] << session[:deck].pop
  if calculate_total(session[:player_hand]) > 21
  	@error = "Sorry, it looks like you busted. You have lost."
  	@show_hit_or_stay_buttons = false
    @gameoff = true
    #@conquer = false
    money_on_hand_loss(session[:round_bet])
  end
  erb :game, layout: false
  #erb :playagain
end

get "/game/computerturn" do
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_hand])
  if dealer_total == 21
    @error = "Computer hit blackjack! You lose."
    @gameoff = true
    #@conquer = false
    money_on_hand_loss(session[:round_bet])
  elsif dealer_total > 21
    @error = "The computer's total is over 21. You win."
    @gameoff = true
    #@conquer = true
    money_on_hand_win(session[:round_bet])
  elsif dealer_total >= 17
    redirect "/game/winnerdecision"
  else 
    @show_dealer_hit_button = true 
    redirect "/game/dealer/hit"
  end
  erb :game, layout: false
end

get "/game/dealer/hit" do
  @show_hit_or_stay_buttons = false
  session[:dealer_hand] << session[:deck].pop
  #while calculate_total(session[:dealer_hand]) < 17
   # @show_dealer_hit_button = true
  #end
  erb :game
  redirect "/game/computerturn"
end

get "/game/winnerdecision" do 
  @show_hit_or_stay_buttons = false
  player = calculate_total(session[:player_hand])
  dealer = calculate_total(session[:dealer_hand])
  if player > dealer
    @success = "Congratulations! You win."
    @gameoff = true
    #@conquer = true
    money_on_hand_win(session[:round_bet])
  elsif dealer > player
    @error = "Sorry, you lose. Better luck next time."
    @gameoff = true
    #@conquer = false
    money_on_hand_loss(session[:round_bet])
  else dealer == player
    @error = "Unlucky. The game has ended in a tie."
    @gameoff = true
  end
  erb :game
  #erb :playagain
end

post "/end" do
  erb :playagain
end













