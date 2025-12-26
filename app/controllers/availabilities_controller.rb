class AvailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group

  def index
    @availabilities = @group.availabilities.where(user: current_user).order(:start_date)
    @availability = Availability.new
  end

  def create
    @current_month = params[:current_month] ? Date.parse(params[:current_month]) : Date.today

    creator = AvailabilityCreator.new(
      user: current_user,
      group: @group,
      start_date: Date.parse(availability_params[:start_date]),
      end_date: Date.parse(availability_params[:end_date])
    )

    if creator.call
      @availability = creator.availability
      # Explicitly reload the availabilities association to clear cache
      @group.availabilities.reload
      # Prepare calendar data AFTER saving for Turbo Stream response
      @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)

      respond_to do |format|
        format.html { redirect_to @group, notice: t('availabilities.create.success') }
        format.turbo_stream { response.content_type = "text/vnd.turbo-stream.html" }
      end
    else
      @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)
      respond_to do |format|
        format.html { redirect_to @group, alert: creator.errors.join(", ") }
        format.turbo_stream
      end
    end
  end

  def destroy
    @availability = @group.availabilities.find(params.expect(:id))
    @current_month = params[:current_month] ? Date.parse(params[:current_month]) : Date.today

    if @availability.user == current_user
      @availability.destroy
      # Explicitly reload the availabilities association to clear cache
      @group.availabilities.reload
      # Prepare calendar data AFTER destroying for Turbo Stream response
      @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)

      respond_to do |format|
        format.html { redirect_to @group, notice: t('availabilities.destroy.success') }
        format.turbo_stream { response.content_type = "text/vnd.turbo-stream.html" }
      end
    else
      redirect_to @group, alert: t('notifications.not_authorized')
    end
  end

  def remove_range
    @current_month = params[:current_month] ? Date.parse(params[:current_month]) : Date.today

    remover = AvailabilityRemover.new(
      user: current_user,
      group: @group,
      start_date: Date.parse(params[:start_date]),
      end_date: Date.parse(params[:end_date])
    )

    if remover.call
      # Explicitly reload the availabilities association to clear cache
      @group.availabilities.reload
      # Prepare calendar data AFTER removing for Turbo Stream response
      @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)

      respond_to do |format|
        format.html { redirect_to @group, notice: t('availabilities.remove_range.success') }
        format.turbo_stream {
          response.content_type = "text/vnd.turbo-stream.html"
          render "availabilities/create"
        }
      end
    else
      @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)
      respond_to do |format|
        format.html { redirect_to @group, alert: remover.errors.join(", ") }
        format.turbo_stream
      end
    end
  end

  def preview_holidays
    year = params[:year] ? params[:year].to_i : Date.today.year

    # Get all Brazilian holidays for the year
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)

    holidays = Holidays.between(start_date, end_date, :br)

    # Format holidays for JSON response
    holidays_data = holidays.map do |holiday|
      {
        date: holiday[:date].strftime("%B %d, %Y"),
        date_iso: holiday[:date].to_s,
        name: holiday[:name],
        day_of_week: holiday[:date].strftime("%A")
      }
    end

    render json: {
      year: year,
      count: holidays.count,
      holidays: holidays_data
    }
  end

  def add_all_holidays
    @current_month = params[:current_month] ? Date.parse(params[:current_month]) : Date.today
    year = params[:year] ? params[:year].to_i : @current_month.year

    # Get all Brazilian holidays for the year
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)

    holidays = Holidays.between(start_date, end_date, :br)

    if holidays.empty?
      @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)
      respond_to do |format|
        format.html { redirect_to @group, alert: t('availabilities.add_all_holidays.no_holidays', year: year) }
        format.turbo_stream {
          response.content_type = "text/vnd.turbo-stream.html"
          render "availabilities/create"
        }
      end
      return
    end

    # Create availability for each holiday
    added_count = 0
    holidays.each do |holiday|
      holiday_date = holiday[:date]

      # Use AvailabilityCreator to handle merging with existing availabilities
      creator = AvailabilityCreator.new(
        user: current_user,
        group: @group,
        start_date: holiday_date,
        end_date: holiday_date
      )

      if creator.call
        added_count += 1
      end
    end

    # Reload and prepare response
    @group.availabilities.reload
    @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)

    respond_to do |format|
      format.html { redirect_to @group, notice: t('availabilities.add_all_holidays.success', count: added_count, year: year) }
      format.turbo_stream {
        response.content_type = "text/vnd.turbo-stream.html"
        render "availabilities/create"
      }
    end
  end

  def batch_destroy
    @current_month = params[:current_month] ? Date.parse(params[:current_month]) : Date.today
    availability_ids = params[:availability_ids] || []

    if availability_ids.empty?
      redirect_to @group, alert: t('availabilities.batch_destroy.no_selection')
      return
    end

    # Find and destroy only the current user's availabilities
    deleted_count = @group.availabilities
      .where(id: availability_ids, user: current_user)
      .destroy_all
      .count

    @group.availabilities.reload
    @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)

    respond_to do |format|
      format.html { redirect_to @group, notice: t('availabilities.batch_destroy.success', count: deleted_count) }
      format.turbo_stream {
        response.content_type = "text/vnd.turbo-stream.html"
        render "availabilities/create"
      }
    end
  end

  private

  def set_group
    @group = Group.find(params.expect(:group_id))
  end

  def availability_params
    params.expect(availability: [ :start_date, :end_date ])
  end
end
