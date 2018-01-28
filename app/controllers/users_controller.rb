class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:show]

  def show
    @user = User.find(params[:id])
    @rooms = @user.rooms

    # Display all the guest reviews to host (if this user is a host)
    @guest_reviews = Review.where(type: "GuestReview", host_id: @user.id)

    # Display all the host reviews to host (if this user is a guest)
    @host_reviews = Review.where(type: "HostReview", guest_id: @user.id)
  end

  def update_phone_number
    current_user.update_attributes(user_params)
    current_user.generate_pin
    current_user.send_pin

    redirect_to edit_user_registration_path, notice: "Saved..."
  rescue Exception => e
    redirect_to edit_user_registration_path, alert: "#{e.message}"
  end

  def verify_phone_number
    current_user.verify_pin(params[:user][:pin])

    if current_user.phone_verified
      flash[:notice] = "Your phone number is verified."
    else
      flash[:alert] = "Cannot verify your phone number."
    end

    redirect_to edit_user_registration_path

  rescue Exception => e
    redirect_to edit_user_registration_path, alert: "#{e.message}"
  end

  def payment
  end

  def payout
  #  if !current_user.merchant_id.blank?
  #    account = Stripe::Account.retrieve(current_user.merchant_id)
  #    @login_link = account.login_links.create()
  end


  def add_card
    begin
      if current_user.omise_id.blank?
        customer = Omise::Customer.create(
        email: current_user.email,
        description: "Add Card",
        card: params[:omise_token]
        )
        current_user.omise_id = customer.id
        current_user.save

        # Add Credit Card to Omise
        #customer.sources.create(source: params[:omiseToken])
        else
        customer = Omise::Customer.retrieve(current_user.omise_id)
        customer.id = current_user.omise_id
        customer.save
      end

        flash[:notice] = "Your card is saved."
        redirect_to payment_method_path
      rescue TypeError, NameError => e
        flash[:alert] = e.message
        redirect_to payment_method_path
      end
  end


  private
    def user_params
      params.require(:user).permit(:phone_number, :pin)
    end
end  
