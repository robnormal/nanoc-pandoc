class FilesystemRob < Nanoc::DataSources::FilesystemUnified
	identifier :filesystem_rob

	def self.split_metadata(text)
		# Check presence of metadata section
		if text =~ /\A-{3,5}\s*$/
			extract_metadata(text)

		# Check for MultiMarkdown metadata section
		elsif text =~ /\A[A-Za-z0-9][\w -]*:/
			extract_mmd_metadata(text)

		else
			[ '', text ]
		end
	end


	private
		def self.extract_metadata(text)
      # Split data
      pieces = text.split(/^(-{5}|-{3})\s*$/)
      if pieces.size < 4
        raise RuntimeError.new('Bad metadata')
      end

			[pieces[2], pieces[4..-1].join]
    end

		def self.extract_mmd_metadata(text)
			meta_ls = text.lines.take_while { |l| l !~ /^\s*$/ }
			body = text.lines.drop(meta_ls.size).join('')

			# MultiMarkdown meta keys are case-insensitive, and spaces are stripped
			meta_ls.map! { |l|
				l.sub(/^[A-Za-z0-9][\w -]*:(\s+)/) { |k|
					space = $1
					if k and space
						k.sub(' ', '').downcase() + space
					end
				}
			}

			[ meta_ls.join("\n"), body]
		end

    # Parses the file named `filename` and returns an array with its first
    # element a hash with the file's metadata, and with its second element the
    # file content itself.
    def parse(content_filename, meta_filename, kind)
      if meta_filename
      	# Read content and metadata from separate files
				content = content_filename ? read(content_filename) : ''
				meta_raw = read(meta_filename)
			else
				# Read metadata from file
				data = read content_filename

				begin
					meta_raw, content = FilesystemRob.split_metadata(data)
				rescue RuntimeError => e
					raise RuntimeError.new(
						"The file '#{filename}' appears to start with a metadata section (three or five dashes at the top) but it does not seem to be in the correct format."
					)
				end
      end

			# Parse
			begin
				meta = YAML.load(meta_raw) || {}
			rescue Exception => e
				raise "Could not parse YAML for #{meta_filename || content_filename}: #{e.message}"
			end

			# Done
			[ meta, content.strip ]
		end

end

