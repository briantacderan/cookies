class PagesController < ApplicationController

  def home
    @chips = Chip.all
    @user = current_user
  end
    
  def menu
  end

  def about
  end

end
