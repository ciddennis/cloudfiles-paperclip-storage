module Paperclip
  module Storage
    # Rackspace's Cloud Files service is a scalable, easy place to store files for
    # distribution, and is integrated into the Limelight CDN. You can find out more about
    # it at http://www.rackspacecloud.com/cloud_hosting_products/files
    #
    #
    # To install the Cloud Files gem, add the Gemcutter gem source ("gem sources -a http://gemcutter.org"), then
    # do a "gem install paperclip_cloud_storage".  For more information, see the github repository at http://github.com/ciddennis/cloudfiles-paperclip-storage
    #
    # There are a few Cloud Files-specific options for has_attached_file:
    # * +cloudfiles_credentials+: Takes a path, a File, or a Hash. The path (or File) must point
    #   to a YAML file containing the +username+ and +api_key+ that Rackspace
    #   gives you. Rackspace customers using the cloudfiles gem >= 1.4.1 can also set a servicenet
    #   variable to true to send traffic over the unbilled internal Rackspace service network.
    #   You can 'environment-space' this just like you do to your
    #   database.yml file, so different environments can use different accounts:
    #     development:
    #       username: hayley
    #       api_key: a7f...
    #     test:
    #       username: katherine
    #       api_key: 7fa...
    #     production:
    #       username: minter
    #       api_key: 87k...
    #       servicenet: true
    #   This is not required, however, and the file may simply look like this:
    #     username: minter...
    #     api_key: 11q...
    #   In which case, those access keys will be used in all environments. You can also
    #   put your container name in this file, instead of adding it to the code directly.
    #   This is useful when you want the same account but a different container for
    #   development versus production.
    # * +container+: This is the name of the Cloud Files container that will store your files.
    #   This container should be marked "public" so that the files are available to the world at large.
    #   If the container does not exist, it will be created and marked public.
    # * +path+: This is the path under the container in which the file will be stored. The
    #   CDN URL will be constructed from the CDN identifier for the container and the path. This is what
    #   you will want to interpolate. Keys should be unique, like filenames, and despite the fact that
    #   Cloud Files (strictly speaking) does not support directories, you can still use a / to
    #   separate parts of your file name, and they will show up in the URL structure.
    module Cloudfile
      def self.extended base
        begin
          require 'cloudfiles'
        rescue LoadError => e
          e.message << " (You may need to install the cloudfiles gem)"
          raise e
        end
        @@container ||= {}
        base.instance_eval do
          # If they were not passed in then default to yml config file.
          if(!@options[:cloudfiles_credentials])
              @options[:cloudfiles_credentials] = Rails.root.to_s + "/config/paperclip_cloud_storage.yml"
          end

          @cloudfiles_credentials = parse_credentials(@options[:cloudfiles_credentials])
          @container_name         = @options[:container] || @cloudfiles_credentials[:container]
          @container_name         = @container_name.call(self) if @container_name.is_a?(Proc)
          @@cdn_url               = cloudfiles_container.cdn_url
          @path_filename          = ":cf_path_filename" unless @url.to_s.match(/^:cf.*filename$/)
          @url = @@cdn_url + "/#{URI.encode(@path_filename).gsub(/&/, '%26')}"
          @path = (Paperclip::Attachment.default_options[:path] == @options[:path]) ? ":attachment/:id/:style/:basename.:extension" : @options[:path]
        end
        Paperclip.interpolates(:cf_path_filename) do |attachment, style|
          attachment.path(style)
        end
      end

      def cloudfiles
        @@cf ||= CloudFiles::Connection.new(:username => @cloudfiles_credentials[:username], :api_key => @cloudfiles_credentials[:api_key], :snet => @cloudfiles_credentials[:servicenet])
        @@cf
      end

      def create_container
        container = cloudfiles.create_container(@container_name)
        container.make_public
        container
      end

      def cloudfiles_container
        @@container[@container_name] ||= create_container
      end

      def container_name
        @container_name
      end

      def parse_credentials creds
        creds = find_credentials(creds).stringify_keys
        (creds[Rails.env] || creds).symbolize_keys
      end

      def exists?(style = default_style)
        cloudfiles_container.object_exists?(path(style))
      end

      # Returns representation of the data of the file assigned to the given
      # style, in the format most representative of the current storage.
      def to_file style = default_style
        @queued_for_write[style] || cloudfiles_container.create_object(path(style))
      end

      alias_method :to_io, :to_file

      def flush_writes #:nodoc:
        @queued_for_write.each do |style, file|
          object = cloudfiles_container.create_object(path(style), false)
          object.load_from_filename(file)
        end
        @queued_for_write = {}
      end

      def flush_deletes #:nodoc:
        @queued_for_delete.each do |path|
          cloudfiles_container.delete_object(path)
        end
        @queued_for_delete = []
      end

      def find_credentials creds
        case creds
          when File
            YAML.load_file(creds.path)
          when String
            YAML.load_file(creds)
          when Hash
            creds
          else
            raise ArgumentError, "Credentials are not a path, file, or hash."
        end
      end

      private :find_credentials

    end

  end
end
