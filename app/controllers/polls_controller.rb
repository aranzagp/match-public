class PollsController < ApplicationController
  def index
    @poll = Poll.last
    redirect_to poll_path(@poll.id)
  end

  def show
    @poll = Poll.find(params[:id])
    @activities = Activity.from_a_poll(@poll.activities_from, @poll.activities_to)
    @activities_votes = if current_user.role == 'judge'
                          Vote.judge_activities_votes(@poll.id)
                        else
                          Vote.user_activities_votes(@poll.id, current_user.id)
                        end
    @activity_types = @activities.group(:activity_type).select(:activity_type)
    @best_activities = []
    3.times { |i| @best_activities << Activity.best_activities(@poll.id, i) }

    return unless @activities.empty?

    flash[:alert] = t('poll.empty_activities')
    redirect_to main_index_path
  end
end