class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :show, :edit, :update, :destroy, :results, :join, :leave, :remove_member ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :remove_member ]

  def index
    @groups = current_user.groups.includes(:owner, :members).order(created_at: :desc)
    @public_groups = Group.where(is_public: true).where.not(id: @groups.pluck(:id)).includes(:owner, :members).order(created_at: :desc)
  end

  def show
    @members = @group.all_users.includes(:availabilities)
    @user_availability = @group.availabilities.where(user: current_user)
    @current_month = params[:month] ? Date.parse(params[:month]) : Date.today
    @calendar_data = helpers.calendar_data_for_month(@current_month, @group, current_user)
  end

  def new
    @group = Group.new
  end

  def create
    @group = current_user.owned_groups.build(group_params)

    if @group.save
      redirect_to @group, notice: t('notifications.group_created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: t('notifications.group_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_url, notice: t('notifications.group_deleted')
  end

  def results
    @date_analysis = calculate_availability_results
  end

  def join
    if @group.is_public && !@group.members.include?(current_user)
      @group.group_memberships.create(user: current_user)
      redirect_to @group, notice: t('notifications.member_joined')
    else
      redirect_to @group, alert: t('notifications.not_authorized')
    end
  end

  def leave
    membership = @group.group_memberships.find_by(user: current_user)
    if membership && @group.owner != current_user
      membership.destroy
      redirect_to groups_path, notice: t('notifications.member_left')
    else
      redirect_to @group, alert: t('notifications.not_authorized')
    end
  end

  def remove_member
    user_to_remove = User.find(params[:user_id])
    membership = @group.group_memberships.find_by(user: user_to_remove)

    if user_to_remove == @group.owner
      redirect_to @group, alert: t('notifications.cannot_remove_owner')
    elsif membership
      # Delete the member's availabilities in this group
      @group.availabilities.where(user: user_to_remove).destroy_all
      # Then remove the membership
      membership.destroy
      redirect_to @group, notice: t('notifications.member_removed')
    else
      redirect_to @group, alert: t('notifications.member_not_found')
    end
  end

  private

  def set_group
    @group = Group.find(params.expect(:id))
  rescue ActiveRecord::RecordNotFound
    redirect_to groups_path, alert: t('notifications.group_not_found')
  end

  def authorize_owner!
    unless @group.owner == current_user
      redirect_to @group, alert: t('notifications.not_authorized')
    end
  end

  def group_params
    params.expect(group: [ :name, :description, :is_public, :weekends_only ])
  end

  def calculate_availability_results
    availabilities = @group.availabilities.includes(:user)
    all_dates = {}

    availabilities.each do |availability|
      availability.date_range.each do |date|
        # Skip weekdays if weekends_only filter is enabled
        next if @group.weekends_only && !weekend_or_holiday?(date)

        all_dates[date] ||= []
        all_dates[date] << availability.user
      end
    end

    total_members = @group.all_users.count
    all_dates.sort_by { |date, _users| date }.map do |date, users|
      {
        date: date,
        users: users.uniq,
        count: users.uniq.count,
        percentage: (users.uniq.count.to_f / total_members * 100).round(1),
        is_full: users.uniq.count == total_members
      }
    end.sort_by { |d| [ -d[:count], d[:date] ] }
  end

  def weekend_or_holiday?(date)
    # Saturday (6) or Sunday (0)
    is_weekend = date.wday == 0 || date.wday == 6
    is_holiday = Holidays.on(date, :br).any?
    is_weekend || is_holiday
  end
end
