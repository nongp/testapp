class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: [:approve, :decline]

  def create
    room = Room.find(params[:room_id])

    if current_user == room.user
      flash[:alert] = "You cannot book your own property!"
    elsif current_user.stripe_id.blank?
      flash[:alert] = "Please update your payment method."
      return redirect_to payment_method_path
    else
      start_date = Date.parse(reservation_params[:start_date])
      end_date = Date.parse(reservation_params[:end_date])
      days = (end_date - start_date).to_i + 1

      special_dates = room.calendars.where(
        "status = ? AND day BETWEEN ? AND ? AND price <> ?",
        0, start_date, end_date, room.price
      )

      @reservation = current_user.reservations.build(reservation_params)
      @reservation.room = room
      @reservation.price = room.price
      # @reservation.total = room.price * days
      # @reservation.save

      @reservation.total = room.price * (days - special_dates.count)
      special_dates.each do |date|
          @reservation.total += date.price
      end

      if @reservation.Waiting!
        if room.Request?
          flash[:notice] = "Request sent successfully!"
        else
          charge(room, @reservation)
        end
      else
        flash[:alert] = "Cannot make a reservation!"
      end

    end
    redirect_to room
  end

  def your_trips
    @trips = current_user.reservations.order(start_date: :asc)
  end

  def your_reservations
    @rooms = current_user.rooms
  end

  def approve
    charge(@reservation.room, @reservation)
    redirect_to your_reservations_path
  end

  def decline
    @reservation.Declined!
    redirect_to your_reservations_path
  end

  private

    def send_sms(room, reservation)
      @client = Twilio::REST::Client.new
      @client.messages.create(
        from: '+17273996136',
        to: room.user.phone_number,
        body: "New Booking from #{reservation.user.fullname}! - StayNPlay"
      )
    end

    def charge(room, reservation)
          if !reservation.user.omise_id.blank?
        customer = Omise::Customer.retrieve(reservation.user.omise_id)
        charge = Omise::Charge.create(
          :customer => customer.id,
          :amount => reservation.total * 100,
          :description => room.listing_name,
          :currency => "thb"
          )

        if charge
          reservation.Approved!
          ReservationMailer.send_email_to_guest(reservation.user, room).deliver_later if reservation.user.setting.enable_email
          send_sms(room, reservation) if room.user.setting.enable_sms
          flash[:notice] = "เรียบร้อย!! คุณสามารถดูรายละเอียดการจองของคุณได้ที่เมนู 'ทริปของฉัน'"
        else
          reservation.Declined!
          flash[:alert] = "ขออภัยค่ะ ระบบไม่สามารถเรียกเก็บเงินจากบัตรของคุณ กรุณาอัพเดทข้อมูลบัตร Credit หรือบัตร Debit แล้วลองใหม่อีกครั้งค่ะ!"
        end
      end
    end

    def set_reservation
      @reservation = Reservation.find(params[:id])
    end

    def reservation_params
      params.require(:reservation).permit(:start_date, :end_date)
    end
end
