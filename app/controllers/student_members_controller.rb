# frozen_string_literal: true

class StudentMembersController < ApplicationController
  before_action :set_student_member, only: %i[show edit update destroy dashboard events]
  before_action :admin?, only: [:destroy]
  before_action :allowed_to_view?, only: %i[show edit update dashboard]
  before_action :points_add, only: %i[eventcode]

  # GET /student_members or /student_members.json
  def index
    @student_members = StudentMember.all
  end

  # GET /student_members/1 or /student_members/1.json
  def show; end

  def dashboard
    @student_member = StudentMember.find(params[:id])
  end

  def events
    @student_member = if StudentMember.find_by(id: params[:id])
                        StudentMember.find(params[:id])
                      else
                        StudentMember.find_by(uid: session[:uid])
                      end
    @events = Event.all
    @event_student_members = EventStudentMember.all
  end

  # GET /student_members/new
  def new
    # nobody is allowed to create an account if their account already exists
    redirect_to(pages_unauthorized_path) unless session[:userID].nil?
    @student_member = StudentMember.new
  end

  # GET /student_members/1/edit
  def edit; end

  # POST /student_members or /student_members.json
  def create
    @student_member = StudentMember.new(student_member_params)

    respond_to do |format|
      if @student_member.save
        session[:isAdmin] = StudentMember.where(uid: session[:uid]).pick(:member_title) == 'officer'
        session[:isMember] = StudentMember.find_by(uid: session[:uid])
        session[:userID] = StudentMember.where(uid: session[:uid]).pick(:id)
        format.html { redirect_to(student_member_url(@student_member), notice: 'Student member was successfully created.') }
        format.json { render(:show, status: :created, location: @student_member) }
      else
        format.html { render(:new, status: :unprocessable_entity) }
        format.json { render(json: @student_member.errors, status: :unprocessable_entity) }
      end
    end
  end

  # PATCH/PUT /student_members/1 or /student_members/1.json
  def update
    respond_to do |format|
      if @student_member.update(student_member_params)
        format.json { render(:show, status: :ok, location: @student_member) }
        if Integer(params[:id], 10) == session[:userID]
          format.html { redirect_to(pages_user_dashboard_path(@student_member), notice: 'Account was successfully updated.') }
        else
          format.html { redirect_to(student_member_path(@student_member), notice: 'Account was successfully updated.') }
        end
      else
        format.html { render(:edit, status: :unprocessable_entity) }
        format.json { render(json: @student_member.errors, status: :unprocessable_entity) }
      end
    end
  end

  def points_add
    @student_member = StudentMember.find(params[:mid])
    @meeting_points = @student_member.meeting_point_amount + 1
    @social_points = @student_member.social_point_amount + 1
    @informational_points = @student_member.informational_point_amount + 1
    @fundraising_points = @student_member.fundraiser_point_amount + 1
  end

  def eventcode
    @event = Event.find(params[:eid])
    @ec = params[:event_code_entered]
    @ec_i = Integer(@ec, 10)
    @student_member = StudentMember.find(params[:mid])
    respond_to do |format|
      if (@ec_i == @event.event_code) && (@event.event_type == 'meeting')
        @student_member.update!(meeting_point_amount: @meeting_points)
        format.html { redirect_to(events_student_member_path(@student_member), notice: 'Points have been updated') }
      elsif (@ec_i == @event.event_code) && (@event.event_type == 'social')
        @student_member.update!(social_point_amount: @social_points)
        format.html { redirect_to(events_student_member_path(@student_member), notice: 'Points have been updated') }
      elsif (@ec_i == @event.event_code) && (@event.event_type == 'informational')
        @student_member.update!(informational_point_amount: @informational_points)
        format.html { redirect_to(events_student_member_path(@student_member), notice: 'Points have been updated') }
      elsif (@ec_i == @event.event_code) && (@event.event_type == 'fundraising')
        @student_member.update!(fundraiser_point_amount: @fundraising_points)
        format.html { redirect_to(events_student_member_path(@student_member), notice: 'Points have been updated') }
      else
        Rails.logger.debug(@event.event_type)
        format.html { redirect_to(events_student_member_path(@student_member), notice: 'Incorrect Code entered') }
      end
    end
  end

  # DELETE /student_members/1 or /student_members/1.json
  def destroy
    @student_member.destroy!

    respond_to do |format|
      format.html { redirect_to(student_members_url, notice: 'Student member was successfully destroyed.') }
      format.json { head(:no_content) }
    end
  end

  def search
    @student_members = StudentMember.search(params[:q])
    render('index')
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_student_member
    @student_member = if StudentMember.find_by(id: params[:id])
                        StudentMember.find(params[:id])
                      else
                        StudentMember.find_by(uid: session[:uid])
                      end
  end

  # Only allow a list of trusted parameters through.
  def student_member_params
    params.require(:student_member).permit(:uin, :first_name, :last_name, :class_year, :join_date, :member_title, :email, :phone_number,
                                           :expected_graduation_date, :social_point_amount, :meeting_point_amount, :fundraiser_point_amount,
                                           :informational_point_amount, :officer_title, :dues_paid, :picture, :uid
    )
  end
end
