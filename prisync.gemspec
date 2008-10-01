Gem::Specification.new do |s|
  s.name = 'prisync'
  s.version = "0.2"
  s.date     = "2008-10-01"
  s.summary = "Pseudo-realtime file synchronization daemon."
  s.description = %{Prisync allows to synchronize to local or remote directories in a pseudo-realtime fashion.
  Filesystem changes are monitored with inotify kernel events, rsync utility is used for the actual
  synchronization and can be run over SSH.%}
  s.has_rdoc = false
  
  s.files = ['lib/inotify.rb',
    'lib/prisync.rb',
    'bin/prisync',
    'prisync.gemspec',
    'README'
  ]

  s.bindir = 'bin'
  s.executables = ['prisync']

  s.require_path = 'lib'

  s.author = "Oleg Ivanov"
  s.email = "morhekil@morhekil.net"
  s.homepage = "http://morhekil.net"
end
