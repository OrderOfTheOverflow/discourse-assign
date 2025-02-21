# frozen_string_literal: true

module Jobs
  class UnassignNotification < ::Jobs::Base
    def execute(args)
      raise Discourse::InvalidParameters.new(:topic_id) if args[:topic_id].nil?
      raise Discourse::InvalidParameters.new(:assigned_to_id) if args[:assigned_to_id].nil?
      raise Discourse::InvalidParameters.new(:assigned_to_type) if args[:assigned_to_type].nil?

      topic = Topic.find(args[:topic_id])
      assigned_to_users =
        (
          if args[:assigned_to_type] == "User"
            [User.find(args[:assigned_to_id])]
          else
            Group.find(args[:assigned_to_id]).users
          end
        )

      assigned_to_users.each do |user|
        Assigner.publish_topic_tracking_state(topic, user.id)

        Notification
          .where(
            notification_type: Notification.types[:assigned] || Notification.types[:custom],
            user_id: user.id,
            topic_id: topic.id,
          )
          .where(
            "data like '%discourse_assign.assign_notification%' OR data like '%discourse_assign.assign_group_notification%'",
          )
          .destroy_all
      end
    end
  end
end
