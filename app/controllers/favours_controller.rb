class FavoursController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user,   only: :destroy

  def show
    @favour = Favour.find(params[:id])
    @comment = current_user.comments.build if logged_in?
    @comments = @favour.comments.paginate(page: params[:page])

    if !@favour.address.blank?
      split_values = @favour.address.to_s.split(',', 2)
      @location = split_values.last
    end
  end

  def new
    @favour = Favour.new
  end

  def create
    respond_to do |format|
      format.html {
        # Save favours
        @favour = current_user.favours.build(favour_params)

        @favour.deadline = deadline_options_to_time(params[:deadline_option])

        if params[:use_current_location] == 'true'
          @favour.use_location = true
          @favour.latitude = params[:lat]
          @favour.longitude = params[:long]
          @favour.address = params[:address]
        else
          @favour.use_location = false
        end

        if @favour.save
          flash[:success] = 'Favour has been saved!'
          redirect_to @favour
        else
          render 'new'
        end
      }
    end
  end

  def update
    @favour = Favour.find(params[:id])

    @favour.title = params[:favour][:title]
    @favour.description = params[:favour][:description]

    if params[:deadline_option] != "0"
      @favour.deadline = deadline_options_to_time(params[:deadline_option])
    end

    if !params[:address].blank?
      @favour.address = params[:address]
    end

    # Get current location with new coords
    if params[:use_new_current_location] == 'true'
      @favour.use_location = true
      @favour.latitude = params[:lat]
      @favour.longitude = params[:long]

      query = "#{@favour.latitude},#{@favour.longitude}"
      result = Geocoder.search(query).first
      if result.present?
        @favour.address = result.address
      end

    end

    if @favour.save
      flash[:success] = 'Favour updated'
      redirect_to @favour
    else
      render 'edit'
    end
  end

  def edit
    @favour = Favour.find(params[:id])
  end

  def index
    if(!logged_in? || current_user.lat.nil?)
      @favours = Favour.all
    else
      @favours = Favour.near([current_user.lat, current_user.long], 50)
      @favours = @favours + Favour.where(longitude: nil).reverse_order
    end

    @favours = @favours.find_all { |favour| !favour.deadline.nil? && !favour.deadline.past?}
  end

  def destroy
    @favour.destroy
    flash[:success] = 'Favour deleted'
    redirect_to root_url
  end

  private
    def favour_params
      params.require(:favour).permit(:title, :description, :deadline_option, :lat, :long,
                                     :address, :use_current_location, :less_specific_location)
    end

    def correct_user
      @favour = current_user.favours.find_by(id: params[:id])
      redirect_to root_url if @favour.nil?
    end

    def deadline_options_to_time(deadline_option)
      case deadline_option.to_f
        when 1
          (Time.zone.now + 5.minutes).to_datetime
        when 2
          (Time.zone.now.end_of_hour).to_datetime
        when 3
          (Time.zone.now + 3.hours).to_datetime
        when 4
          (Time.zone.now.end_of_day).to_datetime
        when 5
          (Time.zone.now.end_of_week).to_datetime
        when 6
          (Time.zone.now + 100.years).to_datetime
        else 0
      end
    end

end
