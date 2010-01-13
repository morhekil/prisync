$:.unshift File.dirname(__FILE__)

require 'inotify.rb'
require 'pp'

class Prisync 

  DEFAULT_TIMEOUT = 5

  # Initializes INotify events listener object
  def initialize
    @inotify = INotify::INotify.new
    @inotify_mask = INotify::Mask.new(INotify::IN_MODIFY.value | INotify::IN_DELETE.value | INotify::IN_CREATE.value | INotify::IN_MOVED_TO.value, 'filechange')
  end

  # Starts the synchronization process, options are
  #   :local_path - local path to watch for changes,
  #   :target_path - target (remote) path to sync with,
  #   :port - port to use if rsyncing remotely over ssh tunnel
  #   :timeout - seconds to wait for any new changes to arrive before starting the actual synchronization
  #   :exclude - regexp for excluding files, if omitted or nil - no excluding,
  #   :sync_on_start - trigger synchronization on start if set,
  #   :dryrun - run rsync with --dry-run option to not perform any actual changes if set,
  #   :debug - $stdout.puts out extra debug information if set
  def start(opts)
    
    # init runtime parameters
    @exclude = opts[:exclude].kind_of?(Regexp) ? opts[:exclude] : nil
    @pending_changes = opts[:sync_on_start] ? true : false
    @timeout = opts[:timeout] || DEFAULT_TIMEOUT
    @is_debug = opts[:debug]
    @is_dryrun = opts[:dryrun]
    
    # build the sync command
    if opts[:mode] == :rsync
      # rsync mode
      @sync_cmd = 'rsync -azcC --force --delete '
      @sync_cmd += '--dry-run ' if opts[:dryrun]
      @sync_cmd += '--progress ' if @is_debug
      @sync_cmd += "-e \"ssh -p#{opts[:port]}\" " if opts[:port]
      @sync_cmd += "#{opts[:local_path]} #{opts[:remote_path]}"
    else
      # ftpsync mode
      @sync_cmd = 'ftpsync.pl -p '
      @sync_cmd += '-i ' if opts[:dryrun]
      @sync_cmd += '-v ' if @is_debug
      @sync_cmd += "#{opts[:local_path]} #{opts[:remote_path]}"
    end

    # Start inotify watcher
    @inotify.watch_dir_recursively(opts[:local_path], @inotify_mask)
    # Catch INT and TERM signals to perform a clean up after ourselves
    %w{INT TERM}.each do |signal_name|
      Signal.trap(signal_name, proc { self.cleanup })
    end

    $stdout.puts "Started synchronization with the following options:\n#{opts.pretty_inspect}\n\n" if @is_debug
    
    while (true) do
      begin
        self.monitor_changes
      rescue
        $stderr.puts "Exception: ",$!, "\n"
      end
    end

  end

  # Monitors for changes and initiates syncing in case syncable changes were detected
  def monitor_changes
    # Check to see if we've got any new changes
    new_changes = false
    while ( (events = @inotify.next_events(true)).size > 0 ) do
      $stdout.puts "Detected #{events.size} new events\n" if @is_debug
      new_changes = true if events.find { |event| @exclude.nil? || event.filename !~ @exclude }
      $stdout.puts "Has synchronizable changes\n" if new_changes && @is_debug
    end
    
    # Check if we've got any pending changes those need to be synced and timeout has passed indicating that we're ready to go
    if (@pending_changes && !new_changes) then
      $stdout.puts "Synchronizing...\n" if @is_debug
      self.synchronize
      @pending_changes = false
    end
    
    # Update pending status and wait for a timeout
    @pending_changes = true if new_changes
    $stdout.puts "Pending changes\n" if @pending_changes && @is_debug
    sleep @timeout
      
  end

  # Actually synchronizes the files by calling the pre-built command
  def synchronize
    $stdout.puts "#{@sync_cmd}\n" if @is_debug
    system @sync_cmd
    errorvalue = $?
    errorvalue = errorvalue.exitstatus if errorvalue.kind_of?(Process::Status)
    $stdout.puts "rsync error status #{errorvalue}\n" if @is_debug
    self.cleanup if errorvalue == 20 || errorvalue == 255
  end

  # Cleans up before exit, closing inotify connection
  def cleanup
    $stdout.puts "Cleaning up...\n" if @is_debug
    @inotify.close
    exit 0
  end
end
