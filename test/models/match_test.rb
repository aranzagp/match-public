# == Schema Information
#
# Table name: matches
#
#  id         :bigint(8)        not null, primary key
#  match_type :integer
#  version    :integer
#  start_date :datetime
#  end_date   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class MatchTest < ActiveSupport::TestCase
  setup do
    @match = matches(:project_match)
  end

  test 'matches can have activities' do
    activity1 = activities(:simple_activity)
    activity2 = activities(:simple_activity2)

    @match.activities << activity1
    activity2.update_attribute(:match_id, @match.id)

    assert_equal(@match.activities.length, 2)
    assert_equal(activity2, @match.activities.first)
    assert_equal(activity1, @match.activities.last)
    assert_equal(activity1.match, @match)
  end

  test 'matches can have teams' do
    team1 = teams(:team1)
    team2 = teams(:team2)

    @match.teams << team1
    team2.update_attribute(:match_id, @match.id)

    assert_equal(@match.teams.length, 2)
    assert_equal(team1, @match.teams.first)
    assert_equal(team2, @match.teams.last)
    assert_equal(team1.match, @match)
  end

  test 'matches can have projects' do
    project1 = projects(:simple_project)
    project2 = projects(:simple_project2)

    @match.projects << project1
    project2.update_attribute(:match_id, @match.id)

    assert_equal(@match.projects.length, 2)
    assert_equal(project1, @match.projects.first)
    assert_equal(project2, @match.projects.last)
    assert_equal(project1.match, @match)
  end

  test 'matches cannot be created if required fields are not present' do
    assert_raises(ActiveRecord::RecordInvalid) { Match.create!(match_type: 'Content', start_date: '2019-04-12') }
    assert_raises(ActiveRecord::RecordInvalid) { Match.create!(match_type: 'Content', end_date: '2019-04-12') }
    assert_raises(ActiveRecord::RecordInvalid) { Match.create!(start_date: '2019-04-12', end_date: '2019-04-12') }
    assert(Match.create(match_type: 'Content', start_date: '2019-04-12', end_date: '2019-04-12'))
  end
end
