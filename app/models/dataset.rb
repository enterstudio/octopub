# == Schema Information
#
# Table name: datasets
#
#  id                :integer          not null, primary key
#  name              :string
#  url               :string
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#  repo              :string
#  description       :text
#  publisher_name    :string
#  publisher_url     :string
#  license           :string
#  frequency         :string
#  datapackage_sha   :text
#  owner             :string
#  owner_avatar      :string
#  build_status      :string
#  full_name         :string
#  certificate_url   :string
#  job_id            :string
#  publishing_method :integer          default("github_public"), not null
#

class Dataset < ApplicationRecord

  enum publishing_method: [:github_public, :github_private, :local_private]

  # Note it is the user who is logged in and creates the dataset
  # It can be owned by someone else
  belongs_to :user
  has_many :dataset_files

  after_update :update_dataset_in_github, unless: Proc.new { |dataset| dataset.local_private? }
  after_destroy :delete_dataset_in_github, unless: Proc.new { |dataset| dataset.local_private? }

  validate :check_repo, on: :create
  validates_associated :dataset_files

  def report_status(channel_id, action = :create)
    Rails.logger.info "Dataset: in report_status #{channel_id}"
    Rails.logger.info "Dataset: file count: #{dataset_files.count}"
    if valid?
      Pusher[channel_id].trigger('dataset_created', self) if channel_id
      Rails.logger.info "Dataset: Valid so now do the save and trigger the after creates"
      save
      if publishing_method == 'local_private'
        send_success_email
      end

      unless publishing_method == 'local_private' || action == :update
        # You only want to do this if it's private or public github
        CreateRepository.perform_async(id) unless publishing_method == 'local_private'
      end
    else
      Rails.logger.info "Dataset: In valid, so push to pusher"
      messages = errors.full_messages
      dataset_files.each do |file|
        unless file.valid?
          Rails.logger.info "Dataset: Check file is valid"
          (file.errors.messages[:file] || []).each do |message|
            messages << "Your file '#{file.title}' #{message}"
          end
        end
      end
      if channel_id
        Pusher[channel_id].trigger('dataset_failed', messages.uniq)
      else
        Error.create(job_id: self.job_id, messages: messages.uniq)
      end
    end
  end

  def path(filename, folder = "")
    File.join([folder,filename].reject { |n| n.blank? })
  end

  def config
    {
      "data_dir" => '.',
      "update_frequency" => frequency,
      "permalink" => 'pretty'
    }.to_yaml
  end

  def github_url
    "http://github.com/#{full_name}"
  end

  def gh_pages_url
    "http://#{repo_owner}.github.io/#{repo}"
  end

  def full_name
    "#{repo_owner}/#{repo}"
  end

  def restricted
    ! github_public?
  end

  def repo_owner
    owner.presence || user.github_username
  end

  def actual_repo
    @actual_repo ||= RepoService.fetch_repo(self)
  end

  def schema_names
    names = dataset_files.map {|df| df.schema_name }.compact
    names.join(', ') unless names.nil?
  end

  def complete_publishing
    actual_repo
    set_owner_avatar
    publish_public_views(true)
    send_success_email
    SendTweetService.new(self).perform
  end

  private

    # This is a callback
    def update_dataset_in_github
      Rails.logger.info "in update_dataset_in_github"
      return if local_private?

      jekyll_service.update_dataset_in_github
      make_repo_public_if_appropriate
      publish_public_views
    end

    def make_repo_public_if_appropriate
      Rails.logger.info "in make_repo_public_if_appropriate"
      # Should the repo be made public?
      if publishing_method_changed? && github_public?
        RepoService.new(actual_repo).make_public
      end
    end

    def publish_public_views(new_record = false)
      Rails.logger.info "in publish_public_views"
      return if restricted
      if new_record || publishing_method_changed?
        # This is either a new record or has just been made public
        jekyll_service.create_public_views(self)
      end
      # updates to existing public repos are handled in #update_in_github
    end

    # This is a callback
    def delete_dataset_in_github
      begin
        jekyll_service.delete_dataset_in_github
      rescue Octokit::NotFound
        Rails.logger.info "Repository does not exist"
      end
    end

    def check_repo
      Rails.logger.info "in check_repo"
      repo_name = "#{repo_owner}/#{name.parameterize}"
      if user.octokit_client.repository?(repo_name)
        errors.add :repository_name, 'already exists'
      end
    end

    def set_owner_avatar
      Rails.logger.info "in set_owner_avatar"
      if owner.blank? || owner == user.github_username
        update_column :owner_avatar, user.avatar
      else
        update_column :owner_avatar, Rails.configuration.octopub_admin.organization(owner).avatar_url
      end
    end

    def send_success_email
      Rails.logger.info "in send_success_email"
      DatasetMailer.success(self).deliver
    end

    def jekyll_service
      Rails.logger.info "jekyll_service called, so set with #{repo}"
      @jekyll_service ||= JekyllService.new(self, actual_repo)
    end
end
