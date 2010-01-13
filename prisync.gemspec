Gem::Specification.new do |s|
  s.name = 'prisync'
  s.version = "0.2.2"
  s.date     = "2010-01-13"
  s.summary = "Pseudo-realtime file synchronization daemon."
  s.description = %{Prisync allows to synchronize to local or remote directories in a pseudo-realtime fashion.
  Filesystem changes are monitored with inotify kernel events, rsync or ftpsync utilities are used for the actual
  synchronization. Rsync can be run over SSH.%}
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
  s.homepage = "http://speakmy.name"
end
