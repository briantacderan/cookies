class Stripe::CheckoutsController < ApplicationController
  before_action :get_cart_total
  
  def new
    add_cookie_to_cart(params) if params
    authenticate_user!
    flash[:success] = "Cart updated"
    redirect_to root_path
  end

  def show
    @line_items ||= session[:line_items]
    authenticate_user!
  end

  def create
    if current_user.stripe_id?
      customer = Stripe::Customer.retrieve(current_user.stripe_id)
    else
      if current_user
        customer = StripeTool.create_customer(
          email: current_user.email, 
          stripe_token: params[:stripeToken]
        )
        current_user.update!(stripe_id: customer.id)
      else
        redirect_to new_user_session_path
      end
    end
    
    stripe_session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: @line_items,
      customer: customer.id,
      client_reference_id: current_user.id,
      mode: 'payment',
      success_url: "#{stripe_thanks_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url
    })
    
    redirect_to stripe_session.url
  end
 
  def thanks
    session.delete(:line_items)
    @line_items = Array.new
    flash[:success] = "Purchase successful"
  end

  def destroy
    session.delete(:line_items)
    @line_items = Array.new
    flash[:success] = "Cart deleted"
    redirect_to stripe_cart_path
  end

  def webhook
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    begin
      event = Stripe::Webhook.construct_event(request.body.read, sig_header, ENV['STRIPE_ENDPOINT_SECRET'])
    rescue JSON::ParserError
      return head :bad_request
    rescue Stripe::SignatureVerificationError
      return head :bad_request
    end

    webhook_checkout_session_completed(event) if event['type'] == 'checkout.session.completed'

    head :ok
  end

  def interrupt
    current_user.subscription.interrupt
  end
    
  
  private
    
  def add_cookie_to_cart(params)
    price = params[:item][:menu_id] == 1 ? 150 : 200
    line_item = {
      price_data: {
        unit_amount: price,
        currency: 'usd',
        product_data: {
          name: params[:item][:name],
          images: [params[:item][:image]]
        },
      },
      quantity: params[:item][:quantity]
    }
    @line_items.push(line_item)
    session[:line_items] = @line_items
  end

  def get_cart_total
    @amount = 0
    @line_items ||= Array.new
    unless @line_items.nil?
      @line_items.each do |i| 
        @amount += i[:price_data][:unit_amount] * i[:quantity]
      end
    end
    return @amount
  end

  def build_subscription(stripe_subscription)
    Subscription.new(plan_id: stripe_subscription.plan.id,
                     stripe_id: stripe_subscription.id,
                     current_period_ends_at: Time.zone.at(stripe_subscription.current_period_end))
  end

  def webhook_checkout_session_completed(event)
    object = event['data']['object']
    customer = Stripe::Customer.retrieve(object['customer'])
    #stripe_subscription = Stripe::Subscription.retrieve(object['subscription'])
    #subscription = build_subscription(stripe_subscription)
    user = User.find_by(id: object['client_reference_id'])
    #user.subscription.interrupt if user.subscription.present?
    user.update!(stripe_id: customer.id)
  end
end
