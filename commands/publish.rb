usage       'publish file'
aliases     :pu
summary     'Publishes a post'
description 'Dates a file and moves it into place in the posts directory'

flag   :h, :help,  'show help for this command' do |value, cmd|
  puts cmd.help
  exit 0
end

require 'fileutils'
run do |opts, args, cmd|
	infile = args.first

	unless infile && infile.size > 0
		puts cmd.help
		exit 1
	end

	unless File.exist? infile
		puts "No such file: #{infile}"
	end

	# find nanoc directory
	home = File.absolute_path(File.dirname(__FILE__) + '/..')
	content = home + '/content'

	# move file to <nanoc dir>/contents/posts/YYYY/MM/DD-name.md
	now = Time.new
	dir = "#{content}/posts/#{now.year}/#{now.month.to_s.rjust(2,'0')}"
	file = now.day.to_s.rjust(2,'0') + '-' + File.basename(infile)
	outfile = "#{dir}/#{file}" 

	# add created_at metadata
	require(home + '/lib/filesystem_rob.rb')

	meta_raw, content = FilesystemRob.split_metadata(File.read infile)

	meta = YAML::load(meta_raw)

	# insanely, YAML::load returns ... whatever it feels like, including a string
	unless meta.class == Hash
		meta = {}
	end

	# can't use now.to_s, because String#to_yaml interprets it as binary
	meta['created_at'] = now.strftime "%Y-%m-%d %H:%M:%S %z"

	# add meta back to content, removing the first line of YAML (---)
	# for compatibility with MultiMarkdown
	text = (meta.to_yaml + "\n" + content).lines.drop(1).join("\n")

	# create directory if doesn't exist
	FileUtils.mkdir_p dir

	File.write(outfile, text)
end




require 'fileutils'

class Publish < ::Nanoc::CLI::CommandRunner
	def run
		self.load_site

		# Make sure we are in a nanoc site directory
		self.require_site

		# Check arguments
		if arguments.length != 1
			raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
		end

		# Extract arguments and options
		file = arguments[0]

		unless File.exist? file
			puts "No such file: #{file}"
		end

		# Set VCS if possible
		self.set_vcs(options[:vcs])

		# Setup notifications
		Nanoc::NotificationCenter.on(:file_created) do |file_path|
			Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
		end

		outfile = publish_file(file, self.site.config)

		puts "File has been published at #{outfile}"
	end

	private
		def publish_file(infile, config)

			unless infile && infile.size > 0
				raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
			end

			unless File.exist? infile
				raise Nanoc::Errors::GenericTrivial, "No such file: #{infile}"
			end

			# remember: extname includes the dot
			ext = File.extname(infile)[1..-1]

			unless config[:text_extensions].include? ext
				raise Nanoc::Errors::GenericTrivial, "Cannot publish binary file: #{infile}"
			end

			# move file to <nanoc dir>/contents/posts/YYYY/MM/DD-name.md
			now = Time.new
			dir = "./content/posts/#{now.year}/#{now.month.to_s.rjust(2,'0')}"
			file = now.day.to_s.rjust(2,'0') + '-' + File.basename(infile)
			outfile = "#{dir}/#{file}" 

			# add created_at metadata
			require('./lib/filesystem_rob.rb')

			meta_raw, content = FilesystemRob.split_metadata(File.read infile)

			meta = YAML::load(meta_raw)

			# insanely, YAML::load returns ... whatever it feels like, including a string
			unless meta.class == Hash
				meta = {}
			end

			# can't use now.to_s, because String#to_yaml interprets it as binary
			meta['created_at'] = now.strftime "%Y-%m-%d %H:%M:%S %z"

			# add meta back to content, removing the first line of YAML (---)
			# for compatibility with MultiMarkdown
			text = (meta.to_yaml.strip + "\n\n" + content).lines.drop(1).join('')

			# create directory if doesn't exist
			FileUtils.mkdir_p dir

			File.write(outfile, text)
			outfile
		end
end

runner Publish
