class AvailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :set_current_month, except: [:index, :preview_holidays]

  def index
    @availabilities = @group.availabilities.where(user: current_user).order(:start_date)
    @availability = Availability.new
  end

  def create
    service = AvailabilityService.new(user: current_user, group: @group)

    if service.add(
      start_date: Date.parse(availability_params[:start_date]),
      end_date: Date.parse(availability_params[:end_date])
    )
      prepare_turbo_response
      respond_with_turbo(success: t('availabilities.create.success'))
    else
      prepare_turbo_response
      respond_with_turbo(error: service.errors.join(", "))
    end
  end

  def destroy
    @availability = @group.availabilities.find(params.expect(:id))

    if @availability.user == current_user
      @availability.destroy
      prepare_turbo_response
      respond_with_turbo(success: t('availabilities.destroy.success'))
    else
      redirect_to @group, alert: t('notifications.not_authorized')
    end
  end

  def remove_range
    service = AvailabilityService.new(user: current_user, group: @group)

    if service.remove(
      start_date: Date.parse(params[:start_date]),
      end_date: Date.parse(params[:end_date])
    )
      prepare_turbo_response
      respond_with_turbo(success: t('availabilities.remove_range.success'))
    else
      prepare_turbo_response
      respond_with_turbo(error: service.errors.join(", "))
    end
  end

  def preview_holidays
    year = params[:year]&.to_i || Date.today.year
    holidays = Holidays.between(Date.new(year, 1, 1), Date.new(year, 12, 31), :br)

    render json: {
      year: year,
      count: holidays.count,
      holidays: holidays.map { |h| format_holiday(h) }
    }
  end

  def add_all_holidays
    year = params[:year]&.to_i || @current_month.year
    holidays = Holidays.between(Date.new(year, 1, 1), Date.new(year, 12, 31), :br)

    if holidays.empty?
      prepare_turbo_response
      respond_with_turbo(error: t('availabilities.add_all_holidays.no_holidays', year: year))
      return
    end

    added_count = holidays.count { |holiday| create_availability_for_date(holiday[:date]) }
    prepare_turbo_response
    respond_with_turbo(success: t('availabilities.add_all_holidays.success', count: added_count, year: year))
  end

  def batch_destroy
    availability_ids = params[:availability_ids] || []

    if availability_ids.empty?
      redirect_to @group, alert: t('availabilities.batch_destroy.no_selection')
      return
    end

    deleted_count = @group.availabilities.where(id: availability_ids, user: current_user).destroy_all.count
    prepare_turbo_response
    respond_with_turbo(success: t('availabilities.batch_destroy.success', count: deleted_count))
  end

  private

  def set_group
    @group = Group.find(params.expect(:group_id))
  end

  def set_current_month
    @current_month = params[:current_month] ? Date.parse(params[:current_month]) : Date.today
  end

  def prepare_turbo_response
    @group.availabilities.reload
    @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)
    @user_availability = @group.availabilities.where(user: current_user)
  end

  def respond_with_turbo(success: nil, error: nil)
    message = success || error
    notice_type = success ? :notice : :alert

    respond_to do |format|
      format.html { redirect_to @group, notice_type => message }
      format.turbo_stream do
        response.content_type = "text/vnd.turbo-stream.html"
        render "availabilities/create"
      end
    end
  end

  def create_availability_for_date(date)
    service = AvailabilityService.new(user: current_user, group: @group)
    service.add(start_date: date, end_date: date)
  end

  def format_holiday(holiday)
    {
      date: holiday[:date].strftime("%B %d, %Y"),
      date_iso: holiday[:date].to_s,
      name: holiday[:name],
      day_of_week: holiday[:date].strftime("%A")
    }
  end

  def availability_params
    params.expect(availability: [:start_date, :end_date])
  end
end
