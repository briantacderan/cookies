class PagesController < ApplicationController

  def home
    @chips = Chip.all
  end
    
  def menu
  end

  def about
  end

end
