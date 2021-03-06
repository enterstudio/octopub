# == Schema Information
#
# Table name: dataset_files
#
#  id                     :integer          not null, primary key
#  title                  :string
#  filename               :string
#  mediatype              :string
#  dataset_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  description            :text
#  file_sha               :text
#  view_sha               :text
#  dataset_file_schema_id :integer
#  storage_key            :string
#

class DatasetFile < ApplicationRecord

  belongs_to :dataset
  belongs_to :dataset_file_schema

  validate :check_schema, if: :dataset_file_schema
  validate :check_csv
  validates_presence_of :title
  validates_presence_of :storage_key

  after_validation :set_filename

  attr_accessor :file

  def self.file_from_url(file)
    Rails.logger.info "DatasetFile: In file_from_url"
    tempfile = Tempfile.new 'uploaded'
    tempfile.write read_file_with_utf_8(file)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new filename: File.basename(file),
                                           content_type: 'text/csv',
                                           tempfile: tempfile
  end

  def self.file_from_url_with_storage_key(file, storage_key)
    Rails.logger.info "DatasetFile: In file_from_url_with_storage_key"

    fs_file = FileStorageService.get_string_io(storage_key)
    ActionDispatch::Http::UploadedFile.new filename: File.basename(file),
                                           content_type: 'text/csv',
                                           tempfile: fs_file
  end

  def self.read_file_with_utf_8(file)
    open(URI.escape(file)).read.force_encoding("UTF-8")
  end

  def self.new_file(dataset_file_creation_hash)
    Rails.logger.info "DatasetFile: In new_file"
    # allow use of hashes or strings for keys
    dataset_file_creation_hash = get_file_from_the_right_place(dataset_file_creation_hash)
    Rails.logger.info "Dataset file created using new file #{dataset_file_creation_hash[:file]} key: #{dataset_file_creation_hash[:storage_key]}"
    # Do the actual create here
    create(
      title: dataset_file_creation_hash[:title],
      description: dataset_file_creation_hash[:description],
      file: dataset_file_creation_hash[:file],
      storage_key: dataset_file_creation_hash[:storage_key],
      dataset_file_schema_id: dataset_file_creation_hash[:dataset_file_schema_id]
    )
  end

  def self.get_file_from_the_right_place(dataset_file_hash)
    dataset_file_hash = ActiveSupport::HashWithIndifferentAccess.new(dataset_file_hash)
    if dataset_file_hash[:file].class == String
      if dataset_file_hash[:storage_key]
        dataset_file_hash[:file] = file_from_url_with_storage_key(dataset_file_hash[:file], dataset_file_hash[:storage_key])
      else
        dataset_file_hash[:file] = file_from_url(dataset_file_hash[:file])
      end
    end
    dataset_file_hash
  end

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  def schema_name
    dataset_file_schema.name if dataset_file_schema
  end

  def update_file(file_update_hash)
    Rails.logger.info "DatasetFile: In update_file"
    file_update_hash = DatasetFile.get_file_from_the_right_place(file_update_hash)

    update_hash = {
      description: file_update_hash[:description],
      file: file_update_hash[:file],
      dataset_file_schema_id: file_update_hash[:dataset_file_schema_id],
      storage_key: file_update_hash[:storage_key]
    }.delete_if { |_k,v| v.nil? }

    self.update(update_hash)
  end

  private

    def check_schema
      Rails.logger.info "DatasetFile: In check schema"
      if dataset_file_schema
        if dataset_file_schema.is_schema_valid?
          if dataset_file_schema.csv_on_the_web_schema
            validate_schema_cotw
          else
            validate_schema_non_cotw
          end
        else
          errors.add(:schema, 'is not valid')
        end
      end
    end

    def validate_schema_cotw
      Rails.logger.info "DatasetFile: we have COTW schema and schema is valid, so validate"

      schema = Csvlint::Schema.load_from_json(URI.escape dataset_file_schema.url)
      tempfile = get_file_for_validation_from_file

      if schema.respond_to? :tables
        schema.tables["file:#{tempfile.path}"] = schema.tables.delete(schema.tables.keys.first)
      end
      validation = Csvlint::Validator.new(tempfile, {}, schema)

      errors.add(:file, 'does not match the schema you provided') unless validation.valid?
      Rails.logger.info "DatasetFile: check schema, number of errors #{errors.count}"
      errors
    end


    def validate_schema_non_cotw
      Rails.logger.info "DatasetFile: we have non COTW schema and schema is valid, so validate"

      schema = Csvlint::Schema.load_from_json(URI.escape dataset_file_schema.url)

      string_io = FileStorageService.get_string_io(storage_key)
      validation = Csvlint::Validator.new(string_io, {}, schema)

      errors.add(:file, 'does not match the schema you provided') unless validation.valid?
      Rails.logger.info "DatasetFile: check schema, number of errors #{errors.count}"
      errors
    end

    def get_file_for_validation_from_file
      File.new(file.tempfile)
    end

    def check_csv
      if dataset && storage_key
        string_io = FileStorageService.get_string_io(storage_key)
        unless string_io.nil?
          begin
            CSV.parse(string_io.read)
          rescue CSV::MalformedCSVError
            errors.add(:file, 'does not appear to be a valid CSV. Please check your file and try again.')
          rescue
            errors.add(:file, 'had some problems trying to upload. Please check your file and try again.')
          ensure
            string_io.rewind
          end
        end
      end
    end

    def set_filename
      self.filename = "#{title.parameterize}.csv" rescue nil
    end

end
